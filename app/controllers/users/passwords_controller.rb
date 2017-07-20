class Users::PasswordsController < Devise::PasswordsController
  def create
     self.resource = resource_class.send_reset_password_instructions(resource_params)
     yield resource if block_given?
     if successfully_sent?(resource)
       respond_to do |format|
        format.html { respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name)) }
        format.js
       end

     else
       respond_with(resource)
     end
   end
end
