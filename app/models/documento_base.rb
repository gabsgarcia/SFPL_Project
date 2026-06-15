class DocumentoBase < ApplicationRecord
  belongs_to :pericia

  TIPOS = %w[arq1_peticao arq2_email arq3_termo arq4_analise].freeze

  LABELS = {
    "arq1_peticao" => "ARQ 1 — Petição de Designação de Perícia",
    "arq2_email"   => "ARQ 2 — E-mail para Advogados",
    "arq3_termo"   => "ARQ 3 — Termo de Comparecimento",
    "arq4_analise" => "ARQ 4 — Análise do Perito"
  }.freeze

  EXPORTACAO = {
    "arq1_peticao" => :pdf,
    "arq2_email"   => :texto,
    "arq3_termo"   => :pdf,
    "arq4_analise" => :pdf
  }.freeze

  validates :tipo, presence: true, inclusion: { in: TIPOS }
  validates :tipo, uniqueness: { scope: :pericia_id }

  scope :ordenados, -> { order(Arel.sql("array_position(ARRAY['arq1_peticao','arq2_email','arq3_termo','arq4_analise'], tipo)")) }
  scope :revisados, -> { where(revisado: true) }
  scope :pendentes, -> { where(revisado: false) }

  def label
    LABELS[tipo]
  end

  def exporta_pdf?
    EXPORTACAO[tipo] == :pdf
  end

  def exporta_texto?
    EXPORTACAO[tipo] == :texto
  end

  def marcar_revisado!
    update!(revisado: true, revisado_em: Time.current)
  end
end
