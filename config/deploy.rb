# set :stages, %w(production staging development)
# require 'capistrano/ext/multistage'
# require 'rvm/capistrano'

# require 'bundler/capistrano'

# set :application, 'Toinon'
# set :repository, 'git@github.com:UlricToinon/Toinon.git'
# set :default_stage, 'development'

# # Default branch is :master
# # ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# # Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/home/deploy/webapps/toinon'

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

# after "deploy", "deploy:cleanup" # keep only the last 5 releases

# namespace :deploy do
#   %w[start stop restart].each do |command|
#     desc "#{command} unicorn server"
#     task command, roles: :app, except: {no_release: true} do
#       sudo "sh /etc/init.d/unicorn_toinon #{command}"
#     end
#   end

#   task :setup_config, roles: :app do
#     sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/toinon"
#     sudo "ln -nfs /home/deploy/unicorn/unicorn_init_toinon.sh /etc/init.d/unicorn_toinon"
#     run "mkdir -p #{shared_path}/config"
#     put File.read("config/database.yml"), "#{shared_path}/config/database.yml"
#     puts "Now edit the config files in #{shared_path}."
#   end
#   after "deploy:setup", "deploy:setup_config"

#   task :symlink_config, roles: :app do
#     run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
#   end
#   after "deploy:finalize_update", "deploy:symlink_config"

#   desc "Make sure local git is in sync with remote."
#   task :check_revision, roles: :web do
#     unless `git rev-parse HEAD` == `git rev-parse origin/master`
#       puts "WARNING: HEAD is not the same as origin/master"
#       puts "Run `git push` to sync changes."
#       exit
#     end
#   end
#   before "deploy", "deploy:check_revision"
# end



# config/deploy.rb
set :stages, %w(production staging development)
require "bundler/capistrano"
require 'capistrano/ext/multistage'

# Add RVM's lib directory to the load path.
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

# Load RVM's capistrano plugin.    
require "rvm/capistrano"

set :rvm_ruby_string, '2.0.0'
set :rvm_type, :user  # Don't use system-wide RVM

set :scm,             :git
set :repository,      "git@github.com:UlricToinon/Toinon.git"
set :branch,          "origin/master"
set :migrate_target,  :current
set :ssh_options,     { :forward_agent => true }
set :deploy_to,       "/home/deploy/webapps/toinon"
set :normalize_asset_timestamps, false

set :user,            "deploy"
set :group,           "deploy"
set :use_sudo,        false

set(:latest_release)  { fetch(:current_path) }
set(:release_path)    { fetch(:current_path) }
set(:current_release) { fetch(:current_path) }

set(:current_revision)  { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:latest_revision)   { capture("cd #{current_path}; git rev-parse --short HEAD").strip }
set(:previous_revision) { capture("cd #{current_path}; git rev-parse --short HEAD@{1}").strip }

ssh_options[:forward_agent] = true
default_run_options[:pty] = true

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

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/toinon"
    sudo "ln -nfs /home/deploy/unicorn/unicorn_init_toinon.sh /etc/init.d/unicorn_toinon"
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.yml"), "#{shared_path}/config/database.yml"
    puts "Now edit the config files in #{shared_path}."
  end
  after "deploy:setup", "deploy:setup_config"

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
    run "cd #{current_path}; git fetch origin; git reset --hard #{branch}"
    finalize_update
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

  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # mkdir -p is making sure that the directories are there for some SCM's that don't
    # save empty folders
    run <<-CMD
      rm -rf #{latest_release}/log #{latest_release}/public/system #{latest_release}/tmp/pids &&
      mkdir -p #{latest_release}/public &&
      mkdir -p #{latest_release}/tmp &&
      ln -s #{shared_path}/log #{latest_release}/log &&
      ln -s #{shared_path}/system #{latest_release}/public/system &&
      ln -s #{shared_path}/pids #{latest_release}/tmp/pids &&
      ln -sf #{shared_path}/database.yml #{latest_release}/config/database.yml
    CMD

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = fetch(:public_children, %w(images stylesheets javascripts)).map { |p| "#{latest_release}/public/#{p}" }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  desc "Zero-downtime restart of Unicorn"
  task :restart, :except => { :no_release => true } do
    run "kill -s USR2 `cat /home/deploy/webapps/toinon/shared/pids/unicorn.toinon.pid`"
  end

  desc "Start unicorn"
  task :start, :except => { :no_release => true } do
    run "cd #{current_path} ; bundle exec unicorn_rails -c config/unicorn.rb -D -E production"
  end

  desc "Stop unicorn"
  task :stop, :except => { :no_release => true } do
    run "kill -s QUIT `cat /home/deploy/webapps/toinon/shared/pids/unicorn.toinon.pid`"
  end

  desc "reload the database with seed data"
  task :seed do
    run "cd #{current_path}; bundle exec rake db:seed RAILS_ENV=#{rails_env}"
  end

  namespace :rollback do
    desc "Moves the repo back to the previous version of HEAD"
    task :repo, :except => { :no_release => true } do
      set :branch, "HEAD@{1}"
      deploy.default
    end

    desc "Rewrite reflog so HEAD@{1} will continue to point to at the next previous release."
    task :cleanup, :except => { :no_release => true } do
      run "cd #{current_path}; git reflog delete --rewrite HEAD@{1}; git reflog delete --rewrite HEAD@{1}"
    end

    desc "Rolls back to the previously deployed version."
    task :default do
      rollback.repo
      rollback.cleanup
    end
  end
end

def run_rake(cmd)
  run "cd #{current_path}; #{rake} #{cmd}"
end