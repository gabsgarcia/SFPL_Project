# CLAUDE.md — Plataforma de Laudos Periciais Trabalhistas

## Visão Geral do Projeto

Sistema Rails para automatizar o trabalho de peritos judiciais em processos
trabalhistas de insalubridade e periculosidade. O perito recebe um PDF do
processo judicial, faz upload na plataforma, e o agente de IA extrai os dados
e preenche automaticamente os documentos de cada fase da perícia.

## Stack Tecnológica

- **Ruby 3.3.5 / Rails 8.1**
- **PostgreSQL**
- **ruby_llm ~> 1.2.0** — chamadas ao Claude (Anthropic) — JÁ INSTALADO
- **Devise** — autenticação — JÁ INSTALADO
- **Active Storage + Cloudinary** — uploads — JÁ INSTALADO
- **Solid Queue** — jobs assíncronos — JÁ INSTALADO
- **Bootstrap 5.3 + Stimulus + Turbo** — frontend — JÁ INSTALADO
- **pdf-reader** — extrair texto de PDFs — JÁ INSTALADO
- **docx** — extrair texto de arquivos Word — JÁ INSTALADO
- **roo** — extrair texto de planilhas Excel — JÁ INSTALADO
- **wicked_pdf + wkhtmltopdf-binary** — gerar documentos PDF — JÁ INSTALADO

---

## Domínio do Negócio

### O que é uma perícia trabalhista de insalubridade/periculosidade

Quando um trabalhador processa uma empresa exigindo adicional de insalubridade
ou periculosidade, o juiz nomeia um perito para investigar as condições reais
de trabalho. O processo judicial (PDF enorme, centenas de páginas) contém
todos os dados necessários: partes, advogados, e-mails, quesitos, histórico.

O perito trabalha em três fases bem distintas:

**Fase 1 — Pré-visita:** Ler o processo, preparar e enviar documentos iniciais.
**Fase 2 — Pós-visita:** Processar o material da diligência e gerar pré-laudo.
**Fase 3 — Laudo final:** Revisar pré-laudo e exportar PDF assinável.

### Normas Regulamentadoras relevantes

- **NR-6** — EPIs: valida se os equipamentos eram adequados e suficientes
- **NR-10** — Eletricidade: instalações e serviços elétricos
- **NR-13** — Caldeiras, vasos de pressão e tubulações
- **NR-15** — Insalubridade (a mais importante):
  - Anexo 01: Ruído (medição em dB, comparar com limites de tolerância)
  - Anexo 03: Calor (IBUTG, atividade leve/moderada/pesada)
  - Anexo 11: Agentes químicos com limites de tolerância
  - Anexo 12: Poeiras minerais
  - Anexo 13: Operações diversas (álcalis cáusticos = grau médio)
  - Anexo 14: Agentes biológicos — lixo urbano e higienização de sanitários
    públicos/coletivos = GRAU MÁXIMO (Súmula 448 TST)
- **NR-16** — Periculosidade:
  - Anexo 01: Explosivos
  - Anexo 02: Inflamáveis
  - Anexo 03: Roubos/violência (segurança patrimonial)
  - Anexo 04: Energia elétrica
  - Anexo 05: Motocicleta
- **NR-17** — Ergonomia: AET, levantamento de peso, postura, repetitividade

### Jurisprudência importante

- **Súmula 448 TST II**: higienização de sanitários públicos/coletivos de
  grande circulação + coleta de lixo = insalubre grau máximo (Anexo 14 NR-15)
- **Art. 191 CLT**: EPI elimina ou neutraliza insalubridade — exceto para
  agentes biológicos (Anexo 14), onde EPI apenas minimiza o risco

---

## Fluxo Completo em 3 Fases

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 1 — PRÉ-VISITA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Perito faz upload do PDF do processo judicial
         ↓
2. ExtractProcessoJob (Agente IA):
   Lê o PDF (pode ter centenas de páginas) e extrai:
   - Número do processo, vara, comarca, TRT
   - Dados do reclamante (nome, CPF, admissão, demissão, função)
   - Dados das reclamadas (nomes, CNPJs)
   - E-mails dos advogados de cada parte (presentes na decisão do juiz)
   - Tipo de perícia solicitada (insalubridade | periculosidade | ambos)
   - Quesitos do reclamante (protocolados no processo)
   - Quesitos das reclamadas (protocolados no processo)
   - Assistentes técnicos indicados pelas partes
   - Data-limite para entrega do laudo
   - Resumo da inicial (o que o reclamante alega)
   - Resumo da contestação (o que a reclamada alega)
         ↓
