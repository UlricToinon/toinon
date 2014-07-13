set :stages, %w(production staging development)
require 'capistrano/ext/multistage'
require 'bundler/capistrano'

set :application, 'Toinon'
set :repository, 'git@github.com:UlricToinon/Toinon.git'
set :default_stage, 'development'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

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


after "deploy:restart", "deploy:cleanup"
namespace :deploy do

  desc "symlink shared files"
  task :symlink_shared, :roles => :app do
    run "ln -nfs #{shared_path}/system/mongoid.yml #{release_path}/config/mongoid.yml"
    run "ln -nfs #{shared_path}/system/application.yml #{release_path}/config/application.yml"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

end
before "deploy:assets:precompile", "deploy:symlink_shared"

# Unicorn
require 'capistrano-unicorn'
after 'deploy:restart', 'unicorn:reload'    # app IS NOT preloaded
after 'deploy:restart', 'unicorn:restart'   # app preloaded