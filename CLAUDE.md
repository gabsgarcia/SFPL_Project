# CLAUDE.md — Plataforma de Laudos Periciais Trabalhistas

## Visão Geral do Projeto

Sistema Rails para automatizar a geração de laudos técnicos periciais de
insalubridade e periculosidade em processos trabalhistas. O perito faz upload
dos documentos do caso e de áudios/transcrições da visita pericial, e o agente
de IA gera um rascunho completo do laudo para revisão campo a campo antes da
exportação em PDF.

## Stack Tecnológica

- **Ruby 3.3.5 / Rails 8.1**
- **PostgreSQL** (banco principal)
- **ruby_llm ~> 1.2.0** — chamadas ao Claude (Anthropic) — JÁ INSTALADO
- **Devise** — autenticação — JÁ INSTALADO
- **Active Storage + Cloudinary** — upload de arquivos — JÁ INSTALADO
- **Solid Queue** — jobs assíncronos — JÁ INSTALADO
- **Bootstrap 5.3 + Stimulus + Turbo** — frontend — JÁ INSTALADO
- **pdf-reader** — extrair texto de PDFs (ADICIONAR)
- **docx** — extrair texto de arquivos Word (ADICIONAR)
- **roo** — extrair texto de planilhas Excel (ADICIONAR)
- **wicked_pdf + wkhtmltopdf-binary** — gerar PDF final do laudo (ADICIONAR)

## Domínio do Negócio

### O que é uma perícia trabalhista de insalubridade/periculosidade

Quando um trabalhador processa uma empresa exigindo adicional de insalubridade
ou periculosidade, o juiz nomeia um perito para investigar as condições reais de
trabalho. O perito:

1. Agenda a visita e notifica os advogados das partes
2. Recebe documentos da empresa (PPRA/PGR, ASOs, PPP, fichas de EPI etc.)
3. Faz a visita pericial no local de trabalho, entrevista reclamante e preposto
4. Analisa tudo à luz das NRs aplicáveis
5. Entrega o laudo técnico ao juiz respondendo os quesitos das partes

### Normas Regulamentadoras relevantes

- **NR-6** — EPIs: valida se os equipamentos fornecidos eram adequados e
  suficientes para elidir ou neutralizar o agente nocivo
- **NR-10** — Eletricidade: instalações e serviços elétricos
- **NR-13** — Caldeiras, vasos de pressão e tubulações
- **NR-15** — Insalubridade (a mais importante):
  - Anexo 01: Ruído (medição em dB, comparar com limites de tolerância)
  - Anexo 03: Calor (IBUTG, atividade leve/moderada/pesada)
  - Anexo 11: Agentes químicos com limites de tolerância
  - Anexo 12: Poeiras minerais
  - Anexo 13: Operações diversas (inclui álcalis cáusticos — detergentes
    industriais, hipoclorito — grau médio)
  - Anexo 14: Agentes biológicos — lixo urbano e higienização de sanitários
    públicos/coletivos = GRAU MÁXIMO (Súmula 448 TST)
- **NR-16** — Periculosidade:
  - Anexo 01: Explosivos
  - Anexo 02: Inflamáveis (armazenamento, manuseio)
  - Anexo 03: Roubos/violência (segurança patrimonial)
  - Anexo 04: Energia elétrica
  - Anexo 05: Motocicleta
- **NR-17** — Ergonomia: AET (Análise Ergonômica do Trabalho), levantamento
  de peso, posturas, repetitividade, iluminação

### Jurisprudência importante a conhecer

- **Súmula 448 TST**: higienização de sanitários públicos/coletivos de grande
  circulação + coleta de lixo = insalubre grau máximo (Anexo 14 NR-15)
- **Art. 191 CLT**: a eliminação ou neutralização da insalubridade ocorrerá
  com a adoção de EPI eficaz — mas para agentes biológicos (Anexo 14) o EPI
  não elide, apenas minimiza

---

## Estrutura dos Modelos

### ProcessoPericial (modelo central)

