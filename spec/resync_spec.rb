require "minitest/autorun"
require File.expand_path("../minitest_helper", __FILE__)

describe "Resync" do
  it 'has a configuration' do
    Resync.configuration.must_be_instance_of Resync::Configuration
  end

  it 'caches configuration' do
    Resync.configuration.object_id.must_equal Resync.configuration.object_id
  end

  it 'yields the current configuration' do
    Resync.configure do |config|
      config.must_equal Resync.configuration
    end
  end
end
