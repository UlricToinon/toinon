
server "prod.toinon.re", :app, :web, :db, primary: true
set :rails_env, 'production'

set :application, "toinon"
set :user, "toinon"
set :port, 22
set :deploy_to, "/home/#{user}/sites/#{application}_production"
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:UlricToinon/#{application}.git"
set :branch, "master"