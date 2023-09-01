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
      engine = ::DiscourseDynamicGroups::RuleEngine.new
      user_ids = engine.magical_tree(group.dynamic_rule)
      current_users = group.users.pluck(:id)
      to_be_removed = current_users - user_ids
      to_be_added = user_ids - current_users
      User.where(id: to_be_removed).each do |user|
        group.remove(user)
      end
      User.where(id: to_be_added).each do |user}
        group.add(user)
      end
    end
  end
end
    