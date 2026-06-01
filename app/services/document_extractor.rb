class DocumentExtractor
  def initialize(pericia_document)
    @document = pericia_document
  end

  def extract
    return if @document.processado?

    texto = case @document.file.content_type
            when "application/pdf"
              extract_pdf
            when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
              extract_docx
            when /spreadsheet/, "application/vnd.ms-excel",
                 "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
              extract_xlsx
            else
              nil
            end

    @document.update!(texto_extraido: texto, processado: true)
  rescue => e
    @document.update!(
      texto_extraido: "[Erro ao extrair texto: #{e.message}]",
      processado: true
    )
  end

  private

  def extract_pdf
    @document.file.open do |tempfile|
      reader = PDF::Reader.new(tempfile.path)
      reader.pages.map(&:text).join("\n\n").strip
    end
  end

  def extract_docx
    @document.file.open do |tempfile|
      doc = Docx::Document.open(tempfile.path)
      doc.paragraphs.map(&:text).reject(&:empty?).join("\n").strip
    end
  end

  def extract_xlsx
    @document.file.open do |tempfile|
      workbook = Roo::Spreadsheet.open(tempfile.path)
      workbook.sheets.map do |sheet_name|
        sheet = workbook.sheet(sheet_name)
        (1..sheet.last_row).map do |i|
          (1..sheet.last_column).map { |j| sheet.cell(i, j).to_s }.join("\t")
        end.reject(&:blank?).join("\n")
      end.join("\n\n").strip
    end
  end
end
