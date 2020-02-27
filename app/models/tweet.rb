class Tweet < ApplicationRecord
    belongs_to :user_record
    validates :tweetInfo,:userId, presence: true, on: :create
end
