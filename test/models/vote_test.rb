require 'test_helper'

describe Vote do
  describe "relations" do
    it "has a user" do
      v = votes(:one)
      v.must_respond_to :user
      v.user.must_be_kind_of User
    end

    it "has a work" do
      v = votes(:one)
      v.must_respond_to :work
      v.work.must_be_kind_of Work
    end
  end

  describe "validations" do
    let (:user1) { User.create(username: 'chris', uid: 101, provider: "github") }
    let (:user2) { User.create(username: 'charles', uid: 200, provider: "github") }
    let (:user3) { User.create(username: 'kari', uid: 300, provider: "github") }
    let (:work1) { Work.create(category: 'book', title: 'House of Leaves', user_id: user1.id) }
    let (:work2) { Work.create(category: 'book', title: 'For Whom the Bell Tolls', user_id: user2.id) }
    let (:work3) { Work.create(category: 'book', title: 'The Tao of Poo', user_id: user3.id) }

    it "allows one user to vote for different works that aren't theirs" do
      vote1 = Vote.new(user: user1, work: work2)
      vote1.save
      # puts "**********"
      # ap vote1
      # puts "**********"

      vote1.valid?.must_equal true
      vote2 = Vote.new(user: user1, work: work3)
      vote2.save
      # puts "**********"
      # ap vote2.errors
      vote2.valid?.must_equal true
      # puts "**********"
      # ap vote2.errors
    end

    it "allows multiple users to vote for a work" do
      vote1 = Vote.new(user: user2, work: work1)
      vote1.save!
      vote2 = Vote.new(user: user3, work: work1)
      vote2.valid?.must_equal true
    end

    it "doesn't allow the same user to vote for the same work twice" do
      vote1 = Vote.new(user: user1, work: work2)
      vote1.save!
      vote2 = Vote.new(user: user1, work: work2)
      vote2.valid?.must_equal false
      vote2.errors.messages.must_include :user
    end

    it "doesn't allow users to vote for their own works" do
      vote1 = Vote.new(user: user1, work: work1)
      vote1.valid?.must_equal false
      vote1.errors.messages.must_include :user
    end
  end
end
