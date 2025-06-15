# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :v1 do
    post 'user/check_status', to: 'user#check_status'
  end
end
