require 'ruby_branch/version'
require 'ruby_branch/utils/to_query'
require 'ruby_branch/config'
require 'ruby_branch/errors/link_length_exceed_error'
require 'ruby_branch/errors/api_response_error'
require 'addressable'
require 'faraday'
require 'ruby_branch/api/response'
require 'ruby_branch/api/request'
require 'ruby_branch/api/resources/link'

module RubyBranch
  BRANCH_API_ENDPOINT = 'https://api.branch.io/'.freeze

  class << self

    attr_writer :config

  end

  def self.config
    @config ||= Config.new
  end

  def self.reset
    @config = Config.new
  end

  def self.configure
    yield(config)
  end
end
