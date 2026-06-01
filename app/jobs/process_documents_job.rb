class ProcessDocumentsJob < ApplicationJob
  queue_as :default

  def perform(pericia_document_id)
    document = PericiaDocument.find(pericia_document_id)
    DocumentExtractor.new(document).extract
  end
end