```ruby
# Representa um processo judicial trabalhista completo
# Pertence a um User (o perito)
campos:
  numero_processo: string       # ex: "1001760-11.2025.5.02.0292"
  vara: string                  # ex: "2ª Vara do Trabalho"
  comarca: string               # ex: "Franco da Rocha"
  regiao_trt: string            # ex: "TRT 02ª Região"
  reclamante: string
  reclamada_1: string
  reclamada_2: string           # nullable — nem sempre há segunda reclamada
  funcao_reclamante: string     # ex: "auxiliar de limpeza"
  admissao: date
  demissao: date
  tipo_pericia: string          # "insalubridade" | "periculosidade" | "ambos"
  status: string                # ver abaixo
  data_pericia: datetime        # data/hora da visita agendada
  local_pericia: text           # endereço completo da visita

  # Agentes identificados (define quais seções gerar no laudo)
  tem_ruido: boolean
  tem_calor: boolean
  tem_quimico: boolean
  tem_biologico: boolean
  tem_eletricidade: boolean
  tem_inflamavel: boolean
  tem_ergonomia: boolean

  # Metadados do laudo gerado
  honorarios_salarios: integer  # ex: 4 (quatro salários mínimos)
  observacoes_perito: text      # notas internas do perito
```

**Status do ProcessoPericial:**
```
draft           → processo criado, aguardando documentos
documentos_ok   → documentos recebidos e processados
agendado        → visita agendada, e-mails enviados
vistoria_feita  → visita realizada, transcrição disponível
processando     → agente de IA gerando o laudo
em_revisao      → laudo gerado, perito revisando
concluido       → laudo aprovado e PDF gerado
```

### PericiaDocument

```ruby
# Cada arquivo enviado para o processo
# belongs_to :processo_pericial
# has_one_attached :file (Active Storage)
campos:
  document_type: string   # ver tipos abaixo
  nome_original: string
  texto_extraido: text    # conteúdo extraído pelo DocumentExtractor
  processado: boolean     # já foi extraído o texto?
```

**Tipos de documento:**
- `ppra` / `pgr` — Programa de Prevenção de Riscos / Gerenciamento de Risco
- `aso` — Atestado de Saúde Ocupacional
- `ppp` — Perfil Profissiográfico Previdenciário
- `epi_ficha` — Ficha de entrega de EPIs assinada pelo reclamante
- `treinamento` — Certificados e listas de presença de treinamentos
- `descricao_cargo` — Descrição formal do cargo
- `fds` / `fispq` — Ficha de Dados de Segurança dos produtos químicos
- `laudo_paradigma` — Laudos de casos similares trazidos pela reclamada
- `ltcat` — Laudo Técnico das Condições Ambientais do Trabalho
- `pcmso` — Programa de Controle Médico de Saúde Ocupacional
- `aet` — Análise Ergonômica do Trabalho
- `transcricao` — Transcrição do áudio da visita pericial
- `audio` — Arquivo de áudio original da visita
- `foto` — Fotos tiradas durante a visita pericial
- `outro` — Outros documentos

### LaudoSection

```ruby
# Cada seção do laudo técnico gerado
# belongs_to :processo_pericial
campos:
  codigo: string      # ex: "5.3.2", "6.1", "7.2"
  titulo: string      # ex: "Agente Físico: Calor (Anexo 03 NR-15)"
  conteudo: text      # texto gerado pelo Claude, editável pelo perito
  ordem: integer
  revisado: boolean
  aplicavel: boolean  # false quando a seção não se aplica ao caso
```

**Seções fixas do laudo (sempre nesta ordem):**
```
codigo  | titulo
--------|----------------------------------------------------------
"intro" | Petição ao Juízo + Introdução
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
"5.4"   | Apuração de Periculosidade (NR-16)
"5.5"   | Análise Ergonômica — AET (NR-17)
"5.3.x" | Outros agentes
"6.1"   | Conclusão — Insalubridade
"6.2"   | Conclusão — Periculosidade
"6.3"   | Conclusão — Ergonomia
"7.1"   | Respostas aos quesitos do Juízo
"7.2"   | Respostas aos quesitos do Reclamante
"7.3"   | Respostas aos quesitos da Reclamada (1ª e 2ª)
```

