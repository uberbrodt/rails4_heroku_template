environment <<-eos
config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.view_specs false
      g.helper_specs false
    end

config.sass.preferred_syntax = :sass
eos

file 'config/unicorn.rb', <<-CODE
worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 25
preload_app true

before_fork do |server, worker|
    Signal.trap 'TERM' do
          puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
              Process.kill 'QUIT', Process.pid
                end

      defined?(ActiveRecord::Base) and
          ActiveRecord::Base.connection.disconnect!
end 

after_fork do |server, worker|
    Signal.trap 'TERM' do
          puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
            end

      defined?(ActiveRecord::Base) and
          ActiveRecord::Base.establish_connection
end
CODE

file 'lib/tasks/assets_nodigest.rake', <<-CODE
# https://gist.github.com/eric1234/5692456
#  
require 'fileutils'
 
task "assets:precompile" do
#Create nondigest versions of all digest assets, overload
#the assets:precompile task so it gets compiled into slug
#in Heroku
  fingerprint = /\-[0-9a-f]{32}\./
  for file in Dir["public/assets/**/*"]
    next unless file =~ fingerprint
    nondigest = file.sub fingerprint, '.'
    FileUtils.cp file, nondigest, verbose: true
  end
end
CODE

file 'Procfile', "web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb"

gem 'pg'
gem 'rack-timeout'
gem 'unicorn'
gem 'bourbon'
gem 'compass-rails', github: 'milgner/compass-rails', ref: '1749c06f15dc4b058427e7969810457213647fb8'
gem 'pg_array_parser'
gem 'haml-rails'

gem_group :development, :test do
    gem 'mail_view'
    gem 'letter_opener'
    gem 'better_errors'
    gem 'binding_of_caller'
    gem 'pry'
    gem 'simplecov', :require => false
    gem 'database_cleaner'
    gem 'rspec-given'
    gem 'rspec-rails'
    gem 'capybara'
    gem 'launchy'
    gem 'factory_girl_rails'
end

gem_group :production, :staging do
  gem 'rails_12factor'
end

run "bundle install"

generate("rspec:install")

file "spec/spec_helper.rb", <<-CODE
require 'simplecov'
SimpleCov.start 'rails'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'rspec/given'
require 'capybara/rspec'


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.include FactoryGirl::Syntax::Methods
  #config.fixture_path = "\#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
CODE
