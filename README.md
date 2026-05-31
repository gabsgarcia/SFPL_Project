# SFPL — Plataforma de Laudos Periciais Trabalhistas

Sistema Rails para automatizar a geração de **laudos técnicos periciais de insalubridade e periculosidade** em processos trabalhistas. O perito faz upload dos documentos do caso e da transcrição da visita pericial, e um agente de IA (Claude) gera um rascunho completo do laudo para revisão seção por seção antes da exportação em PDF.

---

## Contexto do domínio

Quando um trabalhador processa uma empresa exigindo adicional de insalubridade ou periculosidade, o juiz nomeia um perito para investigar as condições reais de trabalho. O perito:

1. Agenda a visita e notifica os advogados das partes
2. Recebe documentos da empresa (PPRA/PGR, ASOs, PPP, fichas de EPI etc.)
3. Realiza a visita pericial no local de trabalho
4. Analisa tudo à luz das Normas Regulamentadoras aplicáveis
5. Entrega o laudo técnico ao juiz respondendo os quesitos das partes

Esta plataforma automatiza o processamento de documentos, a limpeza da transcrição da visita e a geração do laudo com IA.

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
| Locale | pt-BR (timezone: Brasília) |

---

## Modelos principais

```
Pericia             → processo judicial completo (pertence a um User)
├── PericiaDocument → cada arquivo enviado para o processo
├── LaudoSection    → cada seção do laudo gerado pela IA
└── QuesitoResposta → quesitos das partes e suas respostas
```

### Status do processo (`Pericia#status`)

```
rascunho → documentos_ok → agendado → vistoria_feita → processando → em_revisao → concluido
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

## Fluxo de trabalho

```
1. Perito cria a Pericia (dados do processo)
         ↓
2. Upload dos documentos recebidos da reclamada
   (PPRA, ASO, PPP, fichas EPI, FDS etc.)
         ↓
3. ProcessDocumentsJob → extrai texto de cada arquivo (PDF, DOCX, XLSX)
         ↓
4. Upload da transcrição/áudio da visita pericial
         ↓
5. CleanTranscricaoJob (Agente 1)
   → limpa a transcrição automática
   → extrai informações estruturadas em JSON
         ↓
6. Perito marca os agentes de risco presentes no caso
         ↓
7. GenerateLaudoJob (Agente 2)
   → gera cada seção do laudo sequencialmente via Claude
   → salva em LaudoSection
         ↓
8. Perito revisa seção por seção na interface web
   → edita, salva, marca como revisado
   → pode pedir regeneração de uma seção específica
         ↓
9. Exportação do laudo completo em PDF
```

---

## Normas Regulamentadoras cobertas

| NR | Escopo |
|---|---|
| NR-6 | EPIs — validade e suficiência dos equipamentos de proteção |
| NR-10 | Eletricidade |
| NR-15 | Insalubridade (Ruído, Calor, Agentes Químicos, Biológicos) |
| NR-16 | Periculosidade (Inflamáveis, Energia Elétrica, Motocicleta) |
| NR-17 | Ergonomia — AET |

**Jurisprudência relevante:** Súmula 448 TST — higienização de sanitários de uso público/coletivo de grande circulação = insalubre grau máximo (Anexo 14 NR-15).

---

## Fases de desenvolvimento

- [x] **Phase 1** — Modelos do domínio pericial + internacionalização pt-BR
- [ ] **Phase 2** — Rotas, controllers e upload de documentos
- [ ] **Phase 3** — Gems de extração de texto (pdf-reader, docx, roo) + wicked_pdf
- [ ] **Phase 4** — Serviços de IA (CleanTranscricaoService, GenerateLaudoService)
- [ ] **Phase 5** — Interface de revisão do laudo (Turbo Frames + Stimulus)
- [ ] **Phase 6** — Geração do PDF final e documentos automáticos

---

## Licença

Uso privado — todos os direitos reservados.
