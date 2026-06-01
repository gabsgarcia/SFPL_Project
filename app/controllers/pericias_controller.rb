class PericiasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pericia, only: [:show, :edit, :update, :destroy, :review, :generate_laudo, :generate_pdf]

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
      redirect_to @pericia, notice: "Perícia criada com sucesso."
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

  def generate_laudo
    redirect_to @pericia, alert: "Geração de laudo disponível no Phase 4."
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
      :admissao, :demissao, :tipo_pericia,
      :data_pericia, :local_pericia,
      :tem_ruido, :tem_calor, :tem_quimico, :tem_biologico,
      :tem_eletricidade, :tem_inflamavel, :tem_ergonomia,
      :honorarios_salarios, :observacoes_perito
    )
  end
end
