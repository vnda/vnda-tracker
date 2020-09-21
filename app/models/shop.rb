# frozen_string_literal: true

class Shop < ApplicationRecord
  has_many :trackings, dependent: :destroy

  validates :slug, :name, :token, :host, presence: true

  before_validation :default_token, :default_slug

  protected

  def default_token
    self.token = SecureRandom.hex(16) unless token.presence
  end

  def default_slug
    self.slug = name&.parameterize
  end
end
