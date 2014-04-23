namespace :resync do
  def setup
    require File.join(Rails.root, 'config', 'resync')
  end

  desc 'Generates a new ResourceSync resource list.'
  task :generate => :environment do
    setup
    root = Resync.configuration.save_path || ENV["LOCATION"] || Rails.public_path
    path = File.join(root, 'resourcelist.xml')
    Resync::Generator.instance.build!
    Resync::Generator.instance.save path
  end
end
