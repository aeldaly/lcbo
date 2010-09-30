module LCBO
  class ProductListsCrawler

    MAX_RETRIES = 10

    class EpicTimeoutError < StandardError; end

    def self.run(params = {}, tries = 0, &block)
      raise ArgumentError, 'block expected' unless block_given?
      begin
        payload = LCBO.product_list(params[:page])
        yield payload
        run(:page => payload[:next_page], &block) if payload[:next_page]
      rescue Errno::ETIMEDOUT, Timeout::Error
        # On timeout, try again.
        raise EpicTimeoutError if tries > MAX_RETRIES
        run(params, (tries + 1), &block)
      end
    end

  end
end
