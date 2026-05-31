class CorrigirStatusDefaultPericias < ActiveRecord::Migration[8.1]
  def change
    change_column_default :pericias, :status, from: "draft", to: "rascunho"
  end
end
