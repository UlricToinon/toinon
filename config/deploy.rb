# require 'capistrano/ext/multistage'
# require 'rvm/capistrano'

# require 'bundler/capistrano'
# set :stages, %w(production staging development)

# set :application, 'Toinon'
# set :repository, 'git@github.com:UlricToinon/Toinon.git'
# set :default_stage, 'development'


# # Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/toinon'

# # Default value for :scm is :git
# set :scm, :git
# set :branch, 'master'
# set :user, 'deploy'

# set :deploy_via, :copy
# set :keep_releases, 5
# set :use_sudo, false
# set :ssh_options, {:forward_agent => true}

# set :bundle_flags, "--quiet"


# default_run_options[:pty] = true

# after 'deploy', 'deploy:cleanup'
# after 'deploy', 'deploy:migrate'

# namespace :deploy do
#   %w[start stop restart reload].each do |command|
#     desc "#{command} unicorn server"
#     task command, roles: :app, except: {no_release: true} do
#       run "sudo /etc/init.d/unicorn_toinon #{command}"
#     end
#   end

#   # Use this if you know what you are doing.
#   #
#   # desc "Zero-Downtime restart of Unicorn"
#   # task :restart, :except => { :no_release => true } do
#   #   run "sudo /etc/init.d/unicorn_#{application} reload"
#   # end
# end


require 'capistrano/ext/multistage'
require "bundler/capistrano"
require "rvm/capistrano"

set :stages, %w(production staging development)

set :deploy_via, :copy
set :keep_releases, 5

set :default_run_options, {:pty => true}
set :ssh_options, {:forward_agent => true}

after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do

  after 'deploy:setup', :roles => :app do
  # for unicorn
  run "mkdir -p #{shared_path}/sockets"
  run "mkdir -p #{shared_path}/pids"
end

  task :setup_config, roles: :app do
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.sample.yml"), "#{shared_path}/config/database.yml"
    puts "Now edit the config files in #{shared_path}."
  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  # desc "Make sure local git is in sync with remote."
  # task :check_revision, roles: :web do
  #   unless `git rev-parse HEAD` == `git rev-parse origin/master`
  #     puts "WARNING: HEAD is not the same as origin/master"
  #     puts "Run `git push` to sync changes."
  #     exit
  #   end
  # end
  # before "deploy", "deploy:check_revision"

  after "deploy", "deploy:restart"

  desc "Zero-downtime restart of Unicorn"
  task :restart, :except => { :no_release => true } do
    run "kill -s USR2 `cat #{shared_path}/pids/unicorn.#{application}.pid`"
  end

  desc "Start unicorn"
  task :start, :except => { :no_release => true } do
    run "cd #{current_path} ; bundle exec unicorn_rails -c config/unicorn.rb -D -E #{rails_env}"
  end

  desc "Stop unicorn"
  task :stop, :except => { :no_release => true } do
    run "kill -s QUIT `cat #{shared_path}/pids/unicorn.#{application}.pid`"
  end
end
