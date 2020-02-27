Rails.application.routes.draw do
  post '/create', :to=> 'account#CreateUser', as: 'create'
  post '/login', :to=> 'account#LoginUser', as: 'LoginUser'
  get '/follow', :to=> 'account#Listfollowing', as: 'follow'
  get '/CreateFollow', :to=> 'account#CreateFollowing', as: 'CreateFollow' 
  get '/follower', :to=> 'account#Listfollowers', as: 'follower'
  get '/CreateFollower', :to=> 'account#CreateFollowers', as: 'CreateFollower'
  get '/UsernameExist', :to=> 'account#existingUserName', as: 'UsernameExist'
  get '/viewProfile', :to=> 'account#viewProfile', as: 'viewProfile'
  get '/updateProfile', :to=> 'account#updateProfile', as: 'updateProfile'

  get '/removeFollower', :to=> 'account#unfollowers', as: 'removeFollower'
  get '/removeFollow', :to=> 'account#unfollowing', as: 'removeFollow'
end
