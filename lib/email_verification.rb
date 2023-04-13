# A class to verify email addresses and encapsulate the details
# of interacting with Kickbox
class EmailVerification

  def self.verify(email_address)
    if !Rails.env.production? && email_address.include?('+timeout')
      {
        'result' => 'timeout',
        'reason' => 'timeout',
      }
    else
      client   = Kickbox::Client.new(YAML_CONFIG['kickbox']['key'])
      kickbox  = client.kickbox()
      kickbox.verify(email_address).body
    end
  end

  # Used to validate an email address and if it is invalid, produce
  # reasonable diagnostic output to explain to the user what is wrong
  # with it.
  # Returns nil if the email address is valid.
  #
  def self.problem_with_email_address(email_address, allow_email_timeout)
    body = verify(email_address)
    Rails.logger.info("kickbox result for #{email_address}: #{body.to_json}")
    status = body['result']
    if status == 'deliverable'
      nil
    elsif body['reason'] == 'timeout'
      problem_with_timeout(allow_email_timeout)
    elsif status == 'risky'
      problem_with_risky_address(email_address, body)
    else
      'is not deliverable'
    end
  rescue StandardError => e
    Rails.logger.error("uncaught exception when calling Kickbox API: #{e.message}")
    Honeybadger.notify(e)
    return nil
  end

  protected

  class KickboxFailureError < StandardError
  end

  def self.problem_with_timeout(allow_email_timeout)
    if allow_email_timeout
      nil
    else
      'timeout'
    end
  end

  # Implements some exceptions for addresses marked as 'risky'
  # by KickBox which we feel are no big deal.  Essentially converts
  # an assesment of 'risky' into 'no problem' in certain circumstances.
  def self.problem_with_risky_address(email_address, details)
    reason = details['reason']

    if details['disposable'] && !email_address.ends_with?('@yahoo.com')
      return 'is disposable'
    end

    # let failures through but document it with an exception
    # report via Honeybadger
    unless details['success']
      e = KickboxFailureError.new(details.to_json)
      Honeybadger.notify(e)
    end

    return nil
  end

end
