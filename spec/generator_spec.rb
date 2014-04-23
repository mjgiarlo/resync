require 'minitest/autorun'
require File.expand_path('../minitest_helper', __FILE__)

describe 'Generator' do
  before do
    create_db
    Resync.configuration.reset
    Resync::Generator.reset_instance
  end

  after do
    drop_db
  end

  it 'has a valid xml response' do
    Resync::Generator.instance.load(host: 'someplace.com') {}
    doc = Nokogiri::XML(Resync::Generator.instance.render)
    doc.errors.length.must_equal 0
    doc.root.name.must_equal 'urlset'
  end

  it 'creates entries based on literals' do
    urls = ['http://someplace.com/target_url', 'http://someplace.com/another_url']
    Resync::Generator.instance.load(host: 'someplace.com') do
      literal '/target_url'
      literal '/another_url'
    end
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    elements = doc.xpath '//url/loc'
    elements.length.must_equal urls.length
    elements.each_with_index do |element, i|
      element.text.must_equal urls[i]
    end
  end

  it 'creates entries based on literals with https' do
    urls = ['https://someplace.com/target_url', 'https://someplace.com/another_url']
    Resync::Generator.instance.load(host: 'someplace.com', protocol: 'https') do
      literal '/target_url'
      literal '/another_url'
    end
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    elements = doc.xpath '//url/loc'
    elements.length.must_equal urls.length
    elements.each_with_index do |element, i|
      element.text.must_equal urls[i]
    end
  end

  it 'creates entries based on the route paths' do
    urls = ['http://someplace.com/', 'http://someplace.com/questions']
    Resync::Generator.instance.load(host: 'someplace.com') do
      path :root
      path :faq
    end
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    elements = doc.xpath '//url/loc'
    elements.length.must_equal urls.length
    elements.each_with_index do |element, i|
      element.text.must_equal urls[i]
    end
  end

  it 'creates entries based on the route paths with https' do
    urls = ['https://someplace.com/', 'https://someplace.com/questions']
    Resync::Generator.instance.load(host: 'someplace.com', protocol: 'https') do
      path :root
      path :faq
    end
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    elements = doc.xpath '//url/loc'
    elements.length.must_equal urls.length
    elements.each_with_index do |element, i|
      element.text.must_equal urls[i]
    end
  end

  it 'creates entries based on the route resources' do
    Resync::Generator.instance.load(host: 'someplace.com') do
      resources :activities
    end
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    elements = doc.xpath '//url/loc'
    elements.length.must_equal (Activity.count + 1)
    elements.first.text.must_equal 'http://someplace.com/activities'
    elements[1..-1].each_with_index do |element, i|
      element.text.must_equal "http://someplace.com/activities/#{i + 1}"
    end
  end

  it 'creates entries based on the route resources with https' do
    Resync::Generator.instance.load(host: 'someplace.com', protocol: 'https') do
      resources :activities
    end
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    elements = doc.xpath '//url/loc'
    elements.length.must_equal (Activity.count + 1)
    elements.first.text.must_equal 'https://someplace.com/activities'
    elements[1..-1].each_with_index do |element, i|
      element.text.must_equal "https://someplace.com/activities/#{i + 1}"
    end
  end

  it 'creates entries using only for the specified objects' do
    activities = proc { Activity.where(published: true) }
    Resync::Generator.instance.load(host: 'someplace.com') do
      resources :activities, objects: activities, skip_index: true
    end
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    elements = doc.xpath '//url/loc'
    elements.length.must_equal activities.call.length
    activities.call.each_with_index do |activity, i|
      elements[i].text.must_equal "http://someplace.com/activities/#{activity.id}"
    end
  end

  it 'creates urls using the specified params' do
    Resync::Generator.instance.load(host: 'someplace.com') do
      path :faq, params: { host: 'anotherplace.com', format: 'html', filter: 'recent' }
    end
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    elements = doc.xpath '//url/loc'
    elements.first.text.must_equal 'http://anotherplace.com/questions.html?filter=recent'
  end

  it 'creates params conditionally by using a Proc' do
    Resync::Generator.instance.load(host: 'someplace.com') do
      resources :activities, skip_index: true, params: { host: proc { |obj| [obj.location, host].join('.') } }
    end
    activities = Activity.all
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    elements = doc.xpath '//url/loc'
    elements.each_with_index do |element, i|
      element.text.must_equal "http://#{activities[i].location}.someplace.com/activities/#{activities[i].id}"
    end
  end

  it 'adds resourcelist xml attributes' do
    Resync::Generator.instance.load(host: 'someplace.com') do
      path :faq, priority: 1, change_frequency: 'always'
      resources :activities, change_frequency: 'weekly'
    end
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    doc.xpath('//url/priority').first.text.must_equal '1'
    elements = doc.xpath '//url/changefreq'
    elements[0].text.must_equal 'always'
    elements[1..-1].each do |element|
      element.text.must_equal 'weekly'
    end
  end

  it 'adds resourcelist xml attributes conditionally by using a Proc' do
    Resync::Generator.instance.load(host: 'someplace.com') do
      resources :activities, priority: proc { |obj| obj.id <= 2 ? 1 : 0.5 }, skip_index: true
    end
    activities = Activity.all
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    elements = doc.xpath '//url/priority'
    elements.each_with_index do |element, i|
      value = activities[i].id <= 2 ? '1' : '0.5'
      element.text.must_equal value
    end
  end

  it 'discards empty (or false) search attributes' do
    Resync::Generator.instance.load(host: 'someplace.com') do
      path :faq, priority: '', change_frequency: lambda { |e| return false}, updated_at: Date.today
    end
    Resync::Generator.instance.build!
    doc = Nokogiri::HTML(Resync::Generator.instance.render)
    doc.xpath('//url/priority').count.must_equal 0
    doc.xpath('//url/changefreq').count.must_equal 0
    doc.xpath('//url/lastmod').text.must_equal Date.today.to_s
  end

  it 'sets the resourcelist url based on the current host' do
    Resync::Generator.instance.load(host: 'someplace.com') {}
    Resync::Generator.instance.file_url.must_equal 'http://someplace.com/resourcelist.xml'
  end

  it 'sets the resourcelist url based on the current host and context' do
    Resync::Generator.instance.load(host: 'someplace.com', context: 'foo/bar') {}
    Resync::Generator.instance.file_url.must_equal 'http://someplace.com/foo/bar/resourcelist.xml'
  end

  it 'creates a file when saving' do
    path = File.join(Dir.tmpdir, 'resourcelist.xml')
    File.unlink(path) if File.exist?(path)
    Resync::Generator.instance.load(host: 'someplace.com') do
      resources :activities
    end
    Resync::Generator.instance.build!
    Resync::Generator.instance.save(path)
    File.exist?(path).must_equal true
    File.unlink(path)
  end

  describe 'fragments' do
    before do
      Resync.configure do |config|
        config.max_urls = 2
      end
    end

    it 'saves files' do
      Resync::Generator.instance.load(host: 'someplace.com') do
        path :root
        path :root
        path :root
        path :root
      end
      path = File.join(Dir.tmpdir, 'resourcelist.xml')
      root = File.join(Dir.tmpdir) # Directory is being removed at the end of the test.
      File.directory?(root).must_equal false
      Resync::Generator.instance.build!
      Resync::Generator.instance.save(path)
      1.upto(2) do |i|
        File.exists?(File.join(root, "resourcelist-part#{i}.xml")).must_equal true
      end
      FileUtils.rm_rf(root)
    end

    it 'has an index page' do
      Resync::Generator.instance.load(host: 'someplace.com') do
        path :root
        path :root
        path :root
        path :root
        path :root
      end
      Resync::Generator.instance.build!
      doc = Nokogiri::HTML(Resync::Generator.instance.render('index'))
      elements = doc.xpath '//sitemap'
      Resync::Generator.instance.fragments.length.must_equal 3
    end
  end
end
