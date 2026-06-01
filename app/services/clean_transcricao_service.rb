class CleanTranscricaoService
  PROMPT_SISTEMA = <<~PROMPT
    Você é um assistente especializado em perícias trabalhistas brasileiras.
    Receberá a transcrição bruta de uma visita pericial (gerada por ferramenta
    automática como Whisper ou Transkriptor) e deverá:

    1. Identificar os falantes:
       - SPK_1 (ou similar) = a perita/perito
       - SPK_4 (ou similar) = o reclamante
       - Outros = advogados e assistentes técnicos

    2. Corrigir erros comuns de reconhecimento automático:
       - "IPI" → "EPI"
       - Nomes de produtos distorcidos
       - Palavras cortadas ou concatenadas incorretamente

    3. Extrair as informações estruturadas em JSON com exatamente estas chaves:
       {
         "rotina_trabalho": string — descrição narrativa da rotina diária,
         "produtos_utilizados": array de strings — produtos químicos mencionados,
         "epis_recebidos": array de strings — EPIs que o reclamante diz ter recebido,
         "epis_utilizados": boolean — reclamante diz que usava os EPIs,
         "assinou_ficha_epi": boolean — reclamante diz que assinou a ficha,
         "frequencia_atividade_principal": string — ex: "diária, 1-2 vezes por turno",
         "tempo_por_tarefa": string — ex: "1h30min por banheiro",
         "areas_trabalhadas": array de strings — locais onde trabalhava,
         "tamanho_equipe": integer ou null,
         "sistema_rodizio": boolean — havia rodízio entre funcionários,
         "coleta_lixo": boolean — realizava coleta de lixo,
         "tipo_lixo": string ou null — descrição do lixo coletado,
         "local_trabalho_descricao": string — descrição do local de trabalho,
         "observacoes_adicionais": string — qualquer informação relevante não coberta acima
       }

    Responda APENAS com o JSON válido, sem texto adicional, sem markdown.
  PROMPT

  def initialize(pericia)
    @pericia = pericia
  end

  def process
    documento = @pericia.transcricao_documento
    return unless documento&.texto_extraido.present?

    resposta = RubyLLM.chat do |chat|
      chat.with_model("claude-opus-4-5-20251101")
      chat.with_system(PROMPT_SISTEMA)
      chat.ask(documento.texto_extraido)
    end

    json = JSON.parse(resposta.content)
    @pericia.update!(transcricao_limpa: json)
    json
  rescue JSON::ParserError => e
    raise "Resposta da IA não é um JSON válido: #{e.message}"
  end
end
