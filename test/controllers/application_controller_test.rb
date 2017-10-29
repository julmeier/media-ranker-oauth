require 'test_helper'

describe ApplicationController do
  it "should find an existing user if user is logged in" do
    start_count = User.count
    user = users(:dan)

    login(user, :github)

    # must_respond_with :redirect
    # must_redirect_to root_path
    User.count.must_equal start_count
    session[:user_id].must_equal user.id

  end



end
