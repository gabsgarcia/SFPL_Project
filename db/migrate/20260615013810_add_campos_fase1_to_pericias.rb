class AddCamposFase1ToPericias < ActiveRecord::Migration[8.1]
  def change
    add_column :pericias, :email_adv_reclamante, :string
    add_column :pericias, :email_adv_reclamada_1, :string
    add_column :pericias, :email_adv_reclamada_2, :string
    add_column :pericias, :assist_tec_reclamante, :string
    add_column :pericias, :assist_tec_reclamada_1, :string
    add_column :pericias, :assist_tec_reclamada_2, :string
    add_column :pericias, :prazo_laudo, :date
    add_column :pericias, :resumo_inicial, :text
    add_column :pericias, :resumo_contestacao, :text
  end
end
