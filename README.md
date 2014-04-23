# Resync

ResourceSync generators for Ruby

## Instalation

Install the gem:

```ruby
gem install resync
```

Then create the initial config file:

```ruby
rails g resync:install
```

## Usage

In your config file, paths can be indexed as follows:

```ruby
Resync::Generator.instance.load(host: 'mywebsite.com') do
  path :root, priority: 1
  path :faq, priority: 0.5, change_frequency: 'weekly'
  literal '/my_blog'
  resources :activities, params: { format: 'html' }
  resources :articles, objects: proc { Article.published }
end
```

Building the resource list:

```ruby
rake resync:generate:resourcelist
```

By default the resource list gets saved in the current application root path. You can change the save path by passing a LOCATION environment variable or using a configuration option:

```ruby
Resync.configure do |config|
  config.save_path = "/home/user/apps/my-app/shared"
end
```

## Setting defaults

You may change the defaults for either *params* or *search* options as follows:

```ruby
Resync.configure do |config|
  config.params_format = 'html'
  config.search_change_frequency = 'monthly'
end
```

## Large sites

Google imposes a limit of 50000 entries per resource list and maximum size of 10 MB. To comply with these rules,
resource lists having over 10.000 urls are being split into multiple files. You can change this value by overriding the max urls value:

```ruby
Resync.configure do |config|
  config.max_urls = 50000
end
```

## Tests

This project is using minitest. To run the test simply run `rake`.

## License

This package is licensed under the MIT license and/or the Creative
Commons Attribution-ShareAlike.
