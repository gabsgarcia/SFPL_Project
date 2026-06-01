class AddTranscricaoLimpaToPericias < ActiveRecord::Migration[8.1]
  def change
    add_column :pericias, :transcricao_limpa, :jsonb
    add_column :pericias, :transcricao_revisada, :boolean, default: false, null: false
  end
end
