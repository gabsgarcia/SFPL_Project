class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :photo

  validates :first_name, :last_name, presence: true
  validates :photo,
    content_type: { in: %w[image/jpeg image/png image/webp], message: "must be JPEG, PNG, or WebP" },
    size: { less_than: 5.megabytes, message: "must be less than 5MB" },
    allow_blank: true

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
