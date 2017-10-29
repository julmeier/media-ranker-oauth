class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :work, counter_cache: :vote_count

  validates :user, uniqueness: { scope: :work, message: "has already voted for this work" }
  validate :user_cannot_vote_for_their_work
end

def user_cannot_vote_for_their_work
  if self.work.user_id == self.user.id
    puts "self.work.user_id = #{self.work.user_id}"
    errors.add(:user, "User cannot vote for their own work")
    return false
  else
    return true
  end
end