### QuesitoResposta

```ruby
# Cada quesito das partes e sua resposta no laudo
# belongs_to :processo_pericial
campos:
  origem: string      # "juizo" | "reclamante" | "reclamada_1" | "reclamada_2"
  numero: integer
  texto_quesito: text
  resposta: text      # gerada pelo Claude, editável pelo perito
  revisado: boolean
```

---

## Fluxo de Trabalho Completo

```
1. Perito cria ProcessoPericial (dados do processo)
         ↓
2. Perito faz upload dos documentos recebidos da reclamada
   (PPRA, ASO, PPP, fichas EPI, FDS, etc.)
         ↓
3. ProcessDocumentsJob roda em background:
   - Extrai texto de cada arquivo (PDF, DOCX, XLSX)
   - Salva em pericia_document.texto_extraido
         ↓
4. Perito faz upload da transcrição/áudio da visita pericial
         ↓
5. CleanTranscricaoJob (Agente 1):
   - Recebe transcrição bruta (com erros de reconhecimento)
   - Identifica falantes: SPK perito, SPK reclamante, SPK advogados
   - Corrige erros óbvios de transcrição automática
   - Extrai informações estruturadas em JSON:
     * rotina_trabalho, produtos_utilizados, epis_declarados,
       frequencia_atividades, descricao_local, equipe_tamanho
         ↓
6. Perito marca quais agentes estão presentes no caso
   (ruído, calor, químicos, biológicos, etc.)
         ↓
7. GenerateLaudoJob (Agente 2):
   - Gera cada seção do laudo sequencialmente
   - Para cada seção: monta contexto específico + chama Claude
   - Salva resultado em laudo_sections
   - Muda status para "em_revisao"
         ↓
8. Perito revisa seção por seção na interface web
   - Edita conteúdo de cada seção
   - Marca como revisado
   - Pode pedir regeneração de uma seção específica
         ↓
9. Perito gera PDF final
   - PDF formatado com o layout padrão do escritório
   - Numeração de páginas, cabeçalho com dados do processo
```

---

## Serviços de IA

### Agente 1 — CleanTranscricaoService

**Localização:** `app/services/clean_transcricao_service.rb`

**Objetivo:** Limpar transcrição automática e extrair informações estruturadas

**Contexto para o prompt:**
- A transcrição vem de ferramentas automáticas (Transkriptor, Whisper etc.)
- SPK_1 geralmente é a perita
- SPK_4 geralmente é o reclamante
- SPK_2, SPK_3, SPK_5 são advogados e assistentes técnicos
- Erros comuns: "IPI" → "EPI", nomes distorcidos, palavras cortadas
- Perguntas da perita orientam o que o reclamante relata

**Output esperado (JSON):**
```json
{
  "rotina_trabalho": "descrição narrativa da rotina",
  "produtos_utilizados": ["hipoclorito de sódio", "desinfetante", "detergente"],
  "epis_recebidos": ["luva", "bota"],
  "epis_utilizados": true,
  "assinou_ficha_epi": true,
  "frequencia_lavagem_banheiro": "diária, 1-2 vezes",
  "tempo_por_banheiro": "1h30min",
  "areas_trabalhadas": ["banheiros", "salas administrativas", "área externa"],
  "tamanho_equipe": 6,
  "sistema_rodizio": true,
  "coleta_lixo": true,
  "tipo_lixo": "lixo de sanitários e salas, caçamba externa",
  "local_trabalho_descricao": "secretaria municipal, prédio com térreo e 1° andar",
  "observacoes_adicionais": "..."
}
```

### Agente 2 — GenerateLaudoService

**Localização:** `app/services/generate_laudo_service.rb`

**Objetivo:** Gerar cada seção do laudo com linguagem técnica pericial

