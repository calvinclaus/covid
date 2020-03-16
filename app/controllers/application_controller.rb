class ApplicationController < ActionController::Base
  layout :layout

  def after_sign_in_path_for(resource)
    if resource.class.name == "Admin"
      backend_root_path
    else
      frontend_root_path
    end
  end

  def after_sign_out_path_for(resource)
    if resource == :admin
      new_admin_session_path
    else
      frontend_root_path
    end
  end

  private

  def layout
    if devise_controller? && devise_mapping.name == :admin
      "backend"
    else
      "frontend"
    end
  end
end
