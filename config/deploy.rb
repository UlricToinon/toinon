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

set :application, "toinon_production"
set :user, "deploy"
set :port, 65432
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:UlricToinon/Toinon.git"
set :branch, "master"


default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "/etc/init.d/toinon_production_unicorn_init #{command}"
    end
  end

  task :setup_config, roles: :app do
    # sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    # sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.sample.yml"), "#{shared_path}/config/database.yml"
    puts "Now edit the config files in #{shared_path}."
  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "Make sure local git is in sync with remote."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "deploy:check_revision"
end
