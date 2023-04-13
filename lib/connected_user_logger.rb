# Used for including the user id of the currently acting user
# in Rails log entries.
module ConnectedUserLogger
  def self.extract_user_id_from_request(req)
    session_key = Rails.application.config.session_options[:key]
    session_data = req.cookie_jar.encrypted[session_key]
    return nil unless session_data && session_data.has_key?('user')
    session_data["user"].gsub('user:', '')
  end
end
