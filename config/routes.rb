Discourse::Application.routes.draw do
  get "/g/:group_name/dynamic" => "discourse_dynamic_groups/rules#show"
  post "/g/:group_name/dynamic" => "discourse_dynamic_groups/rules#update"
end