**System prompt base:**
```
Você é um perito judicial especializado em laudos técnicos periciais
trabalhistas de insalubridade e periculosidade, com expertise nas
Normas Regulamentadoras NR-6, NR-10, NR-13, NR-15, NR-16 e NR-17.

Você deve gerar o conteúdo de seções específicas de laudos técnicos
periciais, seguindo estritamente:

1. LINGUAGEM: Técnica, formal, em terceira pessoa, no padrão de
   laudos periciais trabalhistas brasileiros. Exemplo de tom:
   "Conforme evidenciado durante a perícia, foram constatadas
   atividades ou operações insalubres, envolvendo agentes biológicos,
   de acordo com o Anexo nº 14 da NR-15..."

2. CITAÇÕES LEGAIS: Sempre cite o número da NR, o item/subitem e
   o Anexo específico. Exemplo: "NR-15, Anexo 14, Portaria 3.214/78"

3. ESTRUTURA: Siga exatamente a estrutura e numeração solicitada.

4. QUANDO NÃO HÁ INFORMAÇÃO SUFICIENTE: Use [VERIFICAR NA DILIGÊNCIA]
   ou [INSERIR DADOS MEDIDOS] — nunca invente valores ou medições.

5. NEUTRALIDADE: Apresente as versões das partes separadamente antes
   da análise técnica. A análise deve ser baseada nas NRs, não em
   opiniões subjetivas.

6. CONCLUSÃO: Sempre termine cada agente com veredicto claro:
   "INSALUBRE EM GRAU MÁXIMO/MÉDIO/MÍNIMO" ou "NÃO INSALUBRE",
   com a fundamentação legal específica.
```

**Como gerar cada seção:**

Para seções descritivas (2.1, 2.2, 3, 4):
```
Contexto = dados do processo + texto da transcrição limpa (JSON)
           + textos dos documentos relevantes
```

Para seções de apuração (5.3.x, 5.4, 5.5):
```
Contexto = dados do processo + transcrição limpa + documentos técnicos
           + texto do Anexo da NR aplicável + decisões do PPRA/PGR
```

Para seções de conclusão (6.x):
```
Contexto = conteúdo gerado nas seções 5.3.x correspondentes
           (resumir e concluir com veredicto final)
```

Para respostas aos quesitos (7.x):
```
Para cada quesito: texto do quesito + seção do laudo onde a resposta
está fundamentada. A maioria responde com "Conforme descrito no item X."
```

---

## Padrões de Código Rails

### Jobs (usar Solid Queue)

```ruby
# app/jobs/generate_laudo_job.rb
class GenerateLaudoJob < ApplicationJob
  queue_as :default

  def perform(processo_pericial_id, secao_codigo = nil)
    processo = ProcessoPericial.find(processo_pericial_id)
    processo.update!(status: "processando")

    service = GenerateLaudoService.new(processo)

    if secao_codigo
      # Regenerar uma seção específica
      service.generate_section(secao_codigo)
    else
      # Gerar todas as seções aplicáveis
      service.generate_all
      processo.update!(status: "em_revisao")
    end
  rescue => e
    processo.update!(status: "erro_geracao")
    raise e
  end
end
```

### Services

```ruby
# app/services/document_extractor.rb
# Extrai texto de PDF, DOCX, XLSX
# Retorna string com o texto extraído ou mensagem de erro

# app/services/clean_transcricao_service.rb
# Recebe texto bruto da transcrição
# Chama Claude com prompt de limpeza
# Retorna JSON estruturado

# app/services/generate_laudo_service.rb
# Orquestra a geração de todas as seções
# Para cada seção: monta contexto + chama Claude + salva LaudoSection
```

### Controllers

```ruby
# ProcessoPericialController — CRUD do processo
# PericiaDocumentsController — upload e listagem de documentos
# LaudoSectionsController — edição e revisão das seções
# QuesitoRespostasController — edição das respostas
# PdfController — geração do PDF final
```

### Rotas esperadas

```ruby
resources :processo_pericials do
  resources :pericia_documents, only: [:create, :destroy]
  resources :laudo_sections, only: [:update]
  resources :quesito_respostas, only: [:update]
  member do
    post :generate_laudo    # dispara GenerateLaudoJob
    post :generate_pdf      # gera PDF final
    post :generate_docs     # gera petição + e-mail para advogados
    get  :review            # interface de revisão do laudo
  end
end
```