3. Plataforma preenche automaticamente os 4 documentos base:

   ARQ 1 — Petição de Designação de Perícia (para o juiz)
   ARQ 2 — E-mail para Advogados (notificação + lista de documentos)
   ARQ 3 — Termo de Comparecimento (cabeçalho pré-preenchido)
   ARQ 4 — Análise do Perito (quesitos extraídos e organizados)
         ↓
4. Perito revisa os 4 documentos na plataforma e confirma
         ↓
5. Perito envia via e-mail (fora da plataforma por ora)
   Status → "aguardando_visita"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 2 — PÓS-VISITA (Pré-Laudo)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

6. Perito faz upload após a diligência:
   - ARQ 3 preenchido (Termo de Comparecimento com versões das partes)
   - ARQ 4 preenchido (Análise com respostas do perito)
   - Áudio ou transcrição da entrevista
   - Fotos tiradas no local
   - Documentos recebidos da reclamada (PPRA, ASO, PPP, EPI, FDS, etc.)
         ↓
7. CleanTranscricaoJob (Agente IA):
   Processa a transcrição bruta do áudio:
   - Identifica falantes (perita, reclamante, advogados)
   - Corrige erros de reconhecimento automático
   - Extrai informações estruturadas em JSON
         ↓
8. Perito marca quais agentes estão presentes (ruído, calor, químico, etc.)
         ↓
9. GeneratePreLaudoJob (Agente IA):
   Gera o pré-laudo seção por seção, usando:
   - Dados extraídos do processo (Fase 1)
   - ARQ 3 e ARQ 4 preenchidos
   - Transcrição limpa (JSON)
   - Documentos da reclamada (textos extraídos)
   - Base de laudos anteriores como referência de estilo/argumentação
         ↓
10. Perito revisa o pré-laudo seção por seção na plataforma
    Status → "pre_laudo_em_revisao"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 3 — LAUDO FINAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

11. Perito aprova todas as seções do pré-laudo
          ↓
12. Plataforma gera PDF final no formato padrão do escritório
    Status → "concluido"
```

---

## Estrutura dos Modelos

### ProcessoPericial (modelo central)

```ruby
# belongs_to :user
# has_one_attached :arquivo_processo (PDF do processo judicial)
campos:
  # Dados extraídos do processo
  numero_processo:    string   # "1001760-11.2025.5.02.0292"
  vara:               string   # "2ª Vara do Trabalho"
  comarca:            string   # "Franco da Rocha"
  regiao_trt:         string   # "TRT 02ª Região"

  # Reclamante
  reclamante_nome:    string
  reclamante_funcao:  string   # "auxiliar de limpeza"
  reclamante_admissao: date
  reclamante_demissao: date

  # Reclamadas (pode haver 1 ou 2)
  reclamada_1_nome:   string
  reclamada_2_nome:   string   # nullable

  # E-mails dos advogados (extraídos da decisão do juiz no processo)
  email_adv_reclamante:  string
  email_adv_reclamada_1: string
  email_adv_reclamada_2: string  # nullable

  # Assistentes técnicos indicados
  assist_tec_reclamante: string  # nome, nullable
  assist_tec_reclamada_1: string # nome, nullable
  assist_tec_reclamada_2: string # nome, nullable

  # Tipo e prazo
  tipo_pericia:       string   # "insalubridade" | "periculosidade" | "ambos"
  prazo_laudo:        date     # data-limite para entrega do laudo
  data_pericia:       datetime # agendado pelo perito
  local_pericia:      text

  # Resumos extraídos do processo
  resumo_inicial:     text     # o que o reclamante alega
  resumo_contestacao: text     # o que a reclamada alega

  # Agentes identificados (definem quais seções gerar no laudo)
  tem_ruido:          boolean
  tem_calor:          boolean
  tem_quimico:        boolean
  tem_biologico:      boolean
  tem_eletricidade:   boolean
  tem_inflamavel:     boolean
  tem_ergonomia:      boolean

  # Controle
  status:             string   # ver estados abaixo
  honorarios_salarios: integer # ex: 4 (quatro salários mínimos)
  observacoes_perito: text
