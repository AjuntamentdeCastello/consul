class Poll
  class Voter < ActiveRecord::Base

    VALID_ORIGINS = %w{web booth}.freeze

    belongs_to :poll
    belongs_to :user
    belongs_to :geozone
    belongs_to :booth_assignment
    belongs_to :officer_assignment
    belongs_to :officer

    validates :poll_id, presence: true
    validates :user_id, presence: true

    validates :document_number, presence: true, uniqueness: { scope: [:poll_id, :document_type], message: :has_voted }
    validates :origin, inclusion: { in: VALID_ORIGINS }

    before_validation :set_demographic_info, :set_document_info

    scope :web,   -> { where(origin: 'web') }
    scope :booth, -> { where(origin: 'booth') }

    def set_demographic_info
      return if user.blank?

      self.gender  = user.gender
      self.age     = user.age
      self.geozone = user.geozone
    end

    def set_document_info
      return if user.blank?

      current_user = User.with_hidden
                         .where(document_number: self.document_number)
                         .first
      unless current_user&.paranoia_destroyed?
        self.document_type   = user.document_type
        self.document_number = user.document_number
      end
    end

    private

      def in_census?
        census_api_response.valid?
      end

      def census_api_response
        @census_api_response ||= CensusCaller.new.call(document_type, document_number)
      end

      def fill_stats_fields
        if in_census?
          self.gender = census_api_response.gender
          self.geozone_id = Geozone.select(:id).where(census_code: census_api_response.district_code).first.try(:id)
          self.age = voter_age(census_api_response.date_of_birth)
        end
      end

      def voter_age(dob)
        if dob.blank?
          nil
        else
          now = Date.current
          now.year - dob.year - (now.month > dob.month || (now.month == dob.month && now.day >= dob.day) ? 0 : 1)
        end
      end

  end
end

# == Schema Information
#
# Table name: poll_voters
#
#  id                    :integer          not null, primary key
#  document_number       :string
#  document_type         :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  poll_id               :integer          not null
#  booth_assignment_id   :integer
#  age                   :integer
#  gender                :string
#  geozone_id            :integer
#  answer_id             :integer
#  officer_assignment_id :integer
#  user_id               :integer
#  origin                :string
#  officer_id            :integer
#  token                 :string
#
