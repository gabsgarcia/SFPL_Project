import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

export default class extends Controller {
  static targets = ["input", "preview", "container", "confirmButton"]

  connect() {
    this.cropper = null
    this.currentFile = null
  }

  disconnect() {
    this.destroyCropper()
  }

  fileSelected(event) {
    const file = event.target.files[0]
    if (!file) return

    this.currentFile = file
    const isGif = file.type === "image/gif"

    const reader = new FileReader()
    reader.onload = (e) => {
      this.containerTarget.classList.remove("d-none")
      this.previewTarget.src = e.target.result

      if (isGif) {
        this.destroyCropper()
        this.confirmButtonTarget.textContent = "Confirmar foto"
      } else {
        this.destroyCropper()
        this.confirmButtonTarget.textContent = "Confirmar recorte"
        this.cropper = new Cropper(this.previewTarget, {
          aspectRatio: 1,
          viewMode: 1,
          autoCropArea: 0.9,
          movable: true,
          zoomable: true,
          rotatable: false,
          scalable: false,
        })
      }
    }
    reader.readAsDataURL(file)
  }

  crop() {
    if (this.cropper) {
      this.cropper.getCroppedCanvas({ width: 400, height: 400 }).toBlob((blob) => {
        const file = new File([blob], "avatar.jpg", { type: "image/jpeg" })
        const dataTransfer = new DataTransfer()
        dataTransfer.items.add(file)
        this.inputTarget.files = dataTransfer.files
        this.containerTarget.classList.add("d-none")
        this.destroyCropper()
      }, "image/jpeg", 0.9)
    } else if (this.currentFile) {
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(this.currentFile)
      this.inputTarget.files = dataTransfer.files
      this.containerTarget.classList.add("d-none")
      this.currentFile = null
    }
  }

  cancel() {
    this.inputTarget.value = ""
    this.containerTarget.classList.add("d-none")
    this.currentFile = null
    this.destroyCropper()
  }

  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }
}
