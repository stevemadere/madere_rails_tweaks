# Simply requiring this module adds the #fast_pluck method to all 
# ActiveRecord objects that have the #pluck method.
# This is useful because pluck can be annoyingly slow for large data sets.
module FastPluck
  extend ActiveSupport::Concern 
  class_methods do
    # Similar to pluck but returns all column values as strings and
    # runs 3x to 5x faster than pluck.  If your columns are integers,
    # it's still drastically faster to call v.to_i yourself than to let pluck
    # figure out how to cast it on the fly.
    def fast_pluck(*args)
      sql = self.select(*args).to_sql
      res = self.connection.execute(sql)
      if args.size == 1
        res.values.flatten
      else
        res.values
      end
    end
  end
end

ActiveRecord::Base.send :include, FastPluck

