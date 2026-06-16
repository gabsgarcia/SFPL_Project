class PericiasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pericia, only: [:show, :edit, :update, :destroy, :review,
                                     :review_docs_base, :extract_processo,
                                     :review_transcricao, :update_transcricao,
                                     :generate_laudo, :generate_pdf, :confirmar_fase1]

  def index
    @pericias = current_user.pericias.order(created_at: :desc)
  end

  def show
  end

  def new
    @pericia = Pericia.new
  end

  def create
    @pericia = current_user.pericias.build(pericia_params)
    if @pericia.save
      ExtractProcessoJob.perform_later(@pericia.id)
      redirect_to @pericia, notice: "Processo enviado. Extraindo dados automaticamente — aguarde alguns instantes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @pericia.update(pericia_params)
      redirect_to @pericia, notice: "Perícia atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pericia.destroy
    redirect_to pericias_path, notice: "Perícia removida."
  end

  def review
  end

  def review_docs_base
    @documento_bases = @pericia.documento_bases.ordenados
  end

  def extract_processo
    if @pericia.arquivo_processo.attached?
      ExtractProcessoJob.perform_later(@pericia.id)
      redirect_to @pericia, notice: "Extração iniciada. Os documentos serão preenchidos em instantes."
    else
      redirect_to @pericia, alert: "Faça o upload do PDF do processo antes de extrair."
    end
  end

  def review_transcricao
  end

  def update_transcricao
    dados = params.require(:transcricao).permit(
      :rotina_trabalho, :frequencia_atividade_principal, :tempo_por_tarefa,
      :tamanho_equipe, :tipo_lixo, :local_trabalho_descricao, :observacoes_adicionais,
      :epis_utilizados, :assinou_ficha_epi, :sistema_rodizio, :coleta_lixo,
      produtos_utilizados: [], epis_recebidos: [], areas_trabalhadas: []
    ).to_h

    dados["epis_utilizados"]   = dados["epis_utilizados"] == "1"
    dados["assinou_ficha_epi"] = dados["assinou_ficha_epi"] == "1"
    dados["sistema_rodizio"]   = dados["sistema_rodizio"] == "1"
    dados["coleta_lixo"]       = dados["coleta_lixo"] == "1"
    dados["tamanho_equipe"]    = dados["tamanho_equipe"].presence&.to_i

    @pericia.update!(transcricao_limpa: dados, transcricao_revisada: true)
    redirect_to @pericia, notice: "Transcrição revisada. Você já pode gerar o laudo."
  end

  def generate_laudo
    unless @pericia.pronta_para_gerar_laudo?
      return redirect_to @pericia, alert: "Revise a transcrição antes de gerar o laudo."
    end

    @pericia.update!(status: "processando_pos_visita")
    GenerateLaudoJob.perform_later(@pericia.id)
    redirect_to @pericia, notice: "Geração do laudo iniciada. Isso pode levar alguns minutos."
  end

  def confirmar_fase1
    docs = @pericia.documento_bases
    unless docs.count == 4 && docs.all?(&:revisado?)
      return redirect_to review_docs_base_pericia_path(@pericia),
                         alert: "Revise todos os 4 documentos antes de confirmar."
    end

    @pericia.update!(status: "aguardando_visita")
    redirect_to @pericia, notice: "Fase 1 concluída. Documentos enviados — aguardando a visita pericial."
  end

  def generate_pdf
    redirect_to @pericia, alert: "Geração de PDF disponível no Phase 6."
  end

  private

  def set_pericia
    @pericia = current_user.pericias.find(params[:id])
  end

  def pericia_params
    params.require(:pericia).permit(
      :numero_processo, :vara, :comarca, :regiao_trt,
      :reclamante, :reclamada_1, :reclamada_2, :funcao_reclamante,
      :admissao, :demissao, :tipo_pericia, :prazo_laudo,
      :data_pericia, :local_pericia,
      :email_adv_reclamante, :email_adv_reclamada_1, :email_adv_reclamada_2,
      :assist_tec_reclamante, :assist_tec_reclamada_1, :assist_tec_reclamada_2,
      :resumo_inicial, :resumo_contestacao,
      :tem_ruido, :tem_calor, :tem_quimico, :tem_biologico,
      :tem_eletricidade, :tem_inflamavel, :tem_ergonomia,
      :honorarios_salarios, :observacoes_perito,
      :arquivo_processo
    )
  end
end
