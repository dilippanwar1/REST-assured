require 'fake_rest_services'
require 'rake'
require 'sinatra/activerecord/rake'

require 'bundler'
Bundler::GemHelper.install_tasks

task :install do
  Rake::Task['db:migrate'].invoke
end
