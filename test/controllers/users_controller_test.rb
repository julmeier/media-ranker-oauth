require 'test_helper'

describe UsersController do

  describe "logged in users" do
      describe "auth_callback" do
        it "logs in an existing user and redirects to the root route" do
          # Count the users, to make sure we're not (for example) creating
          # a new user every time we get a login request
          start_count = User.count

          # Get a user from the fixtures
          user = users(:kari)

          #added the below two lines to the test_helper file in the login(user) method
          # OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(mock_auth_hash(user))
          # get auth_callback_path(:github)
          login(user)

          must_redirect_to root_path

          # Since we can read the session, check that the user ID was set as expected
          session[:user_id].must_equal user.id

          # Should *not* have created a new user
          User.count.must_equal start_count
        end

        it "creates an account for a new user and redirects to the root route" do
          start_count = User.count
          user = User.new(provider: "github", uid: 99999, username: "test_user", email: "test@user.com")

          # OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(mock_auth_hash(user))
          # get auth_callback_path(:github)
          login(user)

          must_redirect_to root_path

          # Should have created a new user
          User.count.must_equal start_count + 1

          # The new user's ID should be set in the session
          session[:user_id].must_equal User.last.id
        end

        it "redirects to the root path if given invalid user data" do
          start_count = User.count
          #no uid in below user info
          user = User.new(provider: "github", username: "test_user", email: "test@user.com")

          # OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(mock_auth_hash(user))
          # get auth_callback_path(:github)
          login(user)
          must_redirect_to root_path

          User.count.must_equal start_count
        end
    end

    describe "index" do
      it "succeeds with many users" do
        user = User.new(provider: "github", uid: 99999, username: "test_user", email: "test@user.com")
        login(user)
        # Assumption: there are many users in the DB
        User.count.must_be :>, 0

        get users_path
        must_respond_with :success
      end

      it "succeeds with 1 user (yourself)" do
        User.destroy_all # for fk constraint
        before_count = User.count
        user = User.new(provider: "github", uid: 99999, username: "test_user", email: "test@user.com")
        login(user)
        get users_path
        must_respond_with :success
        after_count = User.count
        after_count.must_equal before_count + 1
      end
    end

    describe "show" do
      it "succeeds for an extant user" do
        user = users(:kari)
        # puts "****VOTES"
        # ap user.votes
        user.votes.first.work.publication_year = 1985
        user.votes.first.work.save
        # ap user.votes.first.work
        login(user)
        get user_path(User.first.id)
        must_respond_with :success
      end

      it "renders 404 not_found for a bogus user" do
        user = User.new(provider: "github", uid: 99999, username: "test_user", email: "test@user.com")
        login(user)
        # User.last gives the user with the highest ID
        bogus_user_id = User.last.id + 1
        get user_path(bogus_user_id)
        must_respond_with :not_found
      end
    end
  end

  describe "users that are not logged in (guests)" do
      it "does not allow guests to view the user-show" do
        get user_path(users(:kari).id)
        must_redirect_to root_path
        flash[:result_text].must_equal "You must be logged in to do that"
      end

      it "does not allow guests to view the users-index page" do
        get users_path
        must_redirect_to root_path
        flash[:result_text].must_equal "You must be logged in to do that"
      end

  end
end
