class Follower < ApplicationRecord
    belongs_to :users_record
    validates :followerId,:userId, presence: true, on: :create
end
