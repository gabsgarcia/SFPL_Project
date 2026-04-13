class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def edit
  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :photo)
  end
end