```

**Estados do ProcessoPericial:**
```
novo                   → processo criado, PDF ainda não processado
extraindo_dados        → ExtractProcessoJob rodando
docs_base_prontos      → ARQ 1-4 preenchidos, aguardando revisão do perito
aguardando_visita      → perito confirmou e enviou os documentos
processando_pos_visita → CleanTranscricaoJob / GeneratePreLaudoJob rodando
pre_laudo_em_revisao   → pré-laudo gerado, perito revisando seção a seção
pre_laudo_aprovado     → todas as seções revisadas
concluido              → PDF final gerado
erro                   → falha em algum job
```

### DocumentoBase (ARQ 1, 2, 3, 4)

```ruby
# Os 4 documentos base da Fase 1 — gerados automaticamente, editáveis na plataforma
# belongs_to :processo_pericial
campos:
  tipo:           string  # "arq1_peticao" | "arq2_email" | "arq3_termo" | "arq4_analise"
  conteudo:       text    # HTML ou texto do documento preenchido pelo agente
  revisado:       boolean
  revisado_em:    datetime
```

**Comportamento de cada documento:**

| ARQ | Descrição | Exportação Fase 1 | Retorna preenchido? |
|-----|-----------|-------------------|---------------------|
| ARQ 1 | Petição ao juiz informando data da perícia | **PDF** para protocolar no PJe | Não |
| ARQ 2 | E-mail para advogados com lista de documentos | **Texto de e-mail** para copiar/enviar | Não |
| ARQ 3 | Termo de Comparecimento | **PDF** para imprimir e levar na visita | **Sim** — perito preenche à mão durante a visita e faz upload do scan na Fase 2 |
| ARQ 4 | Análise do Perito (quesitos organizados) | **PDF** para usar digitalmente ou impresso | **Sim** — perito preenche durante/após a visita e faz upload na Fase 2 |

**Fluxo de exportação na Fase 1:**
- Perito edita os 4 ARQs na plataforma (campos inline)
- Clica em "Exportar PDF" → gera PDF formatado para ARQ 1, 3, 4
- Clica em "Copiar e-mail" → gera texto pronto para ARQ 2
- Após exportar todos, confirma na plataforma → status muda para `aguardando_visita`

### PericiaDocument (documentos da reclamada + material da visita)

```ruby
# Arquivos enviados pelo perito após a visita
# belongs_to :processo_pericial
# has_one_attached :file
campos:
  document_type:  string  # ver tipos abaixo
  nome_original:  string
  texto_extraido: text    # extraído pelo DocumentExtractor
  processado:     boolean
```

**Tipos de documento:**
- `ppra` / `pgr` — Programa de Prevenção de Riscos / Gerenciamento de Risco
- `aso` — Atestado de Saúde Ocupacional
- `ppp` — Perfil Profissiográfico Previdenciário
- `epi_ficha` — Ficha de entrega de EPIs assinada
- `treinamento` — Certificados e listas de presença
- `descricao_cargo` — Descrição formal do cargo
- `fds` / `fispq` — Ficha de Dados de Segurança dos produtos
- `laudo_paradigma` — Laudos de casos similares da reclamada
- `ltcat` — Laudo Técnico das Condições Ambientais do Trabalho
- `pcmso` — Programa de Controle Médico de Saúde Ocupacional
- `aet` — Análise Ergonômica do Trabalho
- `transcricao` — Transcrição do áudio da visita
- `audio` — Arquivo de áudio original
- `foto` — Fotos do local de trabalho
- `arq3_preenchido` — ARQ 3 preenchido após a visita
- `arq4_preenchido` — ARQ 4 preenchido após a visita
- `outro`

### LaudoSection (seções do pré-laudo / laudo final)

```ruby
# belongs_to :processo_pericial
campos:
  codigo:     string   # "2.1", "5.3.2", "6.1", "7.2" etc.
  titulo:     string   # "Agente Biológico (Anexo 14 NR-15)"
  conteudo:   text     # gerado pelo agente, editável pelo perito
  ordem:      integer
  revisado:   boolean
  aplicavel:  boolean  # false = seção não se aplica a este caso
```

**Seções fixas do laudo (sempre nesta ordem):**
```
codigo  | titulo
--------|----------------------------------------------------------
"1"     | Introdução
"2"     | Atividades exercidas pelo reclamante
"2.1"   | Versão do reclamante
"2.2"   | Versão da reclamada
"3"     | Equipamentos de Proteção Individual
"4"     | Local de trabalho
"5.1"   | Metodologia
"5.2"   | Documentação solicitada
"5.3.1" | Agente Físico: Ruído (Anexo 01 NR-15)
"5.3.2" | Agente Físico: Calor (Anexo 03 NR-15)
"5.3.3" | Agentes Químicos (Anexos 11, 12, 13 NR-15)
"5.3.4" | Agentes Biológicos (Anexo 14 NR-15)
"5.3.x" | Outros agentes
"5.4"   | Apuração de Periculosidade (NR-16)
"5.5"   | Análise Ergonômica — AET (NR-17)
"6.1"   | Conclusão — Insalubridade
"6.2"   | Conclusão — Periculosidade
"6.3"   | Conclusão — Ergonomia
"7.1"   | Respostas aos quesitos do Juízo
"7.2"   | Respostas aos quesitos do Reclamante
"7.3"   | Respostas aos quesitos da Reclamada
```

### QuesitoResposta

```ruby
# belongs_to :processo_pericial
campos:
  origem:          string   # "juizo" | "reclamante" | "reclamada_1" | "reclamada_2"
  numero:          integer
  texto_quesito:   text
  resposta:        text     # gerada pelo agente, editável
  revisado:        boolean
