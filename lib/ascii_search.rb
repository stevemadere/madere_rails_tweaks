# Adds the ability to do postgresql full text searching to any rails model
# To use this in a model do these in your model class definition:
#    include AsciiSearch::Model
#    setup_ascii_search search_fields: list_of_searched_field_names, return_fields: list_of_returned_field_names
#    
# Models enhanced with this have a new class method full_text_search(query, options)
#
# To use this in a controller do these in your controller class definition:
#     include AsciiSearch::Controller
#
#     Controllers enhanced with this have a new controller action called
#     ascii_search that searches for instances of the associated model 
#     matching params[:term] and renders a json result set
#
module AsciiSearch

  cattr_accessor :min_first_prefix_length
  self.min_first_prefix_length = 2

  module Controller

    def ascii_search_find_matches(relation = self.model)
      matches = relation.none
      query = params[:term].try(:to_ascii)
      while matches.size ==0  && !query.empty?
        matches = relation.full_text_search(query, attrs: [:search_text], limit: 20, scan_limit: 1000)
        if matches.size == 0
          # strip off the last word in case it is a typo or incomplete word
          # and show matches for preceeding words
          words = query.split
          words.pop
          query = words.join(' ')
        end
      end
      matches
    end

    def ascii_search
      matches = ascii_search_find_matches
      render :json => matches.pluck(*model.return_fields), root: false
    end

  end


  module Model

    def self.included(base)
      base.before_save :update_search_text
      base.attr_accessible :search_text
      base.extend(ClassMethods)
      base.fields { search_text :string }
    end

    class FullTextSearch
      def initialize(model_class, query, opts={} )
        @model_class = model_class
        @query = model_class.respond_to?(:clean_full_text_query) ? @model_class.clean_full_text_query(query) : query
        @localopts = opts.clone
        @localopts[:attrs] ||= @model_class.search_fields
        column_names = @localopts[:attrs].map {|a| @model_class.column(a).name }
        @table_name = @model_class.table_name
        @ts_vectors = column_names.map { |cn| "to_tsvector('english',#{table_name}.#{cn})" }
        if @localopts[:prefix_match]
          @query = self.class.build_prefix_matching_ts_query(@query)
          @ts_query = "to_tsquery('english',#{@model_class.connection.quote(@query)})"
        else
          @ts_query = "plainto_tsquery('english',#{@model_class.connection.quote(@query)})"
        end
      end

      def self.remove_ts_query_special_chars(query)
        clean_query = query.tr("():*&|'!",' ')
      end

      def self.build_prefix_matching_ts_query(query)
        q = remove_ts_query_special_chars(query).strip.split(' ').uniq.each_with_index.map {|w,i| (i>0 || w.length >= AsciiSearch.min_first_prefix_length) ? w + ":*" : w }.join(" & ")
        q
      end

      attr_reader :ts_vectors, :ts_query, :table_name

      def where_criteria
        "#{ts_vectors.join(' || ')} @@ #{ts_query}"
      end

      def rank_expr
        "ts_rank(#{self.ts_vectors.join(' || ')}, #{self.ts_query})"
      end

      def matching_ids_sql(limit = nil)
        selector_sql = <<-"EOISQL"
           SELECT id
           FROM #{self.table_name}
           WHERE #{self.where_criteria}
        EOISQL
        if limit
          selector_sql += "\nLIMIT #{limit}"
        end
        selector_sql
      end

    end

    module ClassMethods

      def setup_ascii_search(search_fields: [:name], return_fields: [:id, :name])
        @search_fields = search_fields
        @return_fields = return_fields
      end

      def search_fields
        @search_fields
      end

      def return_fields
        @return_fields
      end

      def initialize_search_text
        self.all.each do |item|
          item.update_attribute('search_text', item.assemble_search_text)
        end
      end

      
      def full_text_search(query, opts = {})
        fts = FullTextSearch.new(self, query, opts)
        ids_selector_sql = fts.matching_ids_sql(opts[:scan_limit])
        rel = self.select("*, #{fts.rank_expr} as rank").where("id in (#{ids_selector_sql})").order('rank desc')
        if (opts[:limit])
          rel = rel.limit(opts[:limit])
        end
        redefine_pluck_and_count_for(rel)
        rel
      end

      def redefine_pluck_and_count_for(relation)
        def relation.pluck(*fields)
          self.map do |m|
            fields.map do |attribute|
              v = m.read_attribute(attribute)
              case v.class.name
              when /^HoboFields::/
                v.to_s
              else
                v
              end
            end
          end
        end
        def relation.count(*args)
          self.to_a.size
        end
        relation
      end
    end


    def assemble_search_text
      text = ""
      self.class.search_fields.each do |field|
        f = self.send(field)
        if f.respond_to?(:name)
          f = f.name
        end
        text += " #{f.try(:to_ascii)}"
      end
      dashed_acronyms = text.scan( /\b(?:\w-)+\w\b/i)
      undashed = dashed_acronyms.map {|s| s.gsub('-','') }
      text =( [text]+undashed).join(' ')
      text.strip
    end

    def update_search_text
      if (self.search_text.nil? || self.class.search_fields.any?{ |field| self.changes.include?(field) } )
        self.search_text = assemble_search_text
      end
    end
  end
end
