class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def respond_with(resource, **)
    if request.post? && resource.errors.any?
      render :new, status: :unprocessable_entity
    else
      super
    end
  end
end
