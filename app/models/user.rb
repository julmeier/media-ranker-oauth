class User < ApplicationRecord
  has_many :votes
  has_many :works
  has_many :ranked_works, through: :votes, source: :work

  validates :username, uniqueness: true, presence: true
end
