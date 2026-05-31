class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :photo
  has_many :pericias, dependent: :destroy

  validates :first_name, :last_name, presence: true
  validates :photo,
            content_type: { in: %w[image/jpeg image/png image/webp image/gif],
                            message: "must be JPEG, PNG, WebP, or GIF" },
            size: { less_than: 10.megabytes, message: "must be less than 10MB" },
            allow_blank: true

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
