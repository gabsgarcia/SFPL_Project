class AddTituloProfissionalToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :titulo_profissional, :string
  end
end
