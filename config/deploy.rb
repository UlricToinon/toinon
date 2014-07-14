set :stages, %w(production staging development)
require 'capistrano/ext/multistage'
require 'rvm/capistrano'
require 'bundler/capistrano'

set :application, 'Toinon'
set :repository, 'git@github.com:UlricToinon/Toinon.git'
set :default_stage, 'development'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/home/deploy/webapps/toinon'

# Default value for :scm is :git
set :scm, :git
set :branch, 'master'
set :user, 'deploy'

set :deploy_via, :copy
set :keep_releases, 5
set :use_sudo, false
set :ssh_options, {:forward_agent => true}

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

default_run_options[:pty] = true

# after "deploy:restart", "deploy:cleanup"
# namespace :deploy do

#   desc "symlink shared files"
#   task :symlink_shared, :roles => :app do
#     run "ln -nfs #{shared_path}/system/mongoid.yml #{release_path}/config/mongoid.yml"
#     run "ln -nfs #{shared_path}/system/application.yml #{release_path}/config/application.yml"
#   end

#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end

#   %w[start stop restart].each do |command|
#     desc "#{command} unicorn server"
#     task command, roles: :app, except: {no_release: true} do
#       run "/etc/init.d/unicorn_toinon #{command}"
#     end
#   end

#   task :setup_config, roles: :app do
#     sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/toinon"
#     sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_toinon"
#     run "mkdir -p #{shared_path}/config"
#     put File.read("config/database.yml"), "#{shared_path}/config/database.yml"
#     puts "Now edit the config files in #{shared_path}."
#   end
#   after "deploy:setup", "deploy:setup_config"

# end
# before "deploy:assets:precompile", "deploy:symlink_shared"

# # Unicorn
# require 'capistrano-unicorn'
# after 'deploy:restart', 'unicorn:reload'    # app IS NOT preloaded
# after 'deploy:restart', 'unicorn:restart'   # app preloaded

after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      sudo "sed -i \"s/^M//\" #{current_path}/config/unicorn_init.sh"
      run "/etc/init.d/unicorn_toinon #{command}"
    end
  end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/toinon"
    sudo "sed -i \"s/^M//\" #{current_path}/config/unicorn_init.sh"
    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_toinon"
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.yml"), "#{shared_path}/config/database.yml"
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