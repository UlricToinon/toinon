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

set :bundle_flags, "--quiet"


default_run_options[:pty] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      sudo "sh /etc/init.d/unicorn_toinon #{command}"
    end
  end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/toinon"
    sudo "ln -nfs /home/deploy/unicorn/unicorn_init_toinon.sh /etc/init.d/unicorn_toinon"
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