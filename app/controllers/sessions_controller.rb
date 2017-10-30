class SessionsController < ApplicationController
  skip_before_action :require_login

  def login_form
  end
  #
  # def login
  #   username = params[:username]
  #   if username and user = User.find_by(username: username)
  #     session[:user_id] = user.id
  #     flash[:status] = :success
  #     flash[:result_text] = "Successfully logged in as existing user #{user.username}"
  #   else
  #     user = User.new(username: username)
  #     if user.save
  #       session[:user_id] = user.id
  #       flash[:status] = :success
  #       flash[:result_text] = "Successfully created new user #{user.username} with ID #{user.id}"
  #     else
  #       flash.now[:status] = :failure
  #       flash.now[:result_text] = "Could not log in"
  #       flash.now[:messages] = user.errors.messages
  #       render "login_form", status: :bad_request
  #       return
  #     end
  #   end
  #   redirect_to root_path
  # end

  def logout
    session[:user_id] = nil
    flash[:status] = :success
    flash[:result_text] = "Successfully logged out"
    redirect_to root_path
  end

  def login
    @auth_hash = request.env['omniauth.auth']
    @user = User.find_by(uid: @auth_hash['uid'], provider: @auth_hash['provider'])
		puts @auth_hash

		if @user
			session[:user_id] = @user.id
			flash[:success] = "#{@user.username} is logged in"
      redirect_to root_path
		else
			@user = User.new uid: @auth_hash['uid'], provider: @auth_hash['provider'], username: @auth_hash['info']['nickname'], email: @auth_hash['info']['email']
			#you can do a lot more like get people's avatar from github

				#save the new user in the database. This might not work if the omniauth didnt give info and didn't give us the values, or database is down.
				if @user.save
					session[:user_id] = @user.id
					flash[:success] = "Welcome #{@user.username}"
          redirect_to root_path
				else
					flash[:error] = "Unable to save user! Invalid authentication. You may be missing a data field."
          redirect_to root_path
				end

		end
  end


end
