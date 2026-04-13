import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

export default class extends Controller {
  static targets = ["input", "preview", "container"]

  connect() {
    this.cropper = null
  }

  disconnect() {
    this.destroyCropper()
  }

  fileSelected(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.containerTarget.classList.remove("d-none")
      this.previewTarget.src = e.target.result

      this.destroyCropper()
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
    reader.readAsDataURL(file)
  }

  crop() {
    if (!this.cropper) return

    this.cropper.getCroppedCanvas({ width: 400, height: 400 }).toBlob((blob) => {
      const file = new File([blob], "avatar.jpg", { type: "image/jpeg" })
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)
      this.inputTarget.files = dataTransfer.files

      this.containerTarget.classList.add("d-none")
      this.destroyCropper()
    }, "image/jpeg", 0.9)
  }

  cancel() {
    this.inputTarget.value = ""
    this.containerTarget.classList.add("d-none")
    this.destroyCropper()
  }

  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }
}
