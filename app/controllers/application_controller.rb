class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_filter :authenticate!

  def authenticate!
    login = authenticate_or_request_with_http_basic do |login, password|
      login == "toinon" && password == "toioui"
    end
    session[:login] = login
  end
end
