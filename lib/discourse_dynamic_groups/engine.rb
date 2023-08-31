# frozen_string_literal: true

module ::DiscourseDynamicGroups
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseDynamicGroups
    end
  end