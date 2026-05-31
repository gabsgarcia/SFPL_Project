class UpdateLaudoSectionsCodigoAplicavel < ActiveRecord::Migration[8.1]
  def change
    add_column :laudo_sections, :codigo, :string
    add_column :laudo_sections, :aplicavel, :boolean, default: true, null: false
  end
end
