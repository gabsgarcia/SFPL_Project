import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      const original = this.element.textContent
      this.element.textContent = "Copiado!"
      this.element.classList.add("btn-success")
      this.element.classList.remove("btn-outline-secondary")
      setTimeout(() => {
        this.element.textContent = original
        this.element.classList.remove("btn-success")
        this.element.classList.add("btn-outline-secondary")
      }, 2000)
    })
  }
}
