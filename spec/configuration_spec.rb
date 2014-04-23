require 'minitest/autorun'
require File.expand_path('../minitest_helper', __FILE__)

describe 'Configuration' do
  before do
    Resync.configuration.reset
  end

  it 'inherits defaults' do
    Resync.configuration.query_batch_size.must_equal 500
  end

  it 'assigns attributes' do
    Resync.configure do |config|
      config.query_batch_size = 200
    end
    Resync.configuration.query_batch_size.must_equal 200
  end

  it 'assigns nested attribute values' do
    Resync.configure do |config|
      config.params_format = 'html'
      config.search_change_frequency = 'monthly'
    end
    Resync.configuration.params_format.must_equal 'html'
    Resync.configuration.search_change_frequency.must_equal 'monthly'
  end

  it 'can be reset' do
    Resync.configure do |config|
      config.params_format = 'html'
    end
    Resync.configuration.reset
    Resync.configuration.params_format.must_be_nil
  end
end