```

---

## Estado das Migrações

> **Atenção — divergência de nomenclatura:** o model foi implementado como
> `Pericia` (tabela `pericias`) em vez de `ProcessoPericial` (tabela
> `processo_pericials`). A FK nas tabelas relacionadas é `pericia_id`.
> Alguns campos também foram renomeados (ver tabela abaixo). O comportamento
> é idêntico ao spec; apenas os nomes diferem.

### Mapeamento de campos: spec → implementação

| Spec (`ProcessoPericial`) | Implementado (`Pericia`) |
|---|---|
| `reclamante_nome` | `reclamante` |
| `reclamante_funcao` | `funcao_reclamante` |
| `reclamante_admissao` | `admissao` |
| `reclamante_demissao` | `demissao` |
| `reclamada_1_nome` | `reclamada_1` |
| `reclamada_2_nome` | `reclamada_2` |

### Migrações já aplicadas

- [x] `pericias` — model `Pericia` (modelo central, com `has_one_attached :arquivo_processo`)
- [x] `documento_bases` — model `DocumentoBase` (ARQ 1-4, índice único por `pericia_id + tipo`)
- [x] `pericia_documents` — model `PericiaDocument`
- [x] `laudo_sections` — model `LaudoSection`
- [x] `quesito_respostas` — model `QuesitoResposta`
- [x] `users` — Devise

### Campos ainda faltando na tabela `pericias` (próxima migration)

```bash
# Adicionar via migration (não recriar a tabela):
rails generate migration AddCamposFase1ToPericias \
  email_adv_reclamante:string \
  email_adv_reclamada_1:string email_adv_reclamada_2:string \
  assist_tec_reclamante:string \
  assist_tec_reclamada_1:string assist_tec_reclamada_2:string \
  prazo_laudo:date \
  resumo_inicial:text resumo_contestacao:text
```

---

## Rotas

> Implementado com `pericias` (não `processo_pericials`).
> `generate_laudo` corresponde ao `generate_pre_laudo` do spec.

```ruby
# config/routes.rb — estado atual
resources :pericias do
  resources :documento_bases,   only: [:show, :edit, :update]  # ARQ 1-4
  resources :pericia_documents, only: [:create, :destroy]       # arquivos da visita
  resources :laudo_sections,    only: [:update]
  resources :quesito_respostas, only: [:update]

  member do
    # Fase 1
    post :extract_processo       # dispara ExtractProcessoJob
    get  :review_docs_base       # revisão dos ARQ 1-4

    # Fase 2
    get   :review_transcricao    # revisão da transcrição limpa
    patch :update_transcricao    # salva a transcrição revisada
    post  :generate_laudo        # dispara GenerateLaudoJob
    get   :review                # revisão do pré-laudo seção a seção

    # Fase 3
    post  :generate_pdf          # gera PDF final
  end
