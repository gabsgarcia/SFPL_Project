class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def after_sign_up_path_for(_resource)
    pericias_path
  end

  def after_sign_in_path_for(_resource)
    pericias_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name photo])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name photo])
  end
end
