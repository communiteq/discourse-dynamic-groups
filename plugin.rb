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
  class ::Group
    def dynamic_rule
      self.custom_fields[:dynamic_rule] || nil
    end

    def set_dynamic_rule(rule)
      self.custom_fields[:dynamic_rule] = rule
      self.save_custom_fields
    end
  end

  add_to_serializer(:group_show, :dynamic_rule, include_condition: -> { object.dynamic_rule.present? && scope.is_admin? }) do
    object.dynamic_rule
  end

  DiscourseEvent.on(:user_badge_granted) do |badge_id, user_id|
  end
  
  DiscourseEvent.on(:user_badge_revoked) do |user_badge|
  end

  DiscourseEvent.on(:user_added_to_group) do |user, group|
  end

  DiscourseEvent.on(:user_removed_from_group) do |user, group|
  end

end
