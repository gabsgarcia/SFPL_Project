class GenerateLaudoJob < ApplicationJob
  queue_as :default

  def perform(pericia_id, secao_codigo = nil)
    pericia = Pericia.find(pericia_id)
    service = GenerateLaudoService.new(pericia)

    if secao_codigo
      service.generate_section(secao_codigo)
    else
      service.generate_all
    end
  rescue => e
    pericia.update!(status: "em_revisao")
    raise e
  end
end
