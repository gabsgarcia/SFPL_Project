class QuesitoResposta < ApplicationRecord
  belongs_to :pericia

  ORIGENS = %w[juizo reclamante reclamada_1 reclamada_2].freeze

  validates :origem, inclusion: { in: ORIGENS }
  validates :numero, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :texto_quesito, presence: true

  scope :do_juizo,      -> { where(origem: "juizo") }
  scope :do_reclamante, -> { where(origem: "reclamante") }
  scope :da_reclamada,  -> { where(origem: ["reclamada_1", "reclamada_2"]) }
  scope :pendentes,     -> { where(revisado: false) }

  def revisado?
    revisado
  end
end
