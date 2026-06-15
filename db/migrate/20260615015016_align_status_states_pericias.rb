class AlignStatusStatesPericias < ActiveRecord::Migration[8.1]
  MAPA = {
    "rascunho"       => "novo",
    "documentos_ok"  => "docs_base_prontos",
    "agendado"       => "aguardando_visita",
    "vistoria_feita" => "processando_pos_visita",
    "processando"    => "processando_pos_visita",
    "em_revisao"     => "pre_laudo_em_revisao"
    # "concluido" permanece igual
  }.freeze

  def up
    MAPA.each do |antigo, novo|
      execute "UPDATE pericias SET status = '#{novo}' WHERE status = '#{antigo}'"
    end
    change_column_default :pericias, :status, from: "rascunho", to: "novo"
  end

  def down
    change_column_default :pericias, :status, from: "novo", to: "rascunho"
    MAPA.each do |antigo, novo|
      execute "UPDATE pericias SET status = '#{antigo}' WHERE status = '#{novo}'"
    end
  end
end
