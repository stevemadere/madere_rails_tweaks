# A point on the globe specified by latitude,longitude.
# Includes methods to calculate great-circle distance from other GeoPoint
# objects or to do displacement math on GeoPoints.
class GeoPoint
  MILES_PER_DEGREE = 69.09 # :nodoc:

  def initialize(latitude,longitude)
    @latitude = latitude
    @longitude = longitude
  end
  attr_reader :latitude, :longitude

  def distance_from(other_point)
    return 0.0 if other_point.latitude == latitude && other_point.longitude == longitude # avoid divide-by-zero errors below
    frac_dist = Math::sin(deg2rad(latitude)) * Math::sin(deg2rad(other_point.latitude)) + Math::cos(deg2rad(latitude)) * Math::cos(deg2rad(other_point.latitude))* Math::cos(deg2rad(longitude - other_point.longitude))
                                                                                   degrees_dist = rad2deg(Math::acos(frac_dist))
                                                                                   distance = degrees_dist * MILES_PER_DEGREE
  end

  def self.parse(latlong)
    self.new(*(latlong.split(',').map(&:to_f)))
  end

  def to_s
    "%f,%f" % [latitude, longitude]
  end

  # Generates a new GeoPoint the specified distance_in_miles from
  # self.
  # Used primarily for testing of proximity-based functionality.
  def displaced_northward(distance_in_miles)
    new_lat = latitude + distance_in_miles / MILES_PER_DEGREE
    return self.class.new(new_lat,longitude)
  end

  def deg2rad(degrees)
    degrees * Math::PI / 180.0
  end

  def rad2deg(radians)
    radians*180.0 / Math::PI
  end

end
