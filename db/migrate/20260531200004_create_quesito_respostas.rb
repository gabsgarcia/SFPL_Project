class CreateQuesitoRespostas < ActiveRecord::Migration[8.1]
  def change
    create_table :quesito_respostas do |t|
      t.references :pericia, null: false, foreign_key: true
      t.string :origem, null: false
      t.integer :numero, null: false
      t.text :texto_quesito
      t.text :resposta
      t.boolean :revisado, default: false, null: false

      t.timestamps
    end

    add_index :quesito_respostas, [:pericia_id, :origem, :numero], unique: true
  end
end
