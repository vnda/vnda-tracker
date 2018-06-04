# frozen_string_literal: true

json.array! @trackings, partial: 'trackings/tracking', as: :tracking
