require "uri"
require "rest_client"
require "multi_json"

DEFAULT_HEADERS = {
  # "Content-Type" => "application/x-www-form-urlencoded",
  "Accept" => "application/json",
  "User-Agent" => "justa-ruby/#{Justa::VERSION}"
}

module Justa
  class Request
    attr_accessor :path, :method, :parameters, :headers, :query

    def initialize(path, method, options = {})
      @path = path
      @method     = method
      @parameters = options[:params]      || nil
      @query      = options[:query]       || {}
      @headers    = options[:headers]     || {}
      @auth       = options[:auth]        || false
      @client_key = options[:client_key]  || @parameters && (@parameters[:client_key] || @parameters["client_key"]) || Justa.default_client_key
    end

    def run
      params = request_params
      response = RestClient::Request.execute params
      MultiJson.decode response.body
    rescue RestClient::Exception => e
      begin
        parsed_error = MultiJson.decode e.http_body

        if e.is_a? RestClient::ResourceNotFound
          if parsed_error["message"]
            raise Justa::NotFound.new(parsed_error, request_params, e)
          else
            raise Justa::NotFound.new(nil, request_params, e)
          end
        elsif parsed_error["message"]
          raise Justa::ResponseError.new(request_params, e, parsed_error["message"])
        else
          raise Justa::ValidationError, parsed_error
        end
      rescue MultiJson::ParseError
        raise Justa::ResponseError.new(request_params, e)
      end
    rescue MultiJson::ParseError
      raise Justa::ResponseError.new(request_params, response)
    rescue SocketError
      raise Justa::ConnectionError, $!
    rescue RestClient::ServerBrokeConnection
      raise Justa::ConnectionError, $!
    end

    def call(ressource_name)
      JustaObject.convert run, ressource_name, @client_key
    end

    def self.get(url, options = {})
      new url, "GET", options
    end

    def self.auth(url, options = {})
      options[:auth] = true
      new url, "POST", options
    end

    def self.post(url, options = {})
      new url, "POST", options
    end

    def self.put(url, options = {})
      new url, "PUT", options
    end

    def self.patch(url, options = {})
      new url, "PATCH", options
    end

    def self.delete(url, options = {})
      new url, "DELETE", options
    end

    def request_params
      aux = {
        method: method,
        url: full_api_url
      }

      @parameters

      if !@auth && @parameters && Justa.callback_url && method == "POST"
        aux.merge!({ payload: MultiJson.encode(@parameters.merge({ callback_url: Justa.callback_url })) })
      elsif @parameters
        aux.merge!({ payload: @parameters })
      end

      # extra_headers = DEFAULT_HEADERS
      # extra_headers[:authorization] = "Bearer #{Justa::TokenManager.token_for @client_key}" unless @auth
      # extra_headers[:authorization] = "Bearer #{Justa::TokenManager.token_for @client_key}" unless @auth

      aux.merge!({ headers: DEFAULT_HEADERS.merge(@headers) })
      aux
    end

    def full_api_url
      Justa.api_endpoint + path
    end
  end
end