end
```

---

## Jobs (Solid Queue)

### Estado atual dos jobs

| Job | Arquivo | Status |
|---|---|---|
| `ExtractProcessoJob` | `app/jobs/extract_processo_job.rb` | ❌ a criar (Phase 4) |
| `CleanTranscricaoJob` | `app/jobs/clean_transcricao_job.rb` | ✅ existe |
| `GenerateLaudoJob` | `app/jobs/generate_laudo_job.rb` | ✅ existe (= `GeneratePreLaudoJob` do spec) |
| `ProcessDocumentsJob` | `app/jobs/process_documents_job.rb` | ✅ existe (extra) |

### ExtractProcessoJob

```ruby
# app/jobs/extract_processo_job.rb — A CRIAR
# Fase 1: lê o PDF do processo e extrai todos os dados
# Input: pericia_id
# Output: preenche campos da Pericia + cria 4 DocumentoBase
# (status será ajustado quando alinharmos os status states)
```

**O que o agente deve extrair do processo (buscar por seções-chave):**

O processo judicial é um PDF longo. As informações estão em seções específicas:

- **Página 1 / capa**: número do processo, nomes das partes e advogados
- **Petição inicial** (primeiras páginas): função do reclamante, datas de
  admissão/demissão, o que ele alega (resumo_inicial)
- **Contestação**: o que a reclamada alega (resumo_contestacao)
- **Decisão do juiz** (buscar "nomeando-se perito", "perícia", "e-mail"):
  tipo de perícia determinada, prazo do laudo, e-mails dos advogados
- **Quesitos**: buscar por "quesitos do reclamante", "quesitos da reclamada",
  "assistente técnico" — vêm logo após a audiência no processo

**Estratégia para PDF grande:** O processo pode ter 200+ páginas. Processar
em chunks: extrair texto por seções, usar embeddings ou busca por palavras-chave
para localizar os dados relevantes sem enviar o documento inteiro ao Claude.

### CleanTranscricaoJob

```ruby
# app/jobs/clean_transcricao_job.rb
# Fase 2: limpa transcrição do áudio e extrai informações estruturadas
# Input: pericia_document_id (do tipo 'transcricao')
# Output: JSON estruturado salvo no processo_pericial
```

**Contexto para o prompt de limpeza:**
- SPK_1 = a perita (faz as perguntas)
- SPK_4 = o reclamante (responde sobre sua rotina)
- SPK_2, 3, 5 = advogados e assistentes técnicos
- Erros comuns: "IPI" → "EPI", palavras cortadas, frases repetidas (bug de
  transcrição automática), nomes distorcidos
- O que interessa: rotina de trabalho, produtos usados, EPIs recebidos/usados,
  frequência das atividades, características do local

**Output JSON esperado:**
```json
{
  "rotina_trabalho": "descrição narrativa da rotina diária",
  "produtos_utilizados": ["hipoclorito de sódio", "desinfetante"],
  "epis_recebidos": ["luva impermeável", "bota"],
  "epis_utilizados": true,
  "assinou_ficha_epi": true,
  "frequencia_limpeza": "diária, 1-2 vezes por turno",
  "tempo_por_atividade": "1h30min por banheiro",
  "areas_trabalhadas": ["banheiros masculino/feminino", "salas", "área externa"],
  "tamanho_equipe": 6,
  "sistema_rodizio": true,
  "coleta_lixo": true,
  "tipo_lixo": "lixo de sanitários e salas, caçamba externa",
  "local_descricao": "secretaria municipal, prédio com térreo e 1° andar",
  "quantidade_banheiros": "13 vasos, 11 pias, 2 chuveiros",
  "observacoes": "reclamante trabalhava sozinho no banheiro do térreo"
}
```

### GeneratePreLaudoJob

```ruby
# app/jobs/generate_pre_laudo_job.rb
# Fase 2: gera cada seção do pré-laudo
# Roda uma seção por vez para evitar timeout e dar feedback ao perito
# Input: processo_pericial_id, secao_codigo (opcional — regenerar 1 seção)
# Output: cria/atualiza LaudoSection + QuesitoResposta
# Muda status: processando_pos_visita → pre_laudo_em_revisao
```

---

## System Prompt Base para Geração do Laudo

```
Você é um perito judicial especializado em laudos técnicos periciais
trabalhistas de insalubridade e periculosidade, com expertise nas
Normas Regulamentadoras NR-6, NR-10, NR-13, NR-15, NR-16 e NR-17.

Você deve gerar o conteúdo de seções específicas de laudos técnicos
periciais, seguindo estritamente:

1. LINGUAGEM: Técnica, formal, em terceira pessoa, no padrão de
   laudos periciais trabalhistas brasileiros.
   Exemplo correto: "Conforme evidenciado durante a perícia, foram
   constatadas atividades ou operações insalubres, envolvendo agentes
   biológicos, de acordo com o Anexo nº 14 da NR-15..."

2. CITAÇÕES LEGAIS: Sempre cite o número da NR, o item/subitem e
   o Anexo específico.
   Exemplo: "NR-15, Anexo 14, Portaria 3.214/78" ou "Súmula 448 TST"

3. INFORMAÇÃO INSUFICIENTE: Quando não houver dados suficientes, use
   [VERIFICAR NA DILIGÊNCIA] ou [INSERIR DADOS MEDIDOS] — nunca invente
   valores de medição ou dados que não foram fornecidos.

4. NEUTRALIDADE: Apresente as versões das partes separadamente antes
   da análise técnica. A análise deve ser baseada nas NRs.

5. CONCLUSÃO DE CADA AGENTE: Sempre termine com veredicto explícito:
   "INSALUBRE EM GRAU MÁXIMO/MÉDIO/MÍNIMO" ou "NÃO INSALUBRE",
   com a fundamentação legal específica citada.
