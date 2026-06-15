# SFPL — Plataforma de Laudos Periciais Trabalhistas

Sistema Rails para automatizar o trabalho de **peritos judiciais** em processos trabalhistas de insalubridade e periculosidade. O perito faz upload do PDF do processo, a IA extrai os dados e preenche automaticamente os documentos de cada fase da perícia.

---

## Contexto do domínio

Quando um trabalhador processa uma empresa exigindo adicional de insalubridade ou periculosidade, o juiz nomeia um perito para investigar as condições reais de trabalho. O processo judicial (PDF com centenas de páginas) contém todos os dados necessários: partes, advogados, e-mails, quesitos e histórico.

O perito trabalha em três fases bem distintas:

- **Fase 1 — Pré-visita:** Lê o processo, prepara e envia documentos iniciais ao juiz e advogados.
- **Fase 2 — Pós-visita:** Processa o material da diligência (transcrição, fotos, documentos da reclamada) e gera o pré-laudo.
- **Fase 3 — Laudo final:** Revisa o pré-laudo seção por seção e exporta o PDF assinável.

---

## Stack

| Camada | Tecnologia |
|---|---|
| Backend | Ruby 3.3.5 / Rails 8.1 |
| Banco de dados | PostgreSQL |
| Autenticação | Devise |
| IA | ruby_llm ~> 1.2 (Claude / Anthropic) |
| Upload de arquivos | Active Storage + Cloudinary |
| Jobs assíncronos | Solid Queue |
| Frontend | Bootstrap 5.3 + Stimulus + Turbo (Hotwire) |
| Geração de PDF | wicked_pdf + wkhtmltopdf-binary |
| Extração de documentos | pdf-reader, docx, roo |

---

## Modelos principais

```
User
└── Pericia                → processo judicial completo (modelo central)
    ├── DocumentoBase      → ARQ 1-4, gerados pela IA na Fase 1 (conteúdo text/HTML)
    ├── PericiaDocument    → arquivos físicos da visita e da reclamada (Fase 2)
    ├── LaudoSection       → cada seção do pré-laudo gerado pela IA
    └── QuesitoResposta    → quesitos das partes e suas respostas
```

### Diferença entre DocumentoBase e PericiaDocument

| | `DocumentoBase` | `PericiaDocument` |
|---|---|---|
| Quando | Fase 1 (pré-visita) | Fase 2 (pós-visita) |
| Criado por | IA (`ExtractProcessoJob`) | Perito (upload manual) |
| Conteúdo | Texto/HTML editável na plataforma | Arquivo físico (PDF, áudio, foto) |
| Exemplos | ARQ 1 petição, ARQ 2 e-mail, ARQ 3 termo, ARQ 4 análise | PPRA, ASO, transcrição, fotos, ARQ 3/4 preenchidos |
| Exportação | PDF ou texto de e-mail | Visualização/download |

### Status do processo (`Pericia#status`)

```
rascunho → documentos_ok → agendado → vistoria_feita → processando → em_revisao → concluido
```

> Os status serão alinhados ao fluxo de 3 fases na Phase 4.

---

## Fluxo completo

### Fase 1 — Pré-visita

```
1. Perito cria a Pericia e faz upload do PDF do processo judicial
         ↓
2. ExtractProcessoJob (IA):
   Extrai do PDF: partes, advogados, e-mails, quesitos, tipo de perícia, prazo
         ↓
3. Plataforma cria os 4 DocumentoBase automaticamente:
   ARQ 1 — Petição ao juiz   (exporta PDF)
   ARQ 2 — E-mail advogados  (exporta texto)
   ARQ 3 — Termo de Comparecimento  (exporta PDF, perito leva na visita)
   ARQ 4 — Análise do Perito (exporta PDF, perito usa na visita)
         ↓
4. Perito revisa e edita os 4 documentos na plataforma
5. Exporta e envia (fora da plataforma por ora)
```

### Fase 2 — Pós-visita

```
6. Perito faz upload dos materiais da diligência:
   ARQ 3 e ARQ 4 preenchidos + documentos da reclamada + áudio/transcrição + fotos
         ↓
7. CleanTranscricaoJob (IA): limpa transcrição e extrai dados estruturados em JSON
         ↓
8. Perito marca quais agentes de risco estão presentes no caso
         ↓
9. GenerateLaudoJob (IA): gera cada seção do pré-laudo via Claude
```

### Fase 3 — Laudo final

```
10. Perito revisa o pré-laudo seção por seção na interface
    → edita, salva, marca como revisado, pode regenerar uma seção
         ↓
11. Exportação do laudo completo em PDF
```

---

## Configuração local

### Pré-requisitos

- Ruby 3.3.5
- PostgreSQL

### Instalação

```bash
git clone https://github.com/gabsgarcia/SFPL_Project.git
cd SFPL_Project

bundle install

cp .env.example .env
# Preencha as variáveis no .env (ver seção abaixo)

rails db:create db:migrate
rails server
```

### Variáveis de ambiente (`.env`)

```bash
# Cloudinary — upload de arquivos
CLOUDINARY_URL=cloudinary://...

# Anthropic — chamadas ao Claude via ruby_llm
ANTHROPIC_API_KEY=sk-ant-...
```

---

## Normas Regulamentadoras cobertas

| NR | Escopo |
|---|---|
| NR-6 | EPIs — validade e suficiência dos equipamentos de proteção |
| NR-10 | Eletricidade |
| NR-13 | Caldeiras, vasos de pressão e tubulações |
| NR-15 | Insalubridade (Ruído, Calor, Agentes Químicos, Biológicos) |
| NR-16 | Periculosidade (Inflamáveis, Energia Elétrica, Motocicleta) |
| NR-17 | Ergonomia — AET |

**Jurisprudência relevante:** Súmula 448 TST II — higienização de sanitários de uso público/coletivo de grande circulação = insalubre grau máximo (Anexo 14 NR-15).

---

## Fases de desenvolvimento

- [x] **Phase 1** — Modelos do domínio + internacionalização pt-BR
- [x] **Phase 2** — Rotas, controllers e upload de documentos
- [x] **Phase 3** — Extração de texto de documentos (pdf-reader, docx, roo) + wicked_pdf
- [ ] **Phase 4** — Serviços de IA: ExtractProcessoJob, DocumentoBase, ajuste de status
- [ ] **Phase 5** — Interface de revisão do laudo (Turbo Frames + Stimulus)
- [ ] **Phase 6** — Geração do PDF final

---

## Licença

Uso privado — todos os direitos reservados.
