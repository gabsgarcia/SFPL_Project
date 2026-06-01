class QuesitoRespostasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pericia
  before_action :set_quesito

  def update
    if @quesito.update(quesito_params)
      render json: { ok: true }
    else
      render json: { ok: false, errors: @quesito.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_pericia
    @pericia = current_user.pericias.find(params[:pericia_id])
  end

  def set_quesito
    @quesito = @pericia.quesito_respostas.find(params[:id])
  end

  def quesito_params
    params.require(:quesito_resposta).permit(:resposta, :revisado)
  end
end
