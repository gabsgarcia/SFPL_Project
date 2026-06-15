class ExtractProcessoJob < ApplicationJob
  queue_as :default

  CAMPOS_PERICIA = %w[
    numero_processo vara comarca regiao_trt
    reclamante reclamada_1 reclamada_2
    funcao_reclamante admissao demissao
    tipo_pericia prazo_laudo
    email_adv_reclamante email_adv_reclamada_1 email_adv_reclamada_2
    assist_tec_reclamante assist_tec_reclamada_1 assist_tec_reclamada_2
    resumo_inicial resumo_contestacao
  ].freeze

  def perform(pericia_id)
    @pericia = Pericia.find(pericia_id)
    @pericia.update!(status: "extraindo_dados")

    dados = ProcessoExtractor.new(@pericia).extract
    quesitos = dados.delete(:quesitos) || []

    atualizar_pericia(dados)
    criar_quesitos(quesitos)
    criar_documento_bases

    @pericia.update!(status: "docs_base_prontos")
  rescue => e
    Rails.logger.error("[ExtractProcessoJob] pericia_id=#{pericia_id} erro=#{e.message}")
    @pericia&.update_column(:status, "erro")
    raise e
  end

  private

  def atualizar_pericia(dados)
    # compact: não sobrescreve campos existentes com nil se a IA não encontrou
    campos = dados.slice(*CAMPOS_PERICIA).compact
    @pericia.update!(campos) if campos.any?
  end

  def criar_quesitos(quesitos)
    quesitos.each do |q|
      origem = q["origem"]
      numero = q["numero"].to_i
      texto  = q["texto"].to_s.strip
      next if origem.blank? || numero.zero? || texto.blank?
      next unless QuesitoResposta::ORIGENS.include?(origem)

      @pericia.quesito_respostas
              .find_or_initialize_by(origem: origem, numero: numero)
              .update!(texto_quesito: texto, revisado: false)
    end
  end

  def criar_documento_bases
    DocumentoBase::TIPOS.each do |tipo|
      doc = @pericia.documento_bases.find_or_initialize_by(tipo: tipo)
      doc.conteudo  = conteudo_para(tipo)
      doc.revisado  = false
      doc.revisado_em = nil
      doc.save!
    end
  end

  # ── Templates dos documentos base ────────────────────────────────────────────

  def conteudo_para(tipo)
    case tipo
    when "arq1_peticao"   then template_arq1
    when "arq2_email"     then template_arq2
    when "arq3_termo"     then template_arq3
    when "arq4_analise"   then template_arq4
    end
  end

  def reclamadas_lista
    linhas = ["1ª Reclamada: #{@pericia.reclamada_1}"]
    linhas << "2ª Reclamada: #{@pericia.reclamada_2}" if @pericia.reclamada_2.present?
    linhas.join("\n")
  end

  def emails_advogados
    linhas = ["Reclamante: #{@pericia.email_adv_reclamante.presence || "[e-mail não encontrado]"}"]
    linhas << "1ª Reclamada: #{@pericia.email_adv_reclamada_1.presence || "[e-mail não encontrado]"}"
    linhas << "2ª Reclamada: #{@pericia.email_adv_reclamada_2}" if @pericia.email_adv_reclamada_2.present?
    linhas.join("\n")
  end

  def tipo_pericia_extenso
    case @pericia.tipo_pericia
    when "insalubridade"  then "insalubridade"
    when "periculosidade" then "periculosidade"
    when "ambos"          then "insalubridade e periculosidade"
    else "[tipo de perícia]"
    end
  end

  def template_arq1
    <<~DOC
      Excelentíssimo(a) Juiz(a) do Trabalho da #{@pericia.vara} de #{@pericia.comarca} - SP

      Processo nº #{@pericia.numero_processo}
      Reclamante: #{@pericia.reclamante}
      #{reclamadas_lista}

      [NOME DA PERITA], nomeada perito no processo supramencionado, vem à presença
      de V. Exa. informar que a perícia técnica para apuração de #{tipo_pericia_extenso}
      foi marcada para o dia [DATA DA PERÍCIA], às [HORA], tendo sido encaminhado
      e-mail aos advogados das partes:

      #{emails_advogados}

      Nestes termos,
      Pede deferimento.

      [LOCAL], [DATA]
      [NOME DA PERITA]
      [TÍTULO / CRQ / CREA]
    DOC
  end

  def template_arq2
    docs_solicitados = <<~DOCS
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
    DOCS

    <<~DOC
      Prezados Advogados,

      Informo que a perícia técnica para apuração de #{tipo_pericia_extenso} no
      processo nº #{@pericia.numero_processo} (#{@pericia.reclamante} x #{@pericia.reclamada_1}) foi
      marcada para o dia [DATA DA PERÍCIA], às [HORA], a ser realizada em
      [LOCAL DA PERÍCIA].

      #{docs_solicitados}
      Solicito que os documentos sejam disponibilizados até o dia da perícia.
      Em caso de dúvidas, entrar em contato pelo e-mail [E-MAIL DA PERITA].

      Atenciosamente,
      [NOME DA PERITA]
      Perita Judicial
    DOC
  end

  def template_arq3
    admissao  = @pericia.admissao&.strftime("%d/%m/%Y")  || "[data de admissão]"
    demissao  = @pericia.demissao&.strftime("%d/%m/%Y")  || "[data de demissão]"

    <<~DOC
      TERMO DE COMPARECIMENTO

      #{@pericia.vara} / SP – #{@pericia.regiao_trt}

      Processo nº #{@pericia.numero_processo}
      Reclamante: #{@pericia.reclamante}
      #{reclamadas_lista}

      Objetivo: Perícia de #{tipo_pericia_extenso}
      Data e hora da Perícia: [DATA] às [HORA]
      Endereço: [LOCAL DA PERÍCIA]
      Admissão: #{admissao}  |  Demissão: #{demissao}
      Função: #{@pericia.funcao_reclamante.presence || "[função]"}

      ─────────────────────────────────────────────────────────────────
      ACOMPANHANTES
      ─────────────────────────────────────────────────────────────────
      [Preencher durante a visita]

      ─────────────────────────────────────────────────────────────────
      VERSÃO DO RECLAMANTE
      ─────────────────────────────────────────────────────────────────
      [Preencher durante a visita]

      ─────────────────────────────────────────────────────────────────
      VERSÃO DA RECLAMADA
      ─────────────────────────────────────────────────────────────────
      [Preencher durante a visita]

      ─────────────────────────────────────────────────────────────────
      Assinaturas:

      Perita: ________________________    Data: ___/___/______

      Reclamante: ____________________    Reclamada: ____________________
    DOC
  end

  def template_arq4
    admissao = @pericia.admissao&.strftime("%d/%m/%Y")  || "[data de admissão]"
    demissao = @pericia.demissao&.strftime("%d/%m/%Y")  || "[data de demissão]"

    secoes_quesitos = QuesitoResposta::ORIGENS.filter_map do |origem|
      quesitos = @pericia.quesito_respostas.where(origem: origem).order(:numero)
      next if quesitos.empty?

      titulo = case origem
               when "reclamante"  then "QUESITOS DO RECLAMANTE"
               when "reclamada_1" then "QUESITOS DA 1ª RECLAMADA"
               when "reclamada_2" then "QUESITOS DA 2ª RECLAMADA"
               when "juizo"       then "QUESITOS DO JUÍZO"
               end

      linhas = quesitos.map { |q| "#{q.numero}. #{q.texto_quesito}" }
      "#{titulo}:\n#{linhas.join("\n")}"
    end.join("\n\n")

    <<~DOC
      ANÁLISE DO PERITO
      Avaliação do Perito referente às informações da Reclamada e Reclamante

      #{@pericia.vara} / SP – #{@pericia.regiao_trt}
      Processo nº #{@pericia.numero_processo}
      Reclamante: #{@pericia.reclamante}
      #{reclamadas_lista}
      Admissão: #{admissao}  |  Demissão: #{demissao}
      Função: #{@pericia.funcao_reclamante.presence || "[função]"}

      ─────────────────────────────────────────────────────────────────
      #{secoes_quesitos.presence || "[Quesitos não encontrados no processo — inserir manualmente]"}

      ─────────────────────────────────────────────────────────────────
      DA INICIAL:
      #{@pericia.resumo_inicial.presence || "[Resumo da inicial não extraído — inserir manualmente]"}

      ─────────────────────────────────────────────────────────────────
      DA CONTESTAÇÃO:
      #{@pericia.resumo_contestacao.presence || "[Resumo da contestação não extraído — inserir manualmente]"}
    DOC
  end
end
