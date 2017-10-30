class UsersController < ApplicationController
  def index
    @users = User.all
    # if @users.length == 0
    #
  end

  def show
    @user = User.find_by(id: params[:id])
    render_404 unless @user
  end
end
