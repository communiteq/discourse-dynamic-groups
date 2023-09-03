# frozen_string_literal: true

module DiscourseDynamicGroups
  class CycleDetector
    def initialize()
      @adj_list = {}
      @visited = {}
      @recursion_stack = {}
    end
  
    def has_cycle?
      @adj_list.each_key do |vertex|
        if has_cycle_util(vertex)
          return true
        end
      end
      false
    end    

    def add_edge(node, dep)
      @adj_list[node] ||= []
      @adj_list[node] << dep
    end

    # detects if there is a circular dependency
    # also performs syntax checking via get_deps_for_rule
    def detect_graph_loop(group, rule)
      Group.all.each do |g|
        dependencies = GroupCustomField.where(group_id: g.id).where("name like 'depends_on_%'").pluck(:name)
        dependencies.each { |dep| add_edge(g.name.downcase, dep[11..].downcase) } if dependencies
      end
      re = RuleEngine.new
      deps = re.get_deps_for_rule(rule)
      deps.each { |dep| add_edge(group.name.downcase, dep.downcase) } if deps
      if has_cycle?
        return true # has circular deps
      else
        return false # no circular deps
      end
    end
  
    private
  
    def has_cycle_util(vertex)
      return true if @recursion_stack[vertex]
      return false if @visited[vertex]
  
      @visited[vertex] = true
      @recursion_stack[vertex] = true
  
      if @adj_list[vertex]
        @adj_list[vertex].each do |neighbour|
          if has_cycle_util(neighbour)
            return true
          end
        end
      end
  
      @recursion_stack[vertex] = false
      false
    end


  end
end

