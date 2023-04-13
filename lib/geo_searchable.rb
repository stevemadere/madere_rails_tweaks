# Adds ability to form distance queries and sorting
# expressions based on latitude and longitude members
# Include this in a Rails model that needs to be searchable
# or sortable by latitude,longitude proximity.
module GeoSearchable

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.extend ClassMethods
  end

  module InstanceMethods

    # Calculates the distance in miles of the instance from the 
    # specified reference_location
    def distance_from(reference_location)
      return nil unless latitude && longitude
      ref_point = self.class.parse_location(reference_location)
      my_point = GeoPoint.new(latitude,longitude)

      if(my_point.latitude == ref_point.latitude && my_point.longitude == ref_point.longitude )
        0
      else
        my_point.distance_from(ref_point)
      end
    end
  end

  module ClassMethods
    METERS_IN_A_MILE = 1609.34

    def parse_location(location)
      GeoPoint.new(*(location.kind_of?(Array) ? location.map(&:to_f) : location.split(',').map(&:to_f)))
    end

    # Composes a SQL expression that evaluates to true for rows cloer to
    # the specified reference_location than the specified distanc_in_miles.
    # Suitable for use in an where() decoration on an ActiveRecord relation.
    #
    # e.g.  Merchant.where(within_distance_expr(my_location, 5.0))
    def within_distance_expr(reference_location, distance_in_miles)
      ref_point = self.parse_location(reference_location)
      distance_in_meters = distance_in_miles.to_f * METERS_IN_A_MILE
      result = <<-"EOSQL"
        ST_DWithin(
          ST_GeographyFromText(
            'SRID=4326;POINT(' || longitude || ' ' || latitude || ')'
          ),
          ST_GeographyFromText('SRID=4326;POINT(#{ref_point.longitude} #{ref_point.latitude})'),
          #{distance_in_meters})
        EOSQL
      result
    end

    # Composes a SQL expression that calculates the distance of a row's
    # latitude and longitude members from a specified reference location.
    # Suitable for use in an order() decoration on an ActiveRecord relation.
    #
    # e.g.  Merchant.all.order(distance_expr(my_location))
    def distance_expr(reference_location, direction="ASC")
      table_name = self.class.table_name
      ref_point = self.parse_location(reference_location)
      result = <<-"EOSQL"
        ST_Distance(
          ST_GeographyFromText(
            'SRID=4326;POINT(' || #{table_name}.longitude || ' ' || #{table_name}.latitude || ')'
          ),
          ST_GeographyFromText('SRID=4326;POINT(#{ref_point.longitude} #{ref_point.latitude})'),
          false)*0.000621371 #{direction}
        EOSQL
      result
    end
  end

end
