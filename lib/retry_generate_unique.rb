# In places where we generate unique tokens and we want to ensure we never return a
# RecordNotUnique unless something has gone horribly wrong
module RetryGenerateUnique
  MAX_RETRIES = 5

  def self.try(token_attempts = 0)
    yield
  rescue ActiveRecord::RecordNotUnique => e
    token_attempts = token_attempts + 1
    retry if token_attempts < MAX_RETRIES
    raise e, "Retries exhausted"
  end

end