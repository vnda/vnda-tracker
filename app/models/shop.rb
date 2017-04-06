class Shop < ApplicationRecord
  has_many :trackings, dependent: :destroy
end
