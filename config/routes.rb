Rails.application.routes.draw do
  resources :users
  resources :listings
  
   get '/' => 'main#home'
   get '/signup' => 'users#new'
   get '/login' => 'users#login'

   post '/login' => 'users#login'

   delete '/logout' => 'users#destroy'
   
end
