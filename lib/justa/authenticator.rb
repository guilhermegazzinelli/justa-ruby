require "jwt"
require "base64"

module Justa
  CLIENT_TYPES = %i[pdv e_comerce]

  #
  # Class to hold client authetication data
  #
  class Client
    attr_reader :username, :password, :client_id, :client_secret, :key, :document, :token, :integrator_id
    attr_accessor :default

    #
    # Initialize Client instance
    #
    # @param [Hash] **options Options required
    # @options [String] :username (Defaults to Justa.secret_key)
    # @options [String] :password (Defaults to Justa.password)
    # @options [String] :client_id (Required) The client identifier
    # @options [String] :client_secret (Required) The client secret
    # @options [String] :integrator_id (Required) The integrator identifier
    # @options [String] :key (Defaults to Justa.default_client_key)
    # @options [Boolean] :default (Defaults to true) Param to define if client is the default one ( Not fully used)
    # @options [Symbol] :type (Defaults to :pdv) Param to define if client is an PDV or E-Commerce [:pdv, :e_comerce]. Raises ParamError if not included in these types.
    def initialize(**options)
      @username = options.fetch(:username, Justa.username)
      @password = options.fetch(:password, Justa.password)
      @client_id = options.fetch(:client_id, Justa.client_id)
      @client_secret = options.fetch(:client_secret, Justa.client_secret)
      @integrator_id = options.fetch(:integrator_id, Justa.integrator_id)

      @key = Justa::Util.to_sym(options.fetch(:key, options.fetch(:document, nil) || Justa.default_client_key))
      @default = options.fetch(:default, true)
      @document = options.fetch(:document)
      @token = options.fetch(:token)
      # raise ParamError.new("Incorrect client type, must be one of #{CLIENT_TYPES}", :type, "Symbol") unless CLIENT_TYPES.include? @type
    rescue KeyError => e
      unless CLIENT_TYPES.include? @type
        raise ParamError.new("Missing data for credentials: #{e.key}, (#{e.message})", "Credentials",
                             "Symbol or String")
      end
    end

    #
    # Convert Client instance to hash
    #
    # @return [Hash] Return Client in hash form
    #
    def to_h
      {
        username: @username,
        password: @password,
        client_id: @client_id,
        document: @document,
        key: @key
      }
    end
  end

  class Authenticator
    attr_reader :key, :client

    #
    # Initialize Authenticator Class
    #
    # @param [Client] client Receives Client instance to initialize authenticator
    #
    def initialize(client)
      @client = client
      @key = client.key
      authenticate
    end

    #
    # Return client authentication token
    #
    # @return [String] Returns cleint authentication token
    #
    def token
      refresh_token_if_expired
      @a_token
    end

    private

    #
    # Call api to authenticate client, receiving auth and refresh token
    #
    # @return [String] Refresh token
    #
    def authenticate
      set_token_from_request Justa::Request.auth("/payment-provider/api/oauth/token",
                                                 { headers: { "Authorization" => basic_auth_header },
                                                   params: { username: @client.username, password: @client.password,
                                                             grant_type: "password" } }).run
    end

    #
    # Refreshes token to receive a new, not expired, JWT auth_token
    #
    # @return [<Type>] <description>
    #
    def refresh_token
      set_token_from_request Justa::Request.auth("/refresh-token",
                                                 { headers: { "Authorization" => "Bearer " + @r_token },
                                                   client_key: @key }).run
    end

    def basic_auth_header
      "Basic " + Base64.encode64("#{@client.client_id}:#{@client.client_secret}").gsub(/\n/, "")
    end

    def refresh_token_if_expired
      # refresh_token if Time.at(JWT.decode(@a_token, nil, false).first.dig("exp")) < Time.now
    end

    #
    # Sets tokens based on response of request
    #
    # @param [JustaObject] response Response from authentication or refresh request
    # @note Must include 'access_token' and 'refresh_token'
    # @return [String] Refresh token
    #
    def set_token_from_request(response)
      @a_token = response["access_token"]
      @r_token = response["refresh_token"]
    end
  end
end
