require "spec_helper"

RSpec.describe EcfDgii::Polling do
  it "polls until status is completed" do
    states = [
      double(progress: "InProcess"),
      double(progress: "InProcess"),
      double(progress: "Completed")
    ]

    call_count = 0
    result = described_class.poll_until_complete(
      EcfDgii::PollingOptions.new(initial_delay: 0.001, max_delay: 0.01)
    ) do
      call_count += 1
      states[call_count - 1]
    end

    expect(call_count).to eq(3)
    expect(result.progress).to eq("Completed")
  end

  it "raises PollingTimeoutError if it exceeds timeout" do
    options = EcfDgii::PollingOptions.new(initial_delay: 0.001, max_delay: 0.002, timeout: 0.005)
    
    expect {
      described_class.poll_until_complete(options) do
        double(progress: "InProcess")
      end
    }.to raise_error(EcfDgii::PollingTimeoutError)
  end

  it "raises PollingMaxRetriesError if it exceeds max retries" do
    options = EcfDgii::PollingOptions.new(initial_delay: 0.001, max_delay: 0.002, max_retries: 3)
    
    expect {
      described_class.poll_until_complete(options) do
        double(progress: "InProcess")
      end
    }.to raise_error(EcfDgii::PollingMaxRetriesError)
  end
end
