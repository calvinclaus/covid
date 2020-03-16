class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable
  devise :pwned_password unless Rails.env.test? || Rails.env.development?

  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}
  belongs_to :company
  has_many :campaigns, through: :company
  validates_associated :company
  accepts_nested_attributes_for :company

  after_commit :maybe_reset_creating_password

  def maybe_reset_creating_password
    changes = saved_change_to_encrypted_password
    return unless changes.present?

    self.creating_password = false
    save!
  end

  def first_name
    name.split(" ").first # TODO TITLES
  end
end
