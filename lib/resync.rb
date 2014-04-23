require 'singleton'
require 'builder'
require 'resync/version'
require 'resync/configuration'
require 'resync/railtie'
require 'resync/store'
require 'resync/generator'

module Resync
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end
