import { Controller } from "@hotwired/stimulus"

// Recarrega a página via Turbo a cada N ms enquanto o elemento estiver no DOM.
// Turbo é um global do turbo-rails — não precisa importar.
export default class extends Controller {
  static values = { interval: { type: Number, default: 4000 } }

  connect() {
    this.timer = setInterval(() => Turbo.visit(window.location.href), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