```

---

## Templates dos Documentos Base (ARQ 1-4)

### ARQ 1 — Petição de Designação de Perícia

```
Excelentíssimo(a) Juiz(a) do Trabalho da {vara} de {comarca} - SP

Processo nº {numero_processo}
Reclamante: {reclamante_nome}
Reclamado 1: {reclamada_1_nome}
{se reclamada_2: Reclamado 2: {reclamada_2_nome}}

{nome_perito}, {titulo_perito}, nomeada perito no processo
supramencionado, vem a presença de V. Exa. informar que a perícia
técnica para apuração de {tipo_pericia} foi marcada para o dia
{data_pericia}, às {hora_pericia}, tendo sido encaminhado e-mail
aos advogados das partes:

Reclamante: {email_adv_reclamante}
1ª Reclamada: {email_adv_reclamada_1}
{se reclamada_2: 2ª Reclamada: {email_adv_reclamada_2}}

Nestes termos,
Pede deferimento.
```

### ARQ 2 — E-mail para Advogados

```
Prezados Advogados:

Informo que a perícia técnica para apuração de {tipo_pericia} foi
marcada para o dia {data_pericia}, às {hora_pericia}, a ser realizada
em {local_pericia}.

[corpo padrão: lista de documentos solicitados]
[a lista de documentos é SEMPRE a mesma — ver lista completa abaixo]

Documentos solicitados à reclamada:
1. PPRA/PGR completo de todo o período laboral
2. ASOs (admissional, periódico, retorno, mudança de função, demissional)
3. PPP (Perfil Profissiográfico Previdenciário)
4. Fichas de EPI assinadas (ordem cronológica, único PDF)
5. Recibos/certificados de treinamentos (NR-01, NR-06)
6. Descrição de cargos
7. FDS/FISPQ dos produtos utilizados
8. Notificação Compulsória (Portaria GM/MS nº 10.175/2026)
9. Outros que julgarem necessários
```

### ARQ 3 — Termo de Comparecimento

```
{vara} / SP – {regiao_trt}

Processo nº {numero_processo}
Reclamante: {reclamante_nome}
Reclamado 1: {reclamada_1_nome}
{se reclamada_2: Reclamado 2: {reclamada_2_nome}}

Objetivo: Perícia de {tipo_pericia}
Data e hora da Perícia: {data_pericia} às {hora_pericia}
Endereço: {local_pericia}
Admissão: {reclamante_admissao}  Demissão: {reclamante_demissao}
Função: {reclamante_funcao}

Acompanhantes:
[preenchido pelo perito durante a visita]

Versão do Reclamante:
[preenchido pelo perito durante a visita]

Versão da Reclamada:
[preenchido pelo perito durante a visita]
```

### ARQ 4 — Análise do Perito

```
Avaliação do Perito referente às informações da Reclamada e Reclamante

{vara} / SP – {regiao_trt}
Processo nº {numero_processo}
[dados das partes]
Admissão: {admissao}  Demissão: {demissao}  Função: {funcao}

Quesitos do Reclamante:
{quesitos extraídos do processo, numerados}

Quesitos da 1ª Reclamada:
{quesitos extraídos do processo, numerados}

{se houver 2ª reclamada:
Quesitos da 2ª Reclamada:
{quesitos, numerados}}

DA INICIAL:
{resumo_inicial}

