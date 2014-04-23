module Resync
  class Generator
    include Singleton

    SEARCH_ATTRIBUTES = {
      updated_at: 'lastmod',
      change_frequency: 'changefreq',
      priority: 'priority'
    }

    attr_accessor :store, :protocol, :host, :routes, :fragments, :context

    # Instantiates a new object.
    # Should never be called directly.
    def initialize
      self.class.send(:include, Rails.application.routes.url_helpers)
      self.protocol = 'http'
      self.fragments = []
      self.store = Store.new(max_entries: Resync.configuration.max_urls)
      self.store.before_reset do |entries|
        self.process_fragment!
      end
    end

    # Sets the urls to be indexed.
    #
    # The +host+, or any other global option can be set here:
    #
    #   Resync::Generator.instance.load(host: 'mywebsite.com') do
    #     ...
    #   end
    #
    # Literal paths can be added as follows:
    #
    #   Resync::Generator.instance.load(host: 'mywebsite.com') do
    #     literal '/some_fancy_url'
    #   end
    #
    # Simple paths can be added as follows:
    #
    #   Resync::Generator.instance.load(host: 'mywebsite.com') do
    #     path :faq
    #   end
    #
    # Object collections are supported too:
    #
    #   Resync::Generator.instance.load(host: 'mywebsite.com') do
    #     resources :activities
    #   end
    #
    # Search options such as frequency and priority can be declared as an options hash:
    #
    #   Resync::Generator.instance.load(host: 'mywebsite.com') do
    #     path :root, priority: 1
    #     path :faq, priority: 0.8, change_frequency: 'daily'
    #     resources :activities, change_frequency: 'weekly'
    #   end
    #
    def load(options = {}, &block)
      options.each do |k, v|
        self.send("#{k}=", v)
      end
      self.routes = block
    end

    # Adds the literal url (for consistency, starting with a "/"  as in "/my_url")
    # accepts similar options to path and resources
    def literal(target_url, options = {})
      search = Resync.configuration.search.clone.merge!(options.select { |k, v| SEARCH_ATTRIBUTES.keys.include?(k) })
      search.merge!(search) { |type, value| get_data(nil, value) }

      output_host =  options[:host] || host
      output_protocol = options[:protocol] || protocol
      self.store << {
        url: "#{output_protocol}://#{output_host}#{target_url}",
        search: search,
        checksum: 'TODO'
      }
    end

    # Adds the specified url or object (such as an ActiveRecord model instance).
    # In either case the data is being looked up in the current application routes.
    #
    # Params can be specified as follows:
    #
    #   # config/routes.rb
    #   match "/frequent-questions" => "static#faq", :as => "faq"
    #
    #   # config/resync.rb
    #   path :faq, :params => { :filter => "recent" }
    #
    # The resolved url would be <tt>http://mywebsite.com/frequent-questions?filter=recent</tt>.
    #
    def path(object, options = {})
      params = Resync.configuration.params.clone.merge!(options[:params] || {})
      params[:protocol] ||= protocol # Use global protocol if none was specified.
      params[:host] ||= host # Use global host if none was specified.
      params.merge!(params) { |type, value| get_data(object, value) }

      search = Resync.configuration.search.clone.merge!(options.select { |k, v| SEARCH_ATTRIBUTES.keys.include?(k) })
      search.merge!(search) { |type, value| get_data(object, value) }

      self.store << {
        :object => object,
        :search => search,
        :params => params
      }
    end

    # Adds the associated object types.
    #
    # The following will map all Activity entries, as well as the index (<tt>/activities</tt>) page:
    #
    #   resources :activities
    #
    # You can also specify which entries are being mapped:
    #
    #   resources :articles, objects: proc { Article.published }
    #
    # To skip the index action and map only the records:
    #
    #   resources :articles, skip_index: true
    #
    # As with the path, you can specify params through the +params+ options hash.
    # The params can also be build conditionally by using a +proc+:
    #
    #   resources :activities, params: { host: proc { |activity| [activity.location, host].join(".") } }, skip_index: true
    #
    # In this case the host will change based the each of the objects associated +location+ attribute.
    # Because the index page doesn't have this attribute it's best to skip it.
    #
    def resources(type, options = {})
      path(type) unless options[:skip_index]
      link_params = options.reject { |k, v| k == :objects }
      get_objects = lambda {
        options[:objects] ? options[:objects].call : type.to_s.classify.constantize
      }
      get_objects.call.find_each(batch_size: Resync.configuration.query_batch_size) do |object|
        path(object, link_params)
      end
    end

    # Parses the loaded data and returns the xml entries.
    def render(object = 'fragment')
      xml = Builder::XmlMarkup.new(indent: 2)
      file = File.read(File.expand_path("../../views/#{object}.xml.builder", __FILE__))
      instance_eval(file)
    end

    # Creates a temporary file from the existing entries.
    def process_fragment!
      file = Tempfile.new('resourcelist.xml')
      file.write(render)
      file.close
      self.fragments << file
    end

    # Generates fragments.
    def build!
      instance_exec(self, &routes)
      process_fragment! unless store.entries.empty?
    end

    # Creates the resourcelist index file and saves any existing fragments.
    def save(location)
      if fragments.length == 1
        FileUtils.mv(fragments.first.path, location)
      else
        remove_saved_files(location)
        root = File.join(Pathname.new(location).dirname)
        Dir.mkdir(root) unless File.directory?(root)
        fragments.each_with_index do |fragment, i|
          file_pattern = File.join(root, "resourcelist-part#{i + 1}.xml")
          FileUtils.mv(fragment.path, file_pattern)
          File.chmod(0755, file_pattern)
        end
        file = File.new(location, 'w')
        file.write(render 'index')
        file.close
      end
      File.chmod(0755, location)
    end

    # URL to the resourcelist file.
    #
    # Defaults to <tt>resourcelist.xml</tt>.
    def file_url(path = 'resourcelist.xml')
      file_path = '/'
      file_path = File.join(file_path, context) if context
      file_path = File.join(file_path, path)

      URI::HTTP.build(host: host, path: file_path).to_s
    end

    def remove_saved_files(location)
      root = File.join(Pathname.new(location).dirname)
      Dir[File.join(root, 'resourcelist-part*.xml')].each do
        |file| File.unlink(file)
      end
      File.unlink(location) if File.exist?(location)
    end

    private

    def get_data(object, data)
      data.is_a?(Proc) ? data.call(object) : data
    end
  end
end
