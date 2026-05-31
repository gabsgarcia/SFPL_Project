class Pericia < ApplicationRecord
  belongs_to :user
  has_many :pericia_documents, dependent: :destroy
  has_many :laudo_sections, -> { order(:ordem) }, dependent: :destroy
  has_many :quesito_respostas, -> { order(:origem, :numero) }, dependent: :destroy

  STATUSES = %w[
    rascunho
    documentos_ok
    agendado
    vistoria_feita
    processando
    em_revisao
    concluido
  ].freeze

  TIPOS_PERICIA = %w[insalubridade periculosidade ambos].freeze

  TRANSICOES_VALIDAS = {
    "rascunho"       => %w[documentos_ok],
    "documentos_ok"  => %w[agendado],
    "agendado"       => %w[vistoria_feita],
    "vistoria_feita" => %w[processando],
    "processando"    => %w[em_revisao],
    "em_revisao"     => %w[concluido processando],
    "concluido"      => []
  }.freeze

  validates :numero_processo, presence: true
  validates :reclamante, presence: true
  validates :reclamada_1, presence: true
  validates :tipo_pericia, inclusion: { in: TIPOS_PERICIA }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }

  validate :transicao_de_status_valida, if: :status_changed?

  scope :for_user, ->(user) { where(user: user) }

  def agentes_selecionados
    %w[ruido calor quimico biologico eletricidade inflamavel ergonomia]
      .select { |a| public_send(:"tem_#{a}") }
  end

  def todas_secoes_revisadas?
    laudo_sections.aplicaveis.all?(&:revisado?)
  end

  private

  def transicao_de_status_valida
    transicoes_permitidas = TRANSICOES_VALIDAS[status_was] || []
    return if transicoes_permitidas.include?(status)

    errors.add(:status, "não pode mudar de '#{status_was}' para '#{status}'")
  end
end
