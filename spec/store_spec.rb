require 'minitest/autorun'
require File.expand_path('../minitest_helper', __FILE__)

describe 'Store' do
  it 'appends entries' do
    store = Resync::Store.new(max_entries: 1000)
    3.times { store << 'contents' }
    store.entries.length.must_equal 3
  end

  it 'resets entries when limit is reached' do
    store = Resync::Store.new(max_entries: 2)
    2.times { store << 'contents' }
    store.entries.length.must_equal 2
    store << 'contents'
    store.entries.length.must_equal 1
  end

  describe 'when a reset has occurred' do
    it 'runs a callback' do
      store = Resync::Store.new(max_entries: 2)
      store.before_reset do |entries|
        store.instance_variable_set('@callback_data', entries.join(', '))
      end
      3.times { |i| store << "item #{i + 1}" }
      store.instance_variable_get('@callback_data').must_equal 'item 1, item 2'
    end

    it 'increments reset count' do
      store = Resync::Store.new(max_entries: 2)
      5.times { store << 'contents' }
      store.reset_count.must_equal 2
    end
  end
end
