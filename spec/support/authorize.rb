# frozen_string_literal: true

RSpec.shared_context 'when authorized' do
  let(:env) { {} }

  def authorize(username, password = nil)
    authorization = ActionController::HttpAuthentication::Basic
      .encode_credentials(username, password)

    if request
      request.env['HTTP_AUTHORIZATION'] = authorization
    else
      # rubocop:disable RSpec/InstanceVariable
      @env ||= {}
      @env['HTTP_AUTHORIZATION'] = authorization
      # rubocop:enable RSpec/InstanceVariable

      env['HTTP_AUTHORIZATION'] = authorization
    end
  end
end

RSpec.configure do |config|
  config.include_context 'when authorized', type: :request
  config.include_context 'when authorized', type: :controller
end
