Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  post '/create', :to=> 'account#CreateUser', as: 'create'
  post '/login', :to=> 'account#LoginUser', as: 'LoginUser'
  get '/CreateFollow', :to=> 'account#CreateFollowing', as: 'CreateFollow' 
  get '/follows', :to=> 'account#Listfollowing', as: 'follows'
  get '/followers', :to=> 'account#Listfollowers', as: 'followers'
  get '/unfollow', :to=> 'account#unfollowing', as: 'unfollow'
  get '/usernameList', :to=> 'account#existingUserName', as: 'usernameList'
  get '/viewProfile', :to=> 'account#viewProfile', as: 'viewProfile'
  get '/updateProfile', :to=> 'account#updateProfile', as: 'updateProfile'
  get '/updatePassword', :to=> 'account#updatePassword', as: 'updatePassword'
  get '/removeFollow', :to=> 'account#unfollowing', as: 'removeFollow'

  post '/tweet', :to=> 'account#CreateTweet', as: 'tweet'
  get '/viewTweet', :to=> 'account#loadTweets', as: 'viewTweet'
end
