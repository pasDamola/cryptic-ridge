class Following < ApplicationRecord
    belongs_to :users_record, class_name: "UsersRecord", optional: true
    validates :followingId,:userId,:users_record_id, presence: true, on: :create
end
