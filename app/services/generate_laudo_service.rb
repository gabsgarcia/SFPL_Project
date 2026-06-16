class GenerateLaudoService
  SYSTEM_PROMPT = <<~PROMPT
    Você é um perito judicial especializado em laudos técnicos periciais
    trabalhistas de insalubridade e periculosidade, com expertise nas
    Normas Regulamentadoras NR-6, NR-10, NR-13, NR-15, NR-16 e NR-17.

    Gere o conteúdo de seções específicas de laudos técnicos periciais seguindo:

    1. LINGUAGEM: Técnica, formal, em terceira pessoa, no padrão de laudos
       periciais trabalhistas brasileiros.

    2. CITAÇÕES LEGAIS: Sempre cite o número da NR, o item/subitem e o Anexo
       específico. Exemplo: "NR-15, Anexo 14, Portaria 3.214/78"

    3. ESTRUTURA: Siga exatamente a estrutura e numeração solicitada.

    4. QUANDO NÃO HÁ INFORMAÇÃO SUFICIENTE: Use [VERIFICAR NA DILIGÊNCIA]
       ou [INSERIR DADOS MEDIDOS] — nunca invente valores ou medições.

    5. NEUTRALIDADE: Apresente versões das partes separadamente antes da
       análise técnica.

    6. CONCLUSÃO: Sempre termine cada agente com veredicto claro:
       "INSALUBRE EM GRAU MÁXIMO/MÉDIO/MÍNIMO" ou "NÃO INSALUBRE",
       com fundamentação legal específica.

    Responda APENAS com o texto da seção, sem cabeçalhos extras, sem markdown.
  PROMPT

  def initialize(pericia)
    @pericia = pericia
  end

  def generate_all
    LaudoSection::SECOES_FIXAS.each do |secao|
      next unless secao_aplicavel?(secao[:codigo])

      generate_section(secao[:codigo])
    end

    @pericia.update!(status: "pre_laudo_em_revisao")
  end

  def generate_section(codigo)
    secao_def = LaudoSection::SECOES_FIXAS.find { |s| s[:codigo] == codigo }
    return unless secao_def

    conteudo = chamar_claude(codigo, secao_def[:titulo])

    section = @pericia.laudo_sections.find_or_initialize_by(codigo: codigo)
    section.update!(
      titulo: secao_def[:titulo],
      conteudo: conteudo,
      ordem: secao_def[:ordem],
      aplicavel: true,
      revisado: false
    )
  end

  private

  def secao_aplicavel?(codigo)
    case codigo
    when "5.3.1" then @pericia.tem_ruido?
    when "5.3.2" then @pericia.tem_calor?
    when "5.3.3" then @pericia.tem_quimico?
    when "5.3.4" then @pericia.tem_biologico?
    when "5.4"   then @pericia.tem_eletricidade? || @pericia.tem_inflamavel?
    when "5.5"   then @pericia.tem_ergonomia?
    when "6.2"   then @pericia.tem_eletricidade? || @pericia.tem_inflamavel?
    when "6.3"   then @pericia.tem_ergonomia?
    else true
    end
  end

  def contexto_base
    t = @pericia.transcricao_limpa || {}
    <<~CTX
      DADOS DO PROCESSO:
      Número: #{@pericia.numero_processo}
      Vara: #{@pericia.vara} — #{@pericia.comarca} (#{@pericia.regiao_trt})
      Reclamante: #{@pericia.reclamante}
      Função: #{@pericia.funcao_reclamante}
      Reclamada: #{@pericia.reclamada_1}#{@pericia.reclamada_2.present? ? " / #{@pericia.reclamada_2}" : ""}
      Admissão: #{@pericia.admissao&.strftime("%d/%m/%Y")} | Demissão: #{@pericia.demissao&.strftime("%d/%m/%Y") || "não informada"}
      Tipo de perícia: #{@pericia.tipo_pericia}

      DADOS DA TRANSCRIÇÃO (extraídos pela IA e revisados pelo perito):
      #{t.map { |k, v| "#{k}: #{v}" }.join("\n")}

      DOCUMENTOS DISPONÍVEIS:
      #{resumo_documentos}
    CTX
  end

  def resumo_documentos
    @pericia.pericia_documents
            .where(processado: true)
            .where.not(texto_extraido: [nil, ""])
            .map { |d| "--- #{d.label} ---\n#{d.texto_extraido&.truncate(3000)}" }
            .join("\n\n")
  end

  def chamar_claude(codigo, titulo)
    prompt_usuario = <<~PROMPT
      #{contexto_base}

      TAREFA: Gere o conteúdo completo da seção "#{codigo} — #{titulo}" do laudo pericial.
      Siga as instruções do sistema e use as informações do processo acima.
    PROMPT

    chat = RubyLLM.chat(model: "claude-sonnet-4-6")
    chat.with_instructions(SYSTEM_PROMPT)
    response = chat.ask(prompt_usuario)
    response.content
  end
end
