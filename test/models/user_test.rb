require 'test_helper'

describe User do
  describe "relations" do
    it "has a list of votes" do
      dan = users(:dan)
      dan.must_respond_to :votes
      dan.votes.each do |vote|
        vote.must_be_kind_of Vote
      end
    end

    it "has a list of ranked works" do
      dan = users(:dan)
      dan.must_respond_to :ranked_works
      dan.ranked_works.each do |work|
        work.must_be_kind_of Work
      end
    end
  end

  describe "validations" do
    it "requires a username" do
      user = User.new
      user.valid?.must_equal false
      user.errors.messages.must_include :username
    end

    it "requires a unique username" do
      username = "test username"
      user1 = User.new(username: username, uid: 500, provider: "github")

      # This must go through, so we use create!
      user1.save!

      user2 = User.new(username: username, uid: 600, provider: "github")
      result = user2.save
      result.must_equal false
      user2.errors.messages.must_include :username
    end

    it "requires a uid and a provider for logged in users" do
      username = "test username"
      user1 = User.new(username: username)
      user1.valid?.must_equal false
      user1.uid = 500
      user1.provider = "github"
      user1.save
      user1.valid?.must_equal true
    end

    it "requires that the uid and provider combination is unique" do
      user1 = User.create(username: "test_username1", uid: 500, provider: "github")
      user1.valid?.must_equal true
      user2 = User.create(username: "test_username2", uid: 500, provider: "google")
      user2.valid?.must_equal true
      user3 = User.new(username: "test_username3", uid: 500, provider: "github")
      user3.valid?.must_equal false
      proc { user3 = User.create!(username: "test_username3", uid: 500, provider: "github")}.must_raise ActiveRecord::RecordInvalid
    end


  end
end
