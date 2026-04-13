module ApplicationHelper
  # Renders the user's avatar <img> tag with a fallback to default_avatar.png.
  # Always applies the "avatar" CSS class (which sets border-radius: 50% for the circle effect).
  # Accepts any extra HTML options (id:, data:, class:) which are merged into the image tag.
  #
  # Usage:
  #   user_avatar(current_user)
  #   user_avatar(current_user, class: "dropdown-toggle", id: "navbarDropdown")
  def user_avatar(user, options = {})
    # Merge "avatar" with any extra classes passed in, so both are always present.
    # e.g. user_avatar(current_user, class: "dropdown-toggle") → class="avatar dropdown-toggle"
    options[:class] = ["avatar", options.delete(:class)].compact.join(" ").strip

    # Use the user's uploaded photo if it exists, otherwise fall back to the default avatar.
    source = user.photo.attached? ? user.photo : "default_avatar.png"

    # Generate the final <img> tag with the resolved source and all HTML options.
    image_tag source, options
  end
end
