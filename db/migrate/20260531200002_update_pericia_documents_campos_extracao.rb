class UpdatePericiaDocumentsCamposExtracao < ActiveRecord::Migration[8.1]
  def change
    add_column :pericia_documents, :texto_extraido, :text
    add_column :pericia_documents, :processado, :boolean, default: false, null: false
  end
end
