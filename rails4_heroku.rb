environment <<-eos
config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.view_specs false
      g.helper_specs false
    end
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