DA CONTESTAÇÃO:
{resumo_contestacao}
```

---

## Interface da Plataforma

### Tela principal: lista de processos
- Card por processo: número, partes, status com badge colorido, ações

### Fase 1: revisão dos documentos base
- Tabs: ARQ 1 | ARQ 2 | ARQ 3 | ARQ 4
- Cada tab: visualização do documento preenchido + botão "Editar"
- Edição inline na plataforma (não gera arquivo ainda)
- Botão "Confirmar e prosseguir" → muda status para aguardando_visita

### Fase 2: upload pós-visita
- Área de upload múltiplo por tipo de documento
- Upload do ARQ 3 e ARQ 4 preenchidos à mão (scan ou digitado)
- Checkbox: quais agentes estão presentes no caso
- Botão "Gerar Pré-Laudo" → dispara GeneratePreLaudoJob

### Fase 2: revisão do pré-laudo
- Lista de seções com barra de progresso (X/Y revisadas)
- Cada seção: título, textarea editável, badge de status
- Botão "Salvar e revisar" por seção
- Botão "Regenerar esta seção" (só regenera uma seção)
- Botão "Gerar PDF Final" aparece apenas quando tudo revisado
- Usar Turbo Frames por seção (sem reload de página)
- Usar Stimulus para auto-resize de textarea e dirty state

---

## Estratégia para Processos Grandes

O processo judicial pode ter 200-500+ páginas. Estratégia em duas etapas:

**Etapa 1 — Extração por palavras-chave:**
Buscar no texto por marcadores conhecidos:
- Capa: "RECLAMANTE:", "RECLAMADO:", "ADVOGADO:"
- Decisão de nomeação: "nomeando-se perito", "e-mail:"
- Quesitos: "Quesitos do Reclamante", "Quesitos da Reclamada"
- Inicial: primeiras páginas após a capa
- Contestação: seção marcada como "CONTESTAÇÃO"

**Etapa 2 — Enviar só os trechos relevantes ao Claude:**
Não enviar o processo inteiro. Enviar apenas os chunks onde cada
informação foi encontrada — reduz tokens e melhora precisão.

**Serviço:** `app/services/processo_extractor.rb`
- Usa `pdf-reader` para extrair texto página por página
- Identifica seções por regex/palavras-chave
- Envia chunks relevantes ao Claude com prompts específicos por dado

---

## Base de Laudos de Referência

Para o futuro (quando a plataforma estiver mais robusta), os laudos
existentes podem ser usados como base de conhecimento (RAG):
- Laudos armazenados e indexados por tipo de caso e agentes identificados
- Na hora de gerar uma seção, buscar laudos similares como exemplos
- Passar 2-3 exemplos relevantes no prompt (few-shot)

**Por ora:** usar os laudos analisados como exemplos fixos nos prompts
das seções mais comuns (agentes biológicos, químicos).

---

## Exemplos Reais de Seções do Laudo

### Seção 5.3.4 — Agentes Biológicos (caso insalubre grau máximo)

> A atividade laboral sujeitava o reclamante ao contato com agentes
> biológicos provenientes de resíduos diversos. [...] Na área de limpeza,
> a legislação apresenta o seguinte parâmetro para classificação da
> atividade como insalubre por agentes biológicos: Insalubridade de grau
> máximo para trabalhos ou operações, em contato permanente, com esgotos
> (galerias e tanques) – NR-15, Anexo 14. [...]
>
> Conforme Súmula nº 448 do TST: "II - A higienização de instalações
> sanitárias de uso público ou coletivo de grande circulação, e a
> respectiva coleta de lixo, por não se equiparar à limpeza em residências
> e escritórios, enseja o pagamento de adicional de insalubridade em grau
> máximo, incidindo o disposto no Anexo 14 da NR-15."
>
> Portanto, em vista das evidências constatadas na perícia e dos resultados
> das análises efetuadas em confronto com os dispositivos legais,
> concluímos que o reclamante desempenhou atividade classificada como
> **INSALUBRE EM GRAU MÁXIMO**, em conformidade com Anexo 14 da NR-15
> e Súmula nº 448 do TST, durante o período contratual.

### Seção 5.3.3 — Agentes Químicos (caso NÃO insalubre)

> Considerando a diluição dos produtos químicos e que os EPIs fornecidos
> foram suficientes para elidir os agentes químicos, a atividade deve ser
> considerada **NÃO INSALUBRE** conforme NR-15, Anexo 13 – Operações
> Diversas, no período laboral do reclamante.

### Resposta padrão a quesito remissivo

> **Resp.:** Conforme descrito no item 5.3.4 deste laudo.

---

## Segurança e Proteção de Dados (LGPD)

Os processos judiciais contêm dados pessoais sensíveis: CPF, RG, nome completo,
dados de saúde, histórico profissional. A LGPD (Lei 13.709/2018) exige proteção
adequada. Implementar desde o início, não como afterthought.

### Isolamento de dados por usuário (multitenancy simples)

Cada perito só pode ver e acessar seus próprios processos. Implementar via
scope obrigatório em todos os controllers:

```ruby
# app/controllers/application_controller.rb
def current_processo
  current_user.pericias.find(params[:id])
  # Raise ActiveRecord::RecordNotFound se não pertencer ao usuário
  # Rails retorna 404 automaticamente — nunca expõe dados de outro usuário
