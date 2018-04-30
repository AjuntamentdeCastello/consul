class Budget
  class Ballot
    class Line < ActiveRecord::Base
      belongs_to :ballot
      belongs_to :investment, counter_cache: :ballot_lines_count
      belongs_to :heading
      belongs_to :group
      belongs_to :budget

      validates :ballot_id, :investment_id, :heading_id, :group_id, :budget_id, presence: true

      validate :check_selected
      validate :check_sufficient_funds
      validate :check_valid_heading

      scope :by_investment, ->(investment_id) { where(investment_id: investment_id) }

      before_validation :set_denormalized_ids
      after_create :update_cached_ballots_up
      after_destroy :update_cached_ballots_up

      def check_sufficient_funds
        errors.add(:money, "insufficient funds") if ballot.amount_available(investment.heading) < investment.price.to_i
      end

      def check_valid_heading
        return if ballot.valid_heading?(heading)
        errors.add(:heading, "This heading's budget is invalid, or a heading on the same group was already selected")
      end

      def check_selected
        errors.add(:investment, "unselected investment") unless investment.selected?
      end

      private

        def set_denormalized_ids
          self.heading_id ||= investment.try(:heading_id)
          self.group_id   ||= investment.try(:group_id)
          self.budget_id  ||= investment.try(:budget_id)
        end

        def update_cached_ballots_up
          investment.update_cached_ballots_up
        end
    end
  end
end

# == Schema Information
#
# Table name: budget_ballot_lines
#
#  id            :integer          not null, primary key
#  ballot_id     :integer
#  investment_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  budget_id     :integer
#  group_id      :integer
#  heading_id    :integer
#
