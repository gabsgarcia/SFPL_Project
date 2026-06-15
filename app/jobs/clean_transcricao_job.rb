class CleanTranscricaoJob < ApplicationJob
  queue_as :default

  def perform(pericia_id)
    pericia = Pericia.find(pericia_id)
    CleanTranscricaoService.new(pericia).process
  end
end
