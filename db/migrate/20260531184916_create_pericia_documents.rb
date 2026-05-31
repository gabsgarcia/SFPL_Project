class CreatePericiaDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :pericia_documents do |t|
      t.references :pericia, null: false, foreign_key: { to_table: :pericias }
      t.string :document_type
      t.string :nome_original

      t.timestamps
    end
  end
end
