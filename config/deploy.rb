require 'capistrano/ext/multistage'
require 'rvm/capistrano'

require 'bundler/capistrano'
set :stages, %w(production staging development)

set :application, 'Toinon'
set :repository, 'git@github.com:UlricToinon/Toinon.git'
set :default_stage, 'development'


# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/var/www/toinon'

# Default value for :scm is :git
set :scm, :git
set :branch, 'master'
set :user, 'deploy'

set :deploy_via, :copy
set :keep_releases, 5
set :use_sudo, false
set :ssh_options, {:forward_agent => true}

set :bundle_flags, "--quiet"


default_run_options[:pty] = true

after 'deploy', 'deploy:cleanup'
after 'deploy', 'deploy:migrate'

namespace :deploy do
  %w[start stop restart reload].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "sudo /etc/init.d/unicorn_toinon #{command}"
    end
  end

  # Use this if you know what you are doing.
  #
  # desc "Zero-Downtime restart of Unicorn"
  # task :restart, :except => { :no_release => true } do
  #   run "sudo /etc/init.d/unicorn_#{application} reload"
  # end
end
