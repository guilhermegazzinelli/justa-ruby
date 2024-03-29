module Justa
  class Model < JustaObject
    def create
      update Justa::Request.post(self.class.url, params: to_hash).call(class_name)
      self
    end

    # def save
    #   update Justa::Request.put(url, params: unsaved_attributes).call(class_name)
    #   self
    # end

    def url(*params)
      raise RequestError, "Invalid ID" unless primary_key.present?

      self.class.url CGI.escape(primary_key.to_s), *params
    end

    def fetch
      update self.class.find(primary_key, client_key: client_key)
      self
    end

    def primary_key
      tx_id
    end

    def class_name
      self.class.to_s.split("::").last
    end

    class << self
      def create(*args)
        new(*args).create
      end

      def find_by_id(id, **options)
        raise RequestError, "Invalid ID" unless id.present?

        Justa::Request.get(url(id), options.merge({ append_document: false })).call underscored_class_name
      end
      alias find find_by_id

      # def find_by(params = Hash.new, page = nil, count = nil)
      #   params = extract_page_count_or_params(page, count, **params)
      #   raise RequestError.new('Invalid page count') if params[:page] < 1 or params[:count] < 1

      #   Justa::Request.get(url, params: params).call
      # end
      # alias :find_by_hash :find_by

      # def all(*args, **params)
      #   params = extract_page_count_or_params(*args, **params)
      #   find_by params
      # end
      # alias :where :all

      def url(*params)
        ["/#{CGI.escape class_name}", *params].join "/"
      end

      def class_name
        name.split("::").last.downcase
      end

      def underscored_class_name
        name.split("::").last.gsub(/[a-z0-9][A-Z]/) { |s| "#{s[0]}_#{s[1]}" }.downcase
      end
    end
  end
end
