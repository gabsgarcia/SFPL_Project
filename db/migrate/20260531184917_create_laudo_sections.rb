class CreateLaudoSections < ActiveRecord::Migration[8.1]
  def change
    create_table :laudo_sections do |t|
      t.references :pericia, null: false, foreign_key: { to_table: :pericias }
      t.string :titulo
      t.text :conteudo
      t.integer :ordem
      t.boolean :revisado, default: false, null: false

      t.timestamps
    end
  end
end
