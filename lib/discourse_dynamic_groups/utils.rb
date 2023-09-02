# frozen_string_literal: true

module DiscourseDynamicGroups
  class Utils
    @@badges_by_slug = nil
    @@group_names = nil
    
    Group.pluck(:name).map { |name| name.downcase }
    # returns badge.id if slug_or_id is a valid slug or a valid id
    def self.find_badge_id(slug_or_id)
      if numeric?(slug_or_id)
        return Badge.exists?(id: slug_or_id.to_i) ? slug_or_id.to_i : false
      end

      populate_badges_by_slug unless @@badges_by_slug
      @@badges_by_slug[slug_or_id] || false
    end

    def self.populate_badges_by_slug
      @@badges_by_slug = {}
  
      Badge.pluck(:id).each do |badge_id|
        badge = Badge.find(badge_id)
        @@badges_by_slug[badge.slug] = badge.id
      end
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
        badge_slug = group_or_badge.split(":").last
        badge_id = self.find_badge_id(badge_slug)
        if badge_id
          "badge:" + badge_id.to_s
        else
          false
        end
      else
        group_name = group_or_badge.downcase
        @@group_names ||= Group.pluck(:name).map { |name| name.downcase } 
        return (@@group_names.include? group_name) ? group_name : false
      end
    end
    
  end
end
