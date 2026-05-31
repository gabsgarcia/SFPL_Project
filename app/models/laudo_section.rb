class LaudoSection < ApplicationRecord
  belongs_to :pericia

  SECOES_FIXAS = [
    { codigo: "intro", titulo: "Petição ao Juízo + Introdução",                     ordem: 1  },
    { codigo: "2",     titulo: "Atividades exercidas pelo reclamante",               ordem: 2  },
    { codigo: "2.1",   titulo: "Versão do reclamante",                              ordem: 3  },
    { codigo: "2.2",   titulo: "Versão da reclamada",                               ordem: 4  },
    { codigo: "3",     titulo: "Equipamentos de Proteção Individual",               ordem: 5  },
    { codigo: "4",     titulo: "Local de trabalho",                                 ordem: 6  },
    { codigo: "5.1",   titulo: "Metodologia",                                       ordem: 7  },
    { codigo: "5.2",   titulo: "Documentação solicitada",                           ordem: 8  },
    { codigo: "5.3.1", titulo: "Agente Físico: Ruído (Anexo 01 NR-15)",            ordem: 9  },
    { codigo: "5.3.2", titulo: "Agente Físico: Calor (Anexo 03 NR-15)",            ordem: 10 },
    { codigo: "5.3.3", titulo: "Agentes Químicos (Anexos 11, 12, 13 NR-15)",       ordem: 11 },
    { codigo: "5.3.4", titulo: "Agentes Biológicos (Anexo 14 NR-15)",              ordem: 12 },
    { codigo: "5.4",   titulo: "Apuração de Periculosidade (NR-16)",               ordem: 13 },
    { codigo: "5.5",   titulo: "Análise Ergonômica — AET (NR-17)",                 ordem: 14 },
    { codigo: "6.1",   titulo: "Conclusão — Insalubridade",                        ordem: 15 },
    { codigo: "6.2",   titulo: "Conclusão — Periculosidade",                       ordem: 16 },
    { codigo: "6.3",   titulo: "Conclusão — Ergonomia",                            ordem: 17 },
    { codigo: "7.1",   titulo: "Respostas aos quesitos do Juízo",                  ordem: 18 },
    { codigo: "7.2",   titulo: "Respostas aos quesitos do Reclamante",             ordem: 19 },
    { codigo: "7.3",   titulo: "Respostas aos quesitos da Reclamada",              ordem: 20 }
  ].freeze

  scope :aplicaveis, -> { where(aplicavel: true) }
  scope :pendentes,  -> { aplicaveis.where(revisado: false) }

  validates :titulo, presence: true
  validates :ordem, presence: true
  validates :codigo, presence: true

  def revisado?
    revisado
  end
end
