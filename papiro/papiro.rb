require 'sinatra'
require 'twitter'
require 'magick_title'
require 'omniauth-twitter'

# change the following API keys
# https://apps.twitter.com

CONSUMER_KEY = ""
CONSUMER_SECRET = ""

configure do
  set :client, nil
  enable :sessions
end

use OmniAuth::Builder do
  provider :twitter, CONSUMER_KEY, CONSUMER_SECRET
end

# request twitter authentication
get '/login' do
  redirect to("/auth/twitter")
end

# after twitter authenticates the account goes back to this page
get '/auth/twitter/callback' do
  env['omniauth.auth'] ? session[:admin] = true : halt(401,'Not Authorized')

  settings.client = Twitter::REST::Client.new do |config|
    config.consumer_key       = CONSUMER_KEY
    config.consumer_secret    = CONSUMER_SECRET
    config.oauth_token        = env['omniauth.auth']['credentials']['token']
    config.oauth_token_secret = env['omniauth.auth']['credentials']['secret']
  end

  redirect "/"
end

get '/auth/failure' do
  params[:message]
end

get '/logout' do
  session[:admin] = false

  "successfully logged out!"
end

get '/' do
  unless session[:admin]
    redirect '/login'
  end

	erb :index
end

post '/papira' do
	@text = params[:text]

	erb :generator
end
