# frozen_string_literal: true

class CorreiosHistory < ApplicationRecord
  validates :code, presence: true
end
