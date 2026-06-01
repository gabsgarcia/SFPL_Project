class PericiaDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pericia

  def create
    @document = @pericia.pericia_documents.build(document_params)
    @document.nome_original = document_params[:file]&.original_filename

    if @document.save
      ProcessDocumentsJob.perform_later(@document.id)
      redirect_to @pericia, notice: "Documento enviado. O texto será extraído em breve."
    else
      redirect_to @pericia, alert: "Erro ao enviar documento: #{@document.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    @document = @pericia.pericia_documents.find(params[:id])
    @document.destroy
    redirect_to @pericia, notice: "Documento removido."
  end

  private

  def set_pericia
    @pericia = current_user.pericias.find(params[:pericia_id])
  end

  def document_params
    params.require(:pericia_document).permit(:file, :document_type)
  end
end
