# frozen_string_literal: true

module DiscourseDynamicGroups
  class MembershipEvaluator
    def determine_group_membership(user, group)
      # get rules for group
      # run rule engine
      # add or remove user from group if necessary
    end

    def evaluate_dependent_groups(user, group)
      # get the dependent groups for this group
      # loop through them
      # call determine_group_membership
    end

    def evaluate_group(group)
      # used when a new rule is added
      # get all users that belong to one of the groups mentioned in the rule
      # loop through all those users
      # call determine_group_membership
    end
  end
end
    