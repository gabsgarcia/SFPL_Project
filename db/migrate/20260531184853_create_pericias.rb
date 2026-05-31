class CreatePericias < ActiveRecord::Migration[8.1]
  def change
    create_table :pericias do |t|
      t.references :user, null: false, foreign_key: true
      t.string :titulo, null: false
      t.string :status, default: "draft", null: false
      t.string :tipo_laudo

      t.timestamps
    end
  end
end
