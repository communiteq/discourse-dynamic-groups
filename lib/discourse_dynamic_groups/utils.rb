# frozen_string_literal: true

module DiscourseDynamicGroups
  class Utils
    # returns badge.id if slug_or_id is a valid slug or a valid id
    def self.find_badge_id(slug_or_id)
      if numeric?(slug_or_id)
        return Badge.exists?(id: slug_or_id.to_i) ? slug_or_id.to_i : false
      end

      badge = Badge.all.detect { |b| b.slug == slug_or_id }
      badge ? badge.id : false
    end

    def self.numeric?(value)
      value.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil
    end

    # for any badge:slug changes to badge:id
    # returns false if slug or id do not exist
    # for any group changes to lowercase
    # returns false if group does not exist

    def self.get_normalized_name(group_or_badge)
      if group_or_badge.start_with?("badge:")
        badge_slug_or_id = group_or_badge.split(":").last
        badge_id = self.find_badge_id(badge_slug_or_id)
        badge_id ? "badge:#{badge_id}" : false
      else
        group_name = group_or_badge.downcase
        current_group_names = Group.pluck(:name).map(&:downcase)
        current_group_names.include?(group_name) ? group_name : false
      end
    end

  end
end
