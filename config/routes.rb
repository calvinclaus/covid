Rails.application.routes.draw do
  get '/', to: 'covid#show', as: :show_covid
  get 'raw_data', to: 'covid#raw_data', as: :raw_data
  post 'create_user', to: 'users#create', as: :create_user
  get 'user_unsubscribe/:id', to: 'users#unsubscribe', as: :unsubscribe_user
  get 'subscriber_count', to: 'users#count', as: :user_count
end
