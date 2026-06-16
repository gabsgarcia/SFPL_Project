class ApplicationJob < ActiveJob::Base
  # Descarta jobs cujo registro foi deletado antes da execução
  discard_on ActiveJob::DeserializationError
  discard_on ActiveRecord::RecordNotFound

  # Retry em deadlocks de banco com backoff exponencial (máx 3 tentativas)
  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 3
end
