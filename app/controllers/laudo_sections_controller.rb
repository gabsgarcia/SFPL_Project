class LaudoSectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pericia
  before_action :set_section

  def update
    if @section.update(section_params)
      render json: { ok: true }
    else
      render json: { ok: false, errors: @section.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_pericia
    @pericia = current_user.pericias.find(params[:pericia_id])
  end

  def set_section
    @section = @pericia.laudo_sections.find(params[:id])
  end

  def section_params
    params.require(:laudo_section).permit(:conteudo, :revisado, :aplicavel)
  end
end
