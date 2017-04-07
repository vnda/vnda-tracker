class Shop < ApplicationRecord
  has_many :trackings, dependent: :destroy

  before_validation :default_token

  protected

  def default_token
    self.token = SecureRandom.hex(16) unless self.token.presence
  end
end
