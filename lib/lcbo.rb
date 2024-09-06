module LCBO

  DEFAULT_CONFIG = {
    :user_agent  => 'Mozilla/5.0 (Windows; U; MSIE 9.0; WIndows NT 9.0; en-US))', # Use the default User-Agent by default
    :max_retries => 3,   # Number of times to retry a request that fails
    :timeout     => 8    # Seconds to wait for a request before timing out
  }.freeze

  def self.config
    @config ||= nil
    reset_config! unless @config
    @config
  end

  def self.reset_config!
    @config = DEFAULT_CONFIG.dup
  end

end

require 'ext'
require 'lcbo/helpers'
require 'crawlkit'
require 'lcbo/pages'
