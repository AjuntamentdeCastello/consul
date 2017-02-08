module Abilities
  class Common
    include CanCan::Ability

    def initialize(user)




      self.merge Abilities::Everyone.new(user)

      can [:read, :update], User, id: user.id

      can :read, Debate
      can :update, Debate do |debate|
        debate.editable_by?(user)
      end

      can :read, Proposal
      can :update, Proposal do |proposal|
        proposal.editable_by?(user)
      end
      can [:retire_form, :retire], Proposal, author_id: user.id

      can :create, Comment
      can :create, Debate
      can :create, Proposal

      can :suggest, Debate
      can :suggest, Proposal

      can [:flag, :unflag], Comment
      cannot [:flag, :unflag], Comment, user_id: user.id

      can [:flag, :unflag], Debate
      cannot [:flag, :unflag], Debate, author_id: user.id

      can [:flag, :unflag], Proposal
      cannot [:flag, :unflag], Proposal, author_id: user.id

      unless user.organization?
        can :vote, Debate
        can :vote, Comment
      end

      if user.level_two_or_three_verified?
        can :vote, Proposal
        can :vote_featured, Proposal
        can :vote, SpendingProposal
        can :create, SpendingProposal

        # TODO: no dejar crear si ya se ha creado
        # if user
        #    .budget_investments
        #    .includes(:budget)
        #    .where(budgets: { phase: 'accepting'})
        #    .where(budget_investments: { hidden_at: nil}).count < 1

          can :create, Budget::Investment,               budget: { phase: "accepting" }
        # end

        budgets_current = Budget.includes(:investments).where(phase: 'selecting')
        investment_ids = budgets_current.map { |b| b.investment_ids }.flatten
        if user.votes.for_type(Budget::Investment).where(votable_id: investment_ids).size <= 3
          can :vote,   Budget::Investment,               budget: { phase: "selecting" }
        end
        can [:show, :create], Budget::Ballot,          budget: { phase: "balloting" }
        can [:create, :destroy], Budget::Ballot::Line, budget: { phase: "balloting" }

        can :create, DirectMessage
        can :show, DirectMessage, sender_id: user.id
      end

      can [:create, :show], ProposalNotification, proposal: { author_id: user.id }

      can :create, Annotation
      can [:update, :destroy], Annotation, user_id: user.id
    end
  end
end