---

## Interface de Revisão (padrão UX)

A tela de revisão (`/processo_pericials/:id/review`) deve:

1. Mostrar as seções do laudo em ordem, num layout de lista
2. Cada seção tem:
   - Cabeçalho com código + título (ex: "5.3.4 — Agentes Biológicos")
   - Badge verde "✓ Revisado" ou amarelo "Pendente"
   - Textarea editável com o conteúdo gerado pelo Claude
   - Botão "Salvar e marcar revisado"
   - Botão "Regenerar esta seção" (dispara job só para essa seção)
3. Barra de progresso mostrando X/Y seções revisadas
4. Botão "Gerar PDF" aparece apenas quando todas as seções estão revisadas
5. Usar Turbo Frames para cada seção (atualização sem reload)
6. Usar Stimulus para o comportamento do textarea (auto-resize, dirty state)

---

## Documentos Gerados Automaticamente

Além do laudo, o sistema deve gerar:

### ARQ 1 — Petição de Designação de Perícia
Template fixo para o juiz informando data/hora da visita agendada.
Campos: número do processo, reclamante, reclamados, data, e-mails das partes.

### ARQ 2 — E-mail para Advogados
Notificação formal da perícia com a lista padronizada de documentos solicitados.
A lista de documentos é sempre a mesma (PPRA, ASO, PPP, EPI, etc.).

### Laudo PDF Final
Seguir o layout dos laudos de referência:
- Cabeçalho em todas as páginas: nome do perito, título, e-mail, linha separadora
- Rodapé: número da página e número do processo
- Sumário na página 2
- Corpo do laudo com numeração de seções
- Assinatura ao final

---

## Exemplos Reais de Seções do Laudo

### Exemplo de seção 5.3.2 — Agentes Biológicos (caso auxiliar de limpeza)

> A atividade laboral, sujeitava o reclamante ao contato com agentes biológicos
> provenientes de resíduos diversos.
>
> Os agentes biológicos constituem substrato privilegiado como meio de cultura
> para abrigar, desenvolver e disseminar agentes patológicos como bactérias do
> grupo entérico e algumas viroses tais como a poliomielite e a hepatite.
>
> Na área de limpeza, a legislação apresenta o seguinte parâmetro para
> classificação da atividade como insalubre por agentes biológicos: Insalubridade
> de grau máximo para trabalhos ou operações, em contato permanente, com esgotos
> (galerias e tanques) – NR 15, Anexo 14.
>
> As pias e vasos sanitários nada mais são que componentes do esgoto na sua fase
> inicial. A limpeza e higienização dos banheiros e vasos sanitários eram
> realizados diariamente. Existia o risco de contágio com agentes biológicos.
>
> [...]
>
> Conforme Súmula nº 448 do TST: [...] "II - A higienização de instalações
> sanitárias de uso público ou coletivo de grande circulação, e a respectiva
> coleta de lixo, por não se equiparar à limpeza em residências e escritórios,
> enseja o pagamento de adicional de insalubridade em grau máximo, incidindo o
> disposto no Anexo 14 da NR-15 da Portaria do MTE nº 3.214/78 quanto à coleta
> e industrialização de lixo urbano."
>
> Portanto, em vista das evidências constatadas na perícia e dos resultados das
> análises efetuadas em confronto com os dispositivos legais, concluímos que o
> reclamante desempenhou atividade classificada como **INSALUBRE EM GRAU MÁXIMO**,
> em conformidade com Anexo 14 da NR-15 e Súmula nº 448 do TST, durante o
> período contratual.

### Exemplo de seção 5.3.1 — Agentes Químicos (quando NÃO insalubre)

> Considerando a diluição dos produtos químicos e que os EPI's fornecidos foram
> suficientes para elidir os agentes químicos, a atividade deve ser considera
> **NÃO INSALUBRE** conforme NR-15 Anexo 13 – Operações Diversas, no período
> laboral do reclamante.

### Exemplo de resposta a quesito padrão

