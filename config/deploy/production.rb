
server "www.toinon.re", :app, :web, :db, primary: true
set :rails_env, 'production'

set :application, "toinon_production"
set :user, "deploy"
set :port, 22
set :deploy_to, "/home/#{user}/sites/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:UlricToinon/Toinon.git"
set :branch, "master"