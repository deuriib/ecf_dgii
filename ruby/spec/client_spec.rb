require "spec_helper"

RSpec.describe EcfDgii::Client do
  before do
    ENV["ECF_API_KEY"] = "test-token"
  end

  after do
    ENV.delete("ECF_API_KEY")
  end

  it "initializes with correct base URL for test environment" do
    client = described_class.new(environment: :test)
    expect(client.environment).to eq(:test)
    expect(client.api_client.config.host).to eq("api.test.ecfx.ssd.com.do")
  end

  it "initializes with correct base URL for prod environment" do
    client = described_class.new(environment: :prod)
    expect(client.environment).to eq(:prod)
    expect(client.api_client.config.host).to eq("api.prod.ecfx.ssd.com.do")
  end

  it "overrides url if base_url parameter is provided" do
    client = described_class.new(base_url: "https://custom.api.com/v1")
    expect(client.api_client.config.host).to eq("custom.api.com")
    expect(client.api_client.config.base_path).to eq("/v1")
  end

  it "raises ArgumentError if no API key is provided" do
    ENV.delete("ECF_API_KEY")
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it "exposes API classes" do
    client = described_class.new
    expect(client.ecf_api).to be_an_instance_of(EcfDgii::Generated::EcfApi)
    expect(client.dgii_api).to be_an_instance_of(EcfDgii::Generated::DgiiApi)
  end

  it "dynamically routes send_ecf based on tipoe_cf in encabezado" do
    client = described_class.new
    
    # Mocking id_doc and encabezado structure
    id_doc = double(tipoe_cf: "FacturaDeCreditoFiscalElectronica")
    encabezado = double(id_doc: id_doc)
    ecf = double(encabezado: encabezado)

    # Expect delegation to send_ecf31
    expect(client).to receive(:send_ecf31).with(ecf).and_return(:success)
    expect(client.send_ecf(ecf)).to eq(:success)
  end

  it "delegates company operations to company_api" do
    client = described_class.new
    expect(client.company_api).to receive(:get_company_by_rnc).with("123456789").and_return(:company)
    expect(client.get_company_by_rnc("123456789")).to eq(:company)
  end
end
