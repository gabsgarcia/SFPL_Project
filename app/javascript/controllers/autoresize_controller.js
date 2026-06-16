import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]

  connect() {
    this.textareaTargets.forEach(el => this.resize(el))
  }

  resize(el) {
    el.style.height = "auto"
    el.style.height = `${el.scrollHeight}px`
  }

  input(event) {
    this.resize(event.target)
  }
}
