# frozen_string_literal: true

module ::DiscourseDynamicGroups
  class RulesController < ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_admin

    def show
      render json: { success: true, errors: [] }
    end

    def update
      group = Group.find_by(name: params[:group_name])

      raise Discourse::NotFound unless group
      raise Discourse::InvalidAccess if group.automatic? && group.custom_fields[:dynamic_rule].nil?

      begin
        rule = params[:dynamic_rule].strip
        if rule.empty?
          group.custom_fields.delete(:dynamic_rule)
          group.custom_fields.delete_if { |key, _| key.start_with?("depends_on") }
          group.save_custom_fields
          group.automatic = false
          group.save
          render json: { success: true, errors: [] }
        else
          group.set_dynamic_rule(rule)
          group.automatic = true
          group.save
          render json: { success: true, errors: [] }
        end
      rescue => e
        render_json_error(e.message)
      end
    end
  end
end

