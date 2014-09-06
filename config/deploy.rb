require 'capistrano/ext/multistage'
require "bundler/capistrano"
require "rvm/capistrano"

set :stages, %w(production staging development)
set :default_stage, "production"

# set :deploy_via, :copy
# set :keep_releases, 5

set :default_run_options, {:pty => true}
set :ssh_options, {:forward_agent => true}


set(:latest_release) { fetch(:current_path) }
set(:release_path) { fetch(:current_path) }
set(:current_release) { fetch(:current_path) }

set(:current_revision) { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:latest_revision) { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:previous_revision) { capture("cd #{current_path}; git rev-parse --short HEAD@{1}").strip }

namespace :deploy do

  desc "Deploy your application"
  task :default do
    update
    migrate
    seed
    restart
  end

  desc "Setup your git-based deployment app"
    task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "#{try_sudo} mkdir -p #{dirs.join(' ')} && #{try_sudo} chmod g+w #{dirs.join(' ')}"
    run "git clone #{repository} #{current_path}"
  end

  task :cold do
    update
    migrate
  end
  task :update do
    transaction do
      update_code
    end
  end
    
  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git fetch origin; git reset --hard origin/#{branch}"
    finalize_update
  end

  task :finalize_update do
    run "cp -R #{release_path}/app/assets/images/* #{shared_path}/assets"
  end
  
  desc "Update the database (overwritten to avoid symlink)"
    task :migrations do
    transaction do
      update_code
    end
    migrate
    seed
    restart
  end

  desc "reload the database with seed data"
  task :seed do
    run "cd #{current_path}; bundle exec rake db:seed RAILS_ENV=#{rails_env}"
  end
  
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

  desc "Zero-downtime restart of Unicorn"
  task :restart, :except => { :no_release => true } do
    run "kill -s USR2 `cat #{shared_path}/pids/unicorn.#{application}_#{rails_env}.pid`"
  end

  desc "Start unicorn"
  task :start, :except => { :no_release => true } do
    run "cd #{current_path} ; bundle exec unicorn_rails -c config/unicorn.rb -D -E #{rails_env}"
  end

  desc "Stop unicorn"
  task :stop, :except => { :no_release => true } do
    run "kill -s QUIT `cat #{shared_path}/pids/unicorn.#{application}_#{rails_env}.pid`"
  end
end
