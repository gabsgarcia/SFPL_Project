class CreateDocumentoBases < ActiveRecord::Migration[8.1]
  def change
    create_table :documento_bases do |t|
      t.references :pericia, null: false, foreign_key: true
      t.string :tipo, null: false
      t.text :conteudo
      t.boolean :revisado, null: false, default: false
      t.datetime :revisado_em

      t.timestamps
    end

    add_index :documento_bases, [:pericia_id, :tipo], unique: true
  end
end
