require "uri"
require "rest_client"
require "multi_json"

module Justa
  class Request
    DEFAULT_HEADERS = {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "User-Agent" => "justa-ruby/#{Justa::VERSION}"
    }.freeze

    attr_accessor :path, :method, :parameters, :headers, :query

    def initialize(path, method, options = {})
      @path             = path
      @method           = method
      @parameters       = options[:params]      || nil
      @query            = options[:query]       || {}
      @headers          = options[:headers]     || {}
      @auth             = options[:auth]        || false
      @append_document  = options.fetch(:append_document, true)
      @client_key       = options[:client_key] || @parameters && (@parameters[:client_key] || @parameters["client_key"]) || Justa.default_client_key
    end

    def run
      response = RestClient::Request.execute request_params
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
      return {} unless response.code < 200 && response.code > 299

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

      if !@auth && @parameters && method == "POST"
        aux.merge!({ payload: MultiJson.encode(@parameters.to_request_params) })
      elsif @parameters
        aux.merge!({ payload: @parameters })
      end

      extra_headers = DEFAULT_HEADERS.merge(@headers)
      extra_headers[:authorization] = "Bearer #{Justa::TokenManager.token_for @client_key}" unless @auth
      extra_headers["integratorId"] = Justa.integrator_id unless @auth

      aux.merge!({ headers: extra_headers })
      aux
    end

    def must_append_document?; end

    def full_api_url
      Justa.api_endpoint + "/payment-provider/api" + @path + (!@auth && @append_document ? ("/" + TokenManager.client_for(@client_key).document.to_s) : "")
    end
  end
end
