module Justa
  class OrderCommom < Model
    # def self.url(*params)
    #   ["/#{ CGI.escape underscored_class_name }", *params].join '/'
    # end

    #
    # Defines primary key for model
    #
    # @return [String] Return the primary_key field value
    def primary_key
      tx_id
    end
  end
end
