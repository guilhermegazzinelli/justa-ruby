# frozen_string_literal: true

require_relative "justa/version"
require_relative "justa/authenticator"
require_relative "justa/request"
require_relative "justa/object"
require_relative "justa/model"
require_relative "justa/core_ext"
require_relative "justa/errors"
require_relative "justa/util"
require_relative "justa/token_manager"
require_relative "justa/order_commom"

Dir[File.expand_path("justa/resources/*.rb", __dir__)].map do |path|
  require path
end

module Justa
  class Error < StandardError; end

  class << self
    attr_accessor :username, :password, :client_id, :client_secret, :integrator_id, :callback_url, :credentials,
                  :default_client_key, :document
    attr_reader :api_endpoint

    def production?
      env = nil
      begin
        env = ENV["RACK_ENV"] == "production" ||
              ENV["RAILS_ENV"] == "production" ||
              ENV["PRODUCTION"] ||
              ENV["production"] || (Rails.env.production? if Object.const_defined?("::Rails"))
      rescue NameError => e
        return false
      end

      env || false
    end
  end

  @default_client_key = :default

  @api_endpoint = Justa.production? ? "https://api.Justa.com.br" : "https://integrador.staging.justa.com.vc"

  puts "Running on production" if production?
end
