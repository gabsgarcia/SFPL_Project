class UpdatePericiasForDominioTrabalhista < ActiveRecord::Migration[8.1]
  def change
    # Remover campos do domínio errado (vistoria de imóvel)
    remove_column :pericias, :titulo, :string
    remove_column :pericias, :tipo_laudo, :string

    # Identificação do processo judicial
    add_column :pericias, :numero_processo, :string
    add_column :pericias, :vara, :string
    add_column :pericias, :comarca, :string
    add_column :pericias, :regiao_trt, :string

    # Partes do processo
    add_column :pericias, :reclamante, :string
    add_column :pericias, :reclamada_1, :string
    add_column :pericias, :reclamada_2, :string
    add_column :pericias, :funcao_reclamante, :string

    # Período contratual
    add_column :pericias, :admissao, :date
    add_column :pericias, :demissao, :date

    # Tipo e agendamento da perícia
    add_column :pericias, :tipo_pericia, :string
    add_column :pericias, :data_pericia, :datetime
    add_column :pericias, :local_pericia, :text

    # Agentes de risco identificados (definem quais seções gerar no laudo)
    add_column :pericias, :tem_ruido, :boolean, default: false, null: false
    add_column :pericias, :tem_calor, :boolean, default: false, null: false
    add_column :pericias, :tem_quimico, :boolean, default: false, null: false
    add_column :pericias, :tem_biologico, :boolean, default: false, null: false
    add_column :pericias, :tem_eletricidade, :boolean, default: false, null: false
    add_column :pericias, :tem_inflamavel, :boolean, default: false, null: false
    add_column :pericias, :tem_ergonomia, :boolean, default: false, null: false

    # Metadados do laudo
    add_column :pericias, :honorarios_salarios, :integer
    add_column :pericias, :observacoes_perito, :text

    # Corrigir valor padrão do status (mantém coluna, só ajusta o default)
    change_column_default :pericias, :status, from: "draft", to: "draft"
  end
end
