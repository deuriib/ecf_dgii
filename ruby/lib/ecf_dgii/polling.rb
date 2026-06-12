module EcfDgii
  class PollingError < StandardError; end
  class PollingTimeoutError < PollingError; end
  class PollingMaxRetriesError < PollingError; end

  class PollingOptions
    attr_accessor :initial_delay, :max_delay, :max_retries, :backoff_multiplier, :timeout

    def initialize(initial_delay: 2.0, max_delay: 30.0, max_retries: 0, backoff_multiplier: 1.5, timeout: 300.0)
      @initial_delay = initial_delay
      @max_delay = max_delay
      @max_retries = max_retries
      @backoff_multiplier = backoff_multiplier
      @timeout = timeout
    end
  end

  module Polling
    TERMINAL_PROGRESS = %w[Completed Failed Rejected].freeze

    def self.poll_until_complete(options = nil)
      opts = options || PollingOptions.new
      delay = opts.initial_delay
      retries = 0
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      loop do
        result = yield

        progress = nil
        if result.respond_to?(:progress)
          progress = result.progress
        elsif result.is_a?(Hash)
          progress = result[:progress] || result["progress"]
        end

        progress_value = progress.respond_to?(:value) ? progress.value : progress.to_s

        return result if TERMINAL_PROGRESS.include?(progress_value)

        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
        if opts.timeout && opts.timeout > 0 && elapsed >= opts.timeout
          raise PollingTimeoutError, "El polling excedió el tiempo límite de #{opts.timeout}s (último progreso: #{progress_value})"
        end

        retries += 1
        if opts.max_retries && opts.max_retries > 0 && retries >= opts.max_retries
          raise PollingMaxRetriesError, "El polling excedió el máximo de #{opts.max_retries} intentos (último progreso: #{progress_value})"
        end

        sleep(delay)
        delay = [delay * opts.backoff_multiplier, opts.max_delay].min
      end
    end
  end
end
