require "uri"

module EcfDgii
  class Client
    ENVIRONMENT_URLS = {
      test: "https://api.test.ecfx.ssd.com.do",
      cert: "https://api.cert.ecfx.ssd.com.do",
      prod: "https://api.prod.ecfx.ssd.com.do"
    }.freeze

    attr_reader :api_client, :environment

    def initialize(api_key: nil, base_url: nil, environment: :test, timeout: 30)
      token = api_key || ENV["ECF_API_KEY"]
      resolved_url = base_url || ENV["ECF_API_URL"] || ENVIRONMENT_URLS[environment.to_sym]
      raise ArgumentError, "Se requiere un api_key o la variable de entorno ECF_API_KEY" if token.nil? || token.empty?

      config = EcfDgii::Generated::Configuration.new
      uri = URI.parse(resolved_url)
      
      config.scheme = uri.scheme
      config.host = uri.host
      config.base_path = uri.path.empty? ? "" : uri.path
      
      config.api_key["Authorization"] = "Bearer #{token}"
      config.timeout = timeout

      @api_client = EcfDgii::Generated::ApiClient.new(config)
      @environment = environment.to_sym
    end

    def ecf_api
      @ecf_api ||= EcfDgii::Generated::EcfApi.new(api_client)
    end

    def dgii_api
      @dgii_api ||= EcfDgii::Generated::DgiiApi.new(api_client)
    end

    def recepcion_api
      @recepcion_api ||= EcfDgii::Generated::RecepcionApi.new(api_client)
    end

    def company_api
      @company_api ||= EcfDgii::Generated::CompanyApi.new(api_client)
    end

    def aprobacion_comercial_api
      @aprobacion_comercial_api ||= EcfDgii::Generated::AprobacionComercialApi.new(api_client)
    end
  end
end
