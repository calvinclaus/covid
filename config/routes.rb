Rails.application.routes.draw do
  get '/', to: 'covid#show', as: :show_covid
  get 'raw_data', to: 'covid#raw_data', as: :raw_data
end
