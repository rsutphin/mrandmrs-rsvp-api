require 'timeout'
require 'time'

require 'uri'
require 'faraday'
require 'faraday_middleware'

class GoogleDeviceOAuth
  STATIC_CONFIG_FILE = Rails.root + 'config/google_oauth.yml'

  SCOPES = ['https://spreadsheets.google.com/feeds', 'https://docs.google.com/feeds']
  SETUP_POLL_TIMEOUT = 180 # sec

  ##
  # Performs the initial device profile setup. Provides instructions at the console.
  # Stores refresh_token in static config file.
  def initial_setup!
    device_result = perform_device_request

    verification_url  = device_result['verification_url']
    user_code         = device_result['user_code']
    device_code       = device_result['device_code']
    interval          = device_result['interval']
    expires_in        = device_result['expires_in']

    puts "Go to #{verification_url}, enter #{user_code.inspect}, and authorize the app."
    puts "I'll wait here."

    poll_result = perform_setup_poll(device_code, interval)
    # If polling times out, there will have already been an exception.
    # Therefore `poll_result` must not be nil at this point.

    update_static_refresh_token(poll_result['refresh_token'])
  end

  ##
  # @return [Token] Requests and returns a new access token.
  def token
    Token.from_json(retrieve_token_json)
  end

  def retrieve_token_json
    Rails.logger.info "Requesting access token using #{refresh_token}"
    response = accounts_connection.post('/o/oauth2/token', {
      'client_id' => client_id,
      'client_secret' => client_secret,
      'refresh_token' => refresh_token,
      'grant_type' => 'refresh_token'
    })
    if response.body['error'] || response.status / 100 != 2
      Rails.logger.error "Token request failed. Status=#{response.status}; entity=#{response.body.inspect}."
      fail "Token refresh failed. See log for detail."
    else
      Rails.logger.debug "Access token result: #{response.body.inspect}"
      response.body
    end
  end
  private :retrieve_token_json

  def accounts_connection
    @accounts_connection ||= Faraday::Connection.new(:url => 'https://accounts.google.com/') do |f|
      f.request  :url_encoded
      f.response :logger, Rails.logger
      f.response :json, :content_type => /\bjson\z/

      f.adapter Faraday.default_adapter
    end
  end
  private :accounts_connection

  def perform_device_request
    response = accounts_connection.post('/o/oauth2/device/code', {
      'client_id' => client_id,
      'scope' => SCOPES.join(' ')
    })

    fail "Device code request failed." unless response.status == 200

    response.body
  end
  private :perform_device_request

  def perform_setup_poll(device_code, interval)
    successful_result = nil

    Timeout.timeout(SETUP_POLL_TIMEOUT) do
      until successful_result
        sleep interval
        response = accounts_connection.post('/o/oauth2/token', {
          'client_id' => client_id,
          'client_secret' => client_secret,
          'code' => device_code,
          'grant_type' => 'http://oauth.net/grant_type/device/1.0'
        })
        if response.body['error']
          Rails.logger.info "Polling will continue: #{response.body['error']}"
        else
          successful_result = response.body
        end
      end
    end

    successful_result
  end
  private :perform_setup_poll

  def update_static_refresh_token(new_token)
    static_config['refresh_token'] = new_token
    File.open(STATIC_CONFIG_FILE, 'w') do |f|
      f.write static_config.to_yaml
    end
  end

  def static_config
    @static_config ||= YAML.load(File.read(STATIC_CONFIG_FILE))
  end
  private :static_config

  def client_secret
    static_config['client_secret']
  end

  def client_id
    static_config['client_id']
  end

  def refresh_token
    static_config['refresh_token']
  end

  class Token < Struct.new(:access_token, :token_type, :expires_in, :created_at)
    def self.from_json(json)
      new.tap do |t|
        t.access_token = json['access_token']
        t.token_type = json['token_type']
        t.expires_in = json['expires_in'].to_i
        t.created_at = Time.now.utc
      end
    end

    def expiration
      created_at + expires_in
    end

    def probably_expired?
      Time.now > expiration
    end

    def authorization_header
      [token_type, access_token].join(' ')
    end
  end
end