end
```

**Regra:** NUNCA usar `Pericia.find(id)` diretamente nos controllers.
SEMPRE usar `current_user.pericias.find(id)`.

### Dados sensíveis no banco

Os campos a seguir contêm dados pessoais e devem ser tratados com cuidado:
`reclamante_nome`, `reclamante_admissao`, `reclamante_demissao`,
`email_adv_*`, todos os campos de texto dos documentos e do laudo.

Por ora (MVP com uma perita): o banco PostgreSQL com acesso restrito é suficiente.
Para o futuro com múltiplos peritos: avaliar criptografia em nível de campo
usando a gem `lockbox` para os campos mais sensíveis.

### Arquivos (Active Storage + Cloudinary)

Os PDFs do processo, áudios e fotos são armazenados no Cloudinary.
Configurar o Cloudinary com:
- Acesso privado (não público) para todos os uploads desta plataforma
- URLs assinadas com expiração para acesso aos arquivos
- Nunca usar URLs públicas permanentes para documentos de processo

```ruby
# config/storage.yml — em produção usar configuração privada
# Os arquivos NÃO devem ser acessíveis por URL direta sem autenticação
```

### Logs e dados em trânsito

```ruby
# config/initializers/filter_parameter_logging.rb
# Adicionar aos filtros já existentes:
Rails.application.config.filter_parameters += [
  :reclamante_nome, :cpf, :rg, :conteudo, :texto_extraido
]
```

HTTPS obrigatório em produção — configurar `config.force_ssl = true` em
`config/environments/production.rb`.

### Dados enviados à API do Claude (Anthropic)

Os textos dos processos são enviados à API do Claude para extração e geração.
Isso significa que dados pessoais passam pela Anthropic.

**Para o MVP (uso interno, uma perita):** aceitável com a política de privacidade
atual da Anthropic para API (dados não usados para treinar modelos por padrão).

**Para o futuro com múltiplos peritos e clientes:** considerar:
- Assinar DPA (Data Processing Agreement) com a Anthropic
- Anonimizar dados antes de enviar ao Claude quando possível
  (ex: substituir nomes reais por "RECLAMANTE" nos prompts)
- Documentar na política de privacidade da plataforma que dados são
  processados por IA de terceiro

### Autenticação e sessões

Devise já instalado. Configurações obrigatórias:
- Confirmação de e-mail habilitada (`:confirmable` no User)
- Timeout de sessão após inatividade
- Senha mínima de 8 caracteres (já configurado no devise.rb)
- Em produção: adicionar rate limiting no login (gem `rack-attack`)

### Preparação para múltiplos peritos (futuro)

Quando a plataforma crescer para múltiplos usuários, adicionar:

**Separação por escritório/organização:**
```ruby
# Model futuro: Organizacao
# User belongs_to :organizacao
# ProcessoPericial belongs_to :organizacao
# Scopes sempre filtram por organizacao_id
```

**Planos e limites:**
- Controlar número de processos ativos por usuário
- Logs de auditoria: quem acessou o quê e quando
- Possibilidade de um perito ver processos de outro dentro da mesma org

**Gems a avaliar no futuro:**
- `pundit` ou `action_policy` — autorização granular por recurso
- `paper_trail` — auditoria de quem editou o quê e quando
- `rack-attack` — rate limiting e proteção contra força bruta
- `lockbox` — criptografia de campos sensíveis no banco

### Backup e retenção de dados

- Backup diário do banco PostgreSQL em local separado do servidor
- Definir política de retenção: por quanto tempo guardar processos concluídos
  (sugestão: 5 anos, conforme prazo prescricional trabalhista)
- Processo claro para exclusão de dados a pedido (direito ao esquecimento, LGPD)

---

## Regras para o Claude Code

1. **Não criar models sem migration** — sempre `rails db:migrate` após gerar
2. **Jobs sempre via Solid Queue** — não usar outros adaptadores
3. **Uploads via Active Storage** — Cloudinary já configurado
4. **ruby_llm configurado** — usar `RubyLLM.chat(model: "claude-sonnet-4-6")` para chamar o Claude
5. **Stimulus para interatividade** — não usar JS vanilla fora de controllers
6. **Turbo Frames para atualizações parciais** — especialmente na revisão
7. **PDF do laudo final nunca antes de todas as seções revisadas**
8. **Status como state machine** — validar transições no model
9. **Textos podem ser longos** — sempre usar `text`, nunca `string` para conteúdo
10. **Processar PDF do processo em chunks** — nunca enviar o arquivo inteiro ao Claude
11. **Jobs granulares** — um job por seção do laudo, não tudo de uma vez
12. **ARQ 1-4 têm dois momentos distintos:**
    - **Fase 1:** agente preenche automaticamente, perito edita na plataforma,
      depois exporta como PDF (ARQ 1, 3, 4) ou texto de e-mail (ARQ 2)
      para uso ANTES da visita — protocolar no PJe, enviar aos advogados,
      imprimir para levar na diligência
    - **Fase 2:** ARQ 3 e ARQ 4 voltam preenchidos pelo perito após a visita
      (upload do scan ou digitação na plataforma) e alimentam o pré-laudo
