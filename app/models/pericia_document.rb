class PericiaDocument < ApplicationRecord
  belongs_to :pericia
  has_one_attached :file

  DOCUMENT_TYPES = %w[
    arq3_preenchido
    arq4_preenchido
    ppra
    pgr
    aso
    ppp
    epi_ficha
    treinamento
    descricao_cargo
    fds
    fispq
    laudo_paradigma
    ltcat
    pcmso
    aet
    transcricao
    audio
    foto
    outro
  ].freeze

  LABELS = {
    "arq3_preenchido" => "ARQ 3 preenchido — Termo de Comparecimento (pós-visita)",
    "arq4_preenchido" => "ARQ 4 preenchido — Análise do Perito (pós-visita)",
    "ppra"            => "PPRA — Programa de Prevenção de Riscos Ambientais",
    "pgr"             => "PGR — Programa de Gerenciamento de Riscos",
    "aso"             => "ASO — Atestado de Saúde Ocupacional",
    "ppp"             => "PPP — Perfil Profissiográfico Previdenciário",
    "epi_ficha"       => "Ficha de entrega de EPIs",
    "treinamento"     => "Certificado / lista de presença de treinamento",
    "descricao_cargo" => "Descrição formal do cargo",
    "fds"             => "FDS — Ficha de Dados de Segurança",
    "fispq"           => "FISPQ — Ficha de Informações de Segurança",
    "laudo_paradigma" => "Laudo paradigma (caso similar)",
    "ltcat"           => "LTCAT — Laudo Técnico das Condições Ambientais do Trabalho",
    "pcmso"           => "PCMSO — Programa de Controle Médico de Saúde Ocupacional",
    "aet"             => "AET — Análise Ergonômica do Trabalho",
    "transcricao"     => "Transcrição da visita pericial",
    "audio"           => "Áudio da visita pericial",
    "foto"            => "Foto da visita pericial",
    "outro"           => "Outro documento"
  }.freeze

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }
  validates :file, presence: true

  def label
    LABELS[document_type] || document_type
  end
end
