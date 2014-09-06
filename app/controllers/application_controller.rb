class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :authenticate!

  def authenticate!
    login = authenticate_or_request_with_http_basic do |login, password|
    login == "toinon" && password == "toioui"
  end
    session[:login] = login
  end
end
