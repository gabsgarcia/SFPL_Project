class Pericia < ApplicationRecord
  belongs_to :user
  has_one_attached :arquivo_processo
  has_many :documento_bases, dependent: :destroy
  has_many :pericia_documents, dependent: :destroy
  has_many :laudo_sections, -> { order(:ordem) }, dependent: :destroy
  has_many :quesito_respostas, -> { order(:origem, :numero) }, dependent: :destroy

  STATUSES = %w[
    novo
    extraindo_dados
    docs_base_prontos
    aguardando_visita
    processando_pos_visita
    pre_laudo_em_revisao
    pre_laudo_aprovado
    concluido
    erro
  ].freeze

  TIPOS_PERICIA = %w[insalubridade periculosidade ambos].freeze

  TRANSICOES_VALIDAS = {
    "novo"                   => %w[extraindo_dados],
    "extraindo_dados"        => %w[docs_base_prontos erro],
    "docs_base_prontos"      => %w[aguardando_visita],
    "aguardando_visita"      => %w[processando_pos_visita],
    "processando_pos_visita" => %w[pre_laudo_em_revisao erro],
    "pre_laudo_em_revisao"   => %w[pre_laudo_aprovado processando_pos_visita],
    "pre_laudo_aprovado"     => %w[concluido],
    "concluido"              => [],
    "erro"                   => %w[novo extraindo_dados processando_pos_visita]
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

  def transcricao_documento
    pericia_documents.find_by(document_type: "transcricao")
  end

  def pronta_para_gerar_laudo?
    transcricao_revisada? && pericia_documents.any?
  end

  private

  def transicao_de_status_valida
    transicoes_permitidas = TRANSICOES_VALIDAS[status_was] || []
    return if transicoes_permitidas.include?(status)

    errors.add(:status, "não pode mudar de '#{status_was}' para '#{status}'")
  end
end
