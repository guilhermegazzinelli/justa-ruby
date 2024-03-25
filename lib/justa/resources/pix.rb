module Justa
  class Pix < OrderCommom
    # def self.url(*params)
    #   ["/#{ CGI.escape underscored_class_name }", *params].join '/'
    # end

    def primary_key
      tx_id
    end

    #
    # Request approve to Justa api for this pix ( Only in DEVELOPMENT)
    #
    # @param [Hash] params Parameters for function
    # @option params [Numeric] :value (Required) The amount that will be approved in cents format
    # @option params [String] :end_to_end_id (Optional) The reference for the payment transaction
    # @return [Pix] Return model pix instance
    # @example Pay 1.0 of pix
    #     pix_instance.approve(value: 1.0)
    def approve(**params)
      raise JustaError, "Can't approve value in Production environment" if Justa.production?
      raise ParamError.new("Missing value param", :value, :integer, url("approve")) unless params.has_key? :value

      Justa::Request.post(url("approve"),
                          { append_document: false, params: params }).call underscored_class_name
      fetch
    end
  end
end
