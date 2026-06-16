class ProcessoExtractor
  # Limite de caracteres por chunk enviado ao Claude (~4k tokens)
  MAX_CHUNK_CHARS = 16_000

  # Janela de páginas ao redor de uma seção encontrada
  WINDOW_ANTES = 1
  WINDOW_DEPOIS = 4

  # ── System prompts por tipo de extração ──────────────────────────────────────

  PROMPT_CAPA = <<~PROMPT
    Você analisa capas de processos judiciais trabalhistas brasileiros gerados pelo sistema PJe.
    Extraia os dados abaixo e responda APENAS com JSON válido, sem markdown, sem texto adicional.

    Schema esperado:
    {
      "numero_processo": string ou null,
      "vara": string ou null,
      "comarca": string ou null,
      "regiao_trt": string ou null,
      "reclamante": string ou null,
      "reclamada_1": string ou null,
      "reclamada_2": string ou null
    }

    Formato típico da capa PJe (o marcador PAGINA_CAPA_PROCESSO_PJE pode aparecer no texto):
      RECLAMANTE: NOME COMPLETO DO TRABALHADOR
      ADVOGADO: NOME DO ADVOGADO DO RECLAMANTE   ← ignorar neste JSON
      RECLAMADO: NOME DA EMPRESA
      ADVOGADO: NOME DO ADVOGADO DA EMPRESA      ← ignorar neste JSON
      PERITO: NOME DO PERITO                     ← ignorar neste JSON

    Regras:
    - reclamante: nome após 'RECLAMANTE:' ou 'AUTOR:' (sempre em maiúsculas no PJe)
    - reclamada_1: nome após 'RECLAMADO:', 'RECLAMADA:', '1ª RECLAMADA:', 'RÉ:' ou '1º RECLAMADO:'
    - reclamada_2: nome após '2ª RECLAMADA:' ou '2º RECLAMADO:' — null se não houver
    - numero_processo: padrão NNNNNNN-NN.NNNN.N.NN.NNNN (pode ter sufixo como '-1')
    - vara: buscar por 'Vara do Trabalho', 'VT', número ordinal + 'Vara'
    - comarca: cidade onde fica a vara (ex: 'Franco da Rocha', 'São Paulo')
    - regiao_trt: buscar por 'TRT', 'Tribunal Regional do Trabalho', número da região

    Se um campo não estiver presente no texto, use null.
  PROMPT

  PROMPT_DECISAO = <<~PROMPT
    Você analisa decisões e despachos de processos judiciais trabalhistas brasileiros.
    Extraia os dados abaixo do texto e responda APENAS com JSON válido, sem markdown.

    Schema esperado:
    {
      "tipo_pericia": "insalubridade" | "periculosidade" | "ambos" | null,
      "prazo_laudo": "YYYY-MM-DD" ou null,
      "email_adv_reclamante": string ou null,
      "email_adv_reclamada_1": string ou null,
      "email_adv_reclamada_2": string ou null,
      "assist_tec_reclamante": string ou null,
      "assist_tec_reclamada_1": string ou null,
      "assist_tec_reclamada_2": string ou null
    }

    Regras:
    - tipo_pericia: buscar 'insalubridade', 'periculosidade' ou ambos no despacho de nomeação do perito.
      Se o juiz determinar ambas as apurações, use 'ambos'.
    - prazo_laudo: buscar 'prazo de X dias', 'até o dia', 'entregar até', 'prazo para apresentação'.
      Converta para YYYY-MM-DD. Se for 'X dias corridos', some ao prazo citado.
    - e-mails: no PJe aparecem no despacho de nomeação do perito em formatos como:
        'e-mail: nome@exemplo.com.br'
        'endereço eletrônico: nome@exemplo.com.br'
        'ao endereço eletrônico nome@exemplo.com.br'
      Associe o e-mail ao advogado da parte correspondente mencionada antes dele.
    - assistentes técnicos: nomes após 'assistente técnico', 'indicando como assistente',
      'AT do reclamante', 'AT da reclamada'.
    - Se reclamada_2 não existir, use null em todos os campos _2.

    Se um campo não estiver presente, use null.
  PROMPT

  PROMPT_INICIAL = <<~PROMPT
    Você analisa petições iniciais de processos judiciais trabalhistas brasileiros.
    Extraia os dados abaixo do texto e responda APENAS com JSON válido, sem markdown.

    Schema esperado:
    {
      "funcao_reclamante": string ou null,
      "admissao": "YYYY-MM-DD" ou null,
      "demissao": "YYYY-MM-DD" ou null,
      "resumo_inicial": string ou null
    }

    Dicas:
    - funcao_reclamante: cargo/função exercida pelo trabalhador (ex: "auxiliar de limpeza")
    - admissao/demissao: datas de contratação e dispensa — converta para YYYY-MM-DD
    - resumo_inicial: parágrafo resumindo o que o reclamante alega (2-4 frases)
      Foque no que ele pede (insalubridade, periculosidade) e qual era sua função/ambiente

    Se um campo não estiver presente, use null.
  PROMPT

  PROMPT_CONTESTACAO = <<~PROMPT
    Você analisa contestações de processos judiciais trabalhistas brasileiros.
    Extraia os dados abaixo do texto e responda APENAS com JSON válido, sem markdown.

    Schema esperado:
    {
      "resumo_contestacao": string ou null
    }

    Dicas:
    - resumo_contestacao: parágrafo resumindo os principais argumentos da reclamada (2-4 frases)
      Foque nos argumentos de defesa: EPIs fornecidos, atividade não insalubre, laudos próprios etc.

    Se não encontrar contestação, use null.
  PROMPT

  PROMPT_QUESITOS = <<~PROMPT
    Você analisa quesitos de processos judiciais trabalhistas brasileiros.
    Extraia TODOS os quesitos do texto e responda APENAS com JSON válido, sem markdown.

    Schema esperado:
    {
      "quesitos": [
        {
          "origem": "reclamante" | "reclamada_1" | "reclamada_2" | "juizo",
          "numero": integer,
          "texto": string
        }
      ]
    }

    Dicas:
    - Quesitos são perguntas numeradas que cada parte faz ao perito
    - Aparecem em seções como "Quesitos do Reclamante:", "Quesitos da Reclamada:"
    - Preserve o texto completo de cada quesito
    - Se houver 2ª reclamada com quesitos próprios, use "reclamada_2"
    - Quesitos do juízo (do próprio juiz) têm origem "juizo"

    Se não houver quesitos, retorne {"quesitos": []}.
  PROMPT

  # ── Palavras-chave por seção ──────────────────────────────────────────────────

  KEYWORDS_DECISAO = %w[
    nomeando-se\ perito
    nomeio\ o\ perito
    perito\ nomeado
    designo\ o\ perito
    e-mail
    prazo\ para\ apresentação
    insalubridade
    periculosidade
    assistente\ técnico
  ].freeze

  KEYWORDS_INICIAL = %w[
    petição\ inicial
    da\ inicial
    dos\ fatos
    da\ admissão
    foi\ admitido
    foi\ admitida
    função\ de
    cargo\ de
  ].freeze

  KEYWORDS_CONTESTACAO = %w[
    contestação
    da\ contestação
    em\ contestação
    preliminarmente
    no\ mérito
  ].freeze

  KEYWORDS_QUESITOS = %w[
    quesitos\ do\ reclamante
    quesitos\ da\ reclamada
    quesitos\ do\ reclamado
    quesitos\ do\ juízo
    quesitos\ da\ reclamante
    quesito
  ].freeze

  # ── Interface pública ─────────────────────────────────────────────────────────

  def initialize(pericia)
    @pericia = pericia
    @page_texts = {}
  end

  def extract
    load_pdf
    return {} if @page_texts.empty?

    dados = {}
    dados.merge!(extrair_dados_capa)
    dados.merge!(extrair_dados_decisao)
    dados.merge!(extrair_resumo_inicial)
    dados.merge!(extrair_resumo_contestacao)
    dados[:quesitos] = extrair_quesitos
    dados
  end

  private

  def load_pdf
    @pericia.arquivo_processo.open do |tempfile|
      reader = PDF::Reader.new(tempfile.path)
      reader.pages.each_with_index do |page, i|
        text = page.text.to_s.strip
        @page_texts[i + 1] = text unless text.empty?
      end
    end
  rescue => e
    Rails.logger.error("[ProcessoExtractor] Erro ao ler PDF: #{e.message}")
  end

  # Retorna os números das páginas que contêm alguma das palavras-chave
  def paginas_com_keywords(keywords)
    @page_texts.select do |_num, text|
      keywords.any? { |kw| text.match?(Regexp.new(Regexp.escape(kw), Regexp::IGNORECASE)) }
    end.keys
  end

  # Monta um chunk de texto a partir de uma página âncora + janela ao redor
  def chunk_ao_redor(pagina_ancora)
    inicio = [pagina_ancora - WINDOW_ANTES, 1].max
    fim    = pagina_ancora + WINDOW_DEPOIS
    @page_texts.slice(*inicio..fim).values.join("\n\n")
  end

  # Monta chunk a partir de páginas específicas com janela
  def chunk_de_paginas(numeros)
    return "" if numeros.empty?

    pages = numeros.flat_map do |n|
      ([(n - WINDOW_ANTES), 1].max..(n + WINDOW_DEPOIS)).to_a
    end.uniq.sort

    @page_texts.slice(*pages).values.join("\n\n")
  end

  def truncar(texto)
    return texto if texto.length <= MAX_CHUNK_CHARS

    texto[0...MAX_CHUNK_CHARS] + "\n\n[... trecho truncado por tamanho ...]"
  end

  def chamar_claude(system_prompt, conteudo)
    Rails.logger.info("[ProcessoExtractor] Enviando chunk de #{conteudo.length} chars ao Claude")
    chat = RubyLLM.chat(model: "claude-sonnet-4-6")
    chat.with_instructions(system_prompt)
    response = chat.ask(conteudo)
    Rails.logger.info("[ProcessoExtractor] Resposta recebida: #{response.content&.first(300)}")
    JSON.parse(limpar_json(response.content))
  rescue JSON::ParserError => e
    Rails.logger.error("[ProcessoExtractor] JSON invalido: #{e.message}")
    Rails.logger.error("[ProcessoExtractor] Resposta bruta: #{response&.content&.first(500)}")
    {}
  rescue => e
    Rails.logger.error("[ProcessoExtractor] Erro na chamada ao Claude: #{e.message}")
    {}
  end

  def limpar_json(texto)
    texto.to_s.strip
         .gsub(/\A```(?:json)?\s*/m, "")
         .gsub(/\s*```\z/m, "")
         .strip
  end

  # ── Extratores por seção ──────────────────────────────────────────────────────

  def extrair_dados_capa
    # As primeiras páginas sempre têm os dados das partes
    chunk = @page_texts.slice(*1..5).values.join("\n\n")
    chamar_claude(PROMPT_CAPA, truncar(chunk))
  end

  def extrair_dados_decisao
    paginas = paginas_com_keywords(KEYWORDS_DECISAO)
    return {} if paginas.empty?

    chunk = chunk_de_paginas(paginas.first(3))
    resultado = chamar_claude(PROMPT_DECISAO, truncar(chunk))

    # Normaliza datas
    %w[prazo_laudo].each do |campo|
      resultado[campo] = parse_date(resultado[campo])
    end

    resultado
  end

  def extrair_resumo_inicial
    paginas = paginas_com_keywords(KEYWORDS_INICIAL)

    # Se não encontrou por keywords, usa as páginas 4-10 (geralmente onde fica)
    paginas = (4..10).to_a if paginas.empty?

    chunk = chunk_de_paginas(paginas.first(3))
    resultado = chamar_claude(PROMPT_INICIAL, truncar(chunk))

    %w[admissao demissao].each do |campo|
      resultado[campo] = parse_date(resultado[campo])
    end

    resultado
  end

  def extrair_resumo_contestacao
    paginas = paginas_com_keywords(KEYWORDS_CONTESTACAO)
    return {} if paginas.empty?

    chunk = chunk_de_paginas(paginas.first(2))
    chamar_claude(PROMPT_CONTESTACAO, truncar(chunk))
  end

  def extrair_quesitos
    paginas = paginas_com_keywords(KEYWORDS_QUESITOS)
    return [] if paginas.empty?

    # Quesitos podem estar em várias páginas — inclui todas as encontradas
    chunk = chunk_de_paginas(paginas)
    resultado = chamar_claude(PROMPT_QUESITOS, truncar(chunk))
    resultado["quesitos"] || []
  rescue => e
    Rails.logger.error("[ProcessoExtractor] Erro ao extrair quesitos: #{e.message}")
    []
  end

  def parse_date(valor)
    return nil if valor.blank?

    Date.parse(valor)
  rescue ArgumentError, TypeError
    nil
  end
end
