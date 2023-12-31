# frozen_string_literal: true

# name: discourse-dynamic-groups
# about: Automatically populate groups
# version: 1.0
# authors: richard@communiteq.com
# url: https://github.com/communiteq/discourse-dynamic-groups

enabled_site_setting :dynamic_groups_enabled

module ::DiscourseDynamicGroups
  PLUGIN_NAME = "discourse-dynamic-groups"
end

require_relative "lib/discourse_dynamic_groups/engine"

after_initialize do
  require_relative "lib/discourse_dynamic_groups/rule_engine"
  require_relative "lib/discourse_dynamic_groups/membership_evaluator"
  require_relative "lib/discourse_dynamic_groups/utils"

  class ::Badge
    def get_depending_group_ids
      deps = GroupCustomField.where(name: "depends_on_badge:#{self.id}").pluck(:group_id)
    end
  end

  class ::Group
    def dynamic_rule
      self.custom_fields[:dynamic_rule] || nil
    end

    def set_dynamic_rule(rule)
      self.set_dependant_info(rule)
      self.custom_fields[:dynamic_rule] = rule
      self.save_custom_fields
      # re-evaluate the rule for all users
      # hmm maybe only the users with depending groups if there is no NOT
    end

    def set_dependant_info(rule)
      engine = ::DiscourseDynamicGroups::RuleEngine.new
      deps = engine.get_deps_for_rule(rule).map { |el| "depends_on_#{el}" }
      existing_deps = GroupCustomField.where(group_id: self.id).where("name like 'depends_on_%'").pluck(:name)
      add_deps = deps - existing_deps
      add_deps.each do |dep|
        self.custom_fields[dep] = true
      end
      del_deps = existing_deps - deps
      del_deps.each do |dep|
        self.custom_fields.delete(dep)
      end
      self.save_custom_fields
    end

    def get_depending_group_ids
      deps = GroupCustomField.where(name: "depends_on_#{self.name.downcase}").pluck(:group_id)
    end

    # returns true if user was added, false if user was removed, nil if it stayed the same
    def evaluate_membership(user)
      engine = ::DiscourseDynamicGroups::RuleEngine.new
      membership = engine.evaluate_rule(user, dynamic_rule)
      is_member = GroupUser.where(user_id: user.id).where(group_id: self.id).count > 0
      if is_member && !membership
        self.remove(user)
        false
      end
      if !is_member && membership
        self.add(user)
        true
      end
    end
  end

  add_to_serializer(:group_show, :dynamic_rule, include_condition: -> { object.dynamic_rule.present? && scope.is_admin? }) do
    object.dynamic_rule
  end

  DiscourseEvent.on(:user_badge_granted) do |badge_id, user_id|
    group_ids = Badge.find(badge_id).get_depending_group_ids
    group_ids.each do |group_id|
      Group.find(group_id).evaluate_membership(User.find(user_id))
    end
  end
  
  DiscourseEvent.on(:user_badge_revoked) do |params|
    user_badge = params[:user_badge]
    group_ids = Badge.find(user_badge.badge_id).get_depending_group_ids
    group_ids.each do |group_id|
      Group.find(group_id).evaluate_membership(User.find(user_badge.user_id))
    end
  end

  DiscourseEvent.on(:user_added_to_group) do |user, group|
    group_ids = group.get_depending_group_ids
    group_ids.each do |group_id|
      Group.find(group_id).evaluate_membership(User.find(user.id))
    end
  end

  DiscourseEvent.on(:user_removed_from_group) do |user, group|
    group_ids = group.get_depending_group_ids
    group_ids.each do |group_id|
      Group.find(group_id).evaluate_membership(User.find(user.id))
    end
  end

end
