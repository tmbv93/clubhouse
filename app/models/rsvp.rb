class Rsvp < ApplicationRecord
  include UsesGuid

  belongs_to :invite, required: false, touch: true
  belongs_to :meeting, required: true

  has_many :survey_responses, dependent: :destroy, class_name: "Surveys::Response"

  enum :answer, { unanswered: "unanswered", yes: "yes", no: "no" }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email" }, if: -> { invite.self_signup? }
  validates :full_name, presence: true, if: -> { invite.self_signup? }

  accepts_nested_attributes_for :survey_responses

  def anything_to_fill_out?
    yes? || no? || invite.nil? || invite.needs_info?
  end

  def to_param
    guid
  end
end
