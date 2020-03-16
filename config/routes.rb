Rails.application.routes.draw do
  get '/', to: 'covid#show', as: :show_covid
end
