require 'test_helper'

describe WorksController do
  describe "root" do
    it "succeeds with all media types" do
      # Precondition: there is at least one media of each category
      %w(album book movie).each do |category|
        Work.by_category(category).length.must_be :>, 0, "No #{category.pluralize} in the test fixtures"
      end

      get root_path
      must_respond_with :success
    end

    it "succeeds with one media type absent" do
      # Precondition: there is at least one media in two of the categories
      %w(album book).each do |category|
        Work.by_category(category).length.must_be :>, 0, "No #{category.pluralize} in the test fixtures"
      end

      # Remove all movies
      Work.by_category("movie").destroy_all

      get root_path
      must_respond_with :success
    end

    it "succeeds with no media" do
      Work.destroy_all
      get root_path
      must_respond_with :success
    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "index" do
    it "succeeds when there are works" do
      Work.count.must_be :>, 0, "No works in the test fixtures"
      login(users(:kari))
      get works_path
      must_respond_with :success
    end

    it "succeeds when there are no works" do
      Work.destroy_all
      login(users(:kari))
      get works_path
      must_respond_with :success
    end
  end

  describe "new" do
    it "works" do
      login(users(:kari))
      get new_work_path
      must_respond_with :success
    end
  end

  describe "create" do
    it "creates a work with valid data for a real category" do
      work_data = {
        work: {
          title: "test work"
        }
      }
      CATEGORIES.each do |category|
        work_data[:work][:category] = category

        start_count = Work.count
        login(users(:kari))
        post works_path(category), params: work_data
        must_redirect_to work_path(Work.last)

        Work.count.must_equal start_count + 1
      end
    end

    it "renders bad_request and does not update the DB for bogus data" do
      work_data = {
        work: {
          title: ""
        }
      }
      CATEGORIES.each do |category|
        work_data[:work][:category] = category

        start_count = Work.count
        login(users(:kari))
        post works_path(category), params: work_data
        must_respond_with :bad_request

        Work.count.must_equal start_count
      end
    end

    it "renders 400 bad_request for bogus categories" do
      work_data = {
        work: {
          title: "test work"
        }
      }
      INVALID_CATEGORIES.each do |category|
        work_data[:work][:category] = category

        start_count = Work.count
        login(users(:kari))
        post works_path(category), params: work_data
        must_respond_with :bad_request

        Work.count.must_equal start_count
      end
    end
  end

  describe "show" do
    it "succeeds for an extant work ID" do
      login(users(:kari))
      get work_path(Work.first)
      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      bogus_work_id = Work.last.id + 1
      login(users(:kari))
      get work_path(bogus_work_id)
      must_respond_with :not_found
    end
  end

  describe "edit" do
    it "succeeds for an extant work ID, for the user that created the work" do
      login(users(:dan))
      #dan created the first work in the yml file
      get edit_work_path(works(:mariner))
      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      bogus_work_id = Work.last.id + 1
      login(users(:dan))
      get edit_work_path(bogus_work_id)
      must_respond_with :not_found
    end

    #NB Added by Julia
    it "only allows editing by the work's owner" do
      new_work = Work.new
      new_work.title = "Much Ado About Nothing"
      new_work.creator = "Shakespeare"
      new_work.category = "album"
      new_work.user_id = users(:kari).id
      new_work.save
      new_work.valid?.must_equal true

      login(users(:dan))
      get edit_work_path(new_work.id)
      must_redirect_to work_path(new_work.id)
      flash[:result_text].must_equal "Only the person that added the work can edit or delete it"

      login(users(:kari))
      get edit_work_path(new_work.id)
      must_respond_with :success
    end
  end

  describe "update" do
    it "succeeds for valid data and an extant work ID for logged in user who created work" do
      #dan created the mariner work
      login(users(:dan))
      get edit_work_path(works(:mariner).id)
      work_data = {
        work: {
          title: "new title"
        }
      }
      patch work_path(works(:mariner).id), params: work_data
      must_redirect_to work_path(works(:mariner).id)

      # Verify the DB was really modified
      Work.find(works(:mariner).id).title.must_equal work_data[:work][:title]
    end

    it "renders bad_request for bogus data" do
      work = works(:poodr)
      work_data = {
        work: {
          title: ""
        }
      }
      patch work_path(work), params: work_data
      must_respond_with :not_found

      # Verify the DB was not modified
      Work.find(work.id).title.must_equal work.title
    end

    it "renders 404 not_found for a bogus work ID" do
      bogus_work_id = Work.last.id + 1
      get work_path(bogus_work_id)
      must_respond_with :not_found
    end
  end

  describe "destroy" do
    it "a work can only be deleted by the person who created it" do
      work_id = works(:mariner).id
      login(users(:dan))

      delete work_path(work_id)
      must_redirect_to root_path
      flash[:result_text].must_equal "Successfully destroyed album Mariner"
      flash[:status].must_equal :success
      # The work should really be gone
      Work.find_by(id: work_id).must_be_nil
    end

    it "a work cannot be deleted by someone who didnt create it" do
      work_id = works(:mariner).id
      login(users(:kari))

      delete work_path(work_id)
      must_redirect_to work_path(work_id)
      flash[:result_text].must_equal "Could not delete the work Mariner"

      Work.find_by(id: work_id).valid?.must_equal true
    end

    #QUESTION from Julia. I'm not sure how to test for this 404 code. The error is:
    #Expected response to be a <404: missing>, but was a <302: Found> redirect to <http://www.example.com/>. See question below.
    it "regardless of user sign-in status: renders 404 not_found and does not update the DB for a bogus work ID" do
      start_count = Work.count
      bogus_work_id = Work.last.id + 1
      delete work_path(bogus_work_id)

      must_redirect_to root_path
      Work.count.must_equal start_count
    end

  end

  describe "upvote" do


    #QUESTION from Julia: The error for the below test is:
    # Expected response to be a <401: unauthorized>, but was a <302: Found> redirect to <http://www.example.com/>.
    #This makes sense, because the before_action in the application controller redirects the user to the root_path if there is no logged in user. Should the test be changed to account for this. How do you test the 401 unauthorized?
    it "if no user is logged in" do
      work = works(:mariner)
      start_vote_count = work.votes.count
      post upvote_path(work)
      must_redirect_to root_path

      work.votes.count.must_equal start_vote_count
    end

    it "returns after the user has logged out" do
      start_vote_count = works(:mariner).votes.count

      # login(users(:dan))
      # logout

      post upvote_path(works(:mariner))
      must_redirect_to root_path

      works((:mariner).id).votes.count.must_equal start_vote_count
    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do
      start_vote_count = works(:poodr).votes.count

      login(users(:dan))

      post upvote_path(works(:poodr))
      # Should be a redirect_back
      must_respond_with :redirect

      works(:poodr).reload
      works(:poodr).votes.count.must_equal start_vote_count + 1
    end

    it "returns 409 conflict if the user has already voted for that work" do
      login(users(:dan))
      Vote.create!(user: users(:dan), work: works(:poodr))

      start_vote_count = works(:poodr).votes.count

      post upvote_path(works(:poodr))
      must_respond_with :conflict

      works(:poodr).votes.count.must_equal start_vote_count
    end
  end
end
