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

      begin
        group.set_dynamic_rule(params[:dynamic_rule])
        render json: { success: true, errors: [] }
      rescue => e
        render_json_error(e.message)
      end
    end
  end
end

