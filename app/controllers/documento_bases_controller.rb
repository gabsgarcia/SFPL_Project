class DocumentoBasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pericia
  before_action :set_documento_base

  def show
  end

  def edit
  end

  def update
    if @documento_base.update(documento_base_params)
      @documento_base.marcar_revisado!
      redirect_to review_docs_base_pericia_path(@pericia),
                  notice: "#{@documento_base.label} salvo e marcado como revisado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def marcar_revisado
    @documento_base.marcar_revisado!
    redirect_to review_docs_base_pericia_path(@pericia),
                notice: "#{@documento_base.label} marcado como revisado."
  end

  private

  def set_pericia
    @pericia = current_user.pericias.find(params[:pericia_id])
  end

  def set_documento_base
    @documento_base = @pericia.documento_bases.find(params[:id])
  end

  def documento_base_params
    params.require(:documento_base).permit(:conteudo)
  end
end
