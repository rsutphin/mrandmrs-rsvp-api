require 'sqlite3'
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
  # Performs the initial device profile setup. Creates the SQLite database that
  # holds the tokens. Provides instructions at the console.
  def initial_setup
    setup_token_database

    device_result = perform_device_request

    verification_url  = device_result['verification_url']
    user_code         = device_result['user_code']
    device_code       = device_result['device_code']
    interval          = device_result['interval']
    expires_in        = device_result['expires_in']

    puts "Go to #{verification_url}, enter #{user_code.inspect}, and authorize the app."
    puts "I'll wait here."

    poll_result = perform_setup_poll(device_code, interval)
    # if polling times out, there will have already been an exception, so poll_result must not be nil at this point.

    store_token_record(poll_result)

    puts "Stored token."
  end

  def token_database
    @token_database ||= SQLite3::Database.new((Rails.root + 'db/google_oauth_token.sqlite3').to_s)
  end
  private :token_database

  def setup_token_database
    token_database.execute 'DROP TABLE IF EXISTS token'
    token_database.execute <<-SQL
      CREATE TABLE token (
        access_token TEXT,
        token_type TEXT,
        expires_in INTEGER,
        created_at TEXT,
        refresh_token TEXT
      )
    SQL
  end
  private :setup_token_database

  def store_token_record(token_json_response, from_when=Time.now)
    token_database.transaction(:exclusive) do
      token_database.execute <<-SQL
        INSERT INTO token (
          access_token, token_type, expires_in, created_at, refresh_token
        ) VALUES (
          '#{token_json_response['access_token']}',
          '#{token_json_response['token_type']}',
          #{token_json_response['expires_in']},
          '#{from_when.utc.iso8601}',
          '#{token_json_response['refresh_token']}'
        )
      SQL
    end
  end

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
end