> **Quesito 01 da Reclamada:** Queira o Sr. perito informar se os equipamentos
> de proteção individual utilizados pelo Autor são adequados à atividade exercida.
>
> **Resp.:** Conforme descrito no item 3 deste laudo.

---

## Gems a Adicionar (Gemfile)

```ruby
# Extração de texto de documentos
gem "pdf-reader"         # PDFs
gem "docx"               # Arquivos Word .docx
gem "roo"                # Planilhas Excel .xlsx

# Geração de PDF do laudo
gem "wicked_pdf"
gem "wkhtmltopdf-binary"

# Opcional: processamento de imagens/fotos da vistoria
# já tem image_processing instalado
```

---

## Migrações a Criar

Execute nesta ordem:

```bash
rails generate model ProcessoPericial \
  user:references numero_processo:string vara:string comarca:string \
  regiao_trt:string reclamante:string reclamada_1:string \
  reclamada_2:string funcao_reclamante:string admissao:date \
  demissao:date tipo_pericia:string status:string \
  data_pericia:datetime local_pericia:text \
  tem_ruido:boolean tem_calor:boolean tem_quimico:boolean \
  tem_biologico:boolean tem_eletricidade:boolean \
  tem_inflamavel:boolean tem_ergonomia:boolean \
  honorarios_salarios:integer observacoes_perito:text

rails generate model PericiaDocument \
  processo_pericial:references document_type:string \
  nome_original:string texto_extraido:text processado:boolean

rails generate model LaudoSection \
  processo_pericial:references codigo:string titulo:string \
  conteudo:text ordem:integer revisado:boolean aplicavel:boolean

rails generate model QuesitoResposta \
  processo_pericial:references origem:string numero:integer \
  texto_quesito:text resposta:text revisado:boolean
```

---

## Arquivos de Referência Disponíveis

Os seguintes arquivos foram analisados para construir este CLAUDE.md e podem
ser consultados como exemplos reais para os prompts do agente:

- `ARQ_1` — Petição de designação de perícia (template)
- `ARQ_2` — E-mail para advogados com lista de documentos (template)
- `ARQ_3` — Termo de comparecimento preenchido durante visita
- `ARQ_4` — Análise do perito: quesitos + análise cruzada
- `Transcrição_Áudio` — Exemplo real de transcrição de entrevista pericial
- `Laudo_Proc_1001760` — Laudo completo (caso auxiliar de limpeza)
- `L245`, `L338`, `L456`, `LAUDO_PERICIAL_1001536` — Outros laudos de referência

O laudo do Proc. 1001760 (auxiliar de limpeza em secretaria municipal) é o
caso de estudo principal — tem insalubridade por agentes biológicos (grau
máximo, Súmula 448 TST) e agentes químicos (não insalubre por diluição + EPI).

---

## Regras Importantes para o Claude Code

1. **Não criar models sem migration** — sempre rodar `rails db:migrate` após gerar
2. **Jobs sempre via Solid Queue** — não usar outros adaptadores
3. **Uploads via Active Storage** — o Cloudinary já está configurado
4. **ruby_llm já configurado** — usar `RubyLLM.chat` para chamar o Claude
5. **Stimulus para interatividade** — não usar JS vanilla fora de controllers
6. **Turbo Frames para atualizações parciais** — especialmente na tela de revisão
7. **Não gerar PDF antes de todas as seções estarem revisadas**
8. **Status do processo como state machine** — validar transições no model
9. **Textos extraídos podem ser longos** — usar `text` (não `string`) no banco
10. **Cada job gera UMA seção** — não gerar tudo em um job só (timeout + UX)
11. **Todo texto de interface em português** — escrever labels, botões, flash
    messages e textos de view diretamente em português nos ERBs, sem usar
    `t("chave")` i18n (o app é exclusivamente pt-BR). Os arquivos de locale
    (`pt-BR.yml`, `devise.pt-BR.yml`, `simple_form.pt-BR.yml`) cuidam das
    mensagens do framework. Locale padrão: `pt-BR`, timezone: `Brasilia`.
