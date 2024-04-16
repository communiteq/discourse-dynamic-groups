# frozen_string_literal: true

module DiscourseDynamicGroups

  class Node
    attr_accessor :left, :right, :value

    def initialize(value, operator = nil)
      @value = value
      @operator = operator
      @left = nil
      @right = nil
    end

    def leaf?
      !@operator
    end

    def operator
      @operator
    end
  end


  class RuleEngine
    def tokenize(expression)
      tokens = expression.downcase.scan(/AND|OR|NOT|\(|\)|[a-z_0-9\-]+(?:\:[a-z_0-9\-]+)?/)

      tokens.map do |token|
        case token
        when 'AND', 'OR', 'NOT', 'and', 'or', 'not'
          token.upcase.to_sym
        when '('
          "LBRACKET".to_sym
        when ')'
          "RBRACKET".to_sym
        else
          normalized_token = Utils.get_normalized_name(token)
          if normalized_token
            normalized_token
          else
            raise "Unknown keyword, group or badge: '#{token}'"
          end
        end
      end
    end

    def shunting_yard(tokens)
      output = []
      operators = []

      tokens.each do |token|
        case token
        when String
          output << token
        when :NOT
          operators << token
        when :AND, :OR
          #if operators.last && [:AND, :OR, :NOT].include?(operators.last)
          #  raise "Consecutive operators detected: ... #{operators.last} #{token} ..."
          #end

          while operators.any? && (operators.last == :AND || operators.last == :NOT)
            output << operators.pop
          end
          operators << token
        when :LBRACKET
          operators << token
        when :RBRACKET
          if operators.empty?
            raise "Mismatched parentheses detected: no matching open parenthesis."
          end

          while operators.last != :LBRACKET
            output << operators.pop
          end
          operators.pop
        end
      end

      if operators.include?(:LBRACKET)
        raise "Mismatched parentheses detected: no matching close parenthesis."
      end

      while operators.any?
        output << operators.pop
      end

      output
    end

    def evaluate_postfix(postfix, true_vars)
      stack = []

      postfix.each do |token|
        case token
        when String
          stack << (true_vars.include?(token) ? true : false)
        when :NOT
          operand = stack.pop
          stack << !operand
        when :AND
          right = stack.pop
          left = stack.pop
          stack << (left && right)
        when :OR
          right = stack.pop
          left = stack.pop
          stack << (left || right)
        end
      end

      stack.first
    end

    def build_tree(tokens)
      stack = []

      tokens.each do |token|
        case token
        when :AND, :OR
          right = stack.pop
          raise "Syntax error" unless right
          left = stack.pop
          raise "Syntax error" unless left
          node = Node.new(nil, token)
          node.left = left
          node.right = right
          stack.push(node)
        when :NOT
          operand = stack.pop
          node = Node.new(nil, token)
          node.left = operand
          stack.push(node)
        else  # this means the token is a group
          stack.push(Node.new(token))
        end
      end

      stack[0]  # The root of our expression tree
    end

    def get_truth_for_user(user)
      user.groups.pluck(:name).map { |name| name.downcase } +
        user.badges.map { |badge| "badge:#{badge.slug}" } +
        user.badges.pluck(:id).map { |id| "badge:#{id}" }
    end

    def get_deps_for_rule(rule)
      tokens = tokenize(rule)
      postfix = shunting_yard(tokens)
      tree = build_tree(postfix) # include it because it does syntax checking
      postfix.reject { |el| el.is_a? Symbol }.uniq
    end

    def evaluate_rule(user, rule)
      true_vars = get_truth_for_user(user)
      tokens = tokenize(rule)
      postfix = shunting_yard(tokens)
      result = evaluate_postfix(postfix, true_vars)
    end

    def group_or_badge_set(group_or_badge)
      if group_or_badge.start_with?("badge:")
        badge_id = group_or_badge.split(":").last.to_i
        UserBadge.where(badge_id: badge_id).pluck(:user_id)
      else
        Group.find_by(name: group_or_badge).users.pluck(:id)
      end
    end

    def universal_set
      User.pluck(:id)
    end

    def evaluate_tree(node)
      return unless node

      return group_or_badge_set(node.value) if node.leaf?

      left_result = evaluate_tree(node.left)
      right_result = evaluate_tree(node.right) if node.right

      case node.operator
      when :AND
        left_result & right_result
      when :OR
        left_result | right_result
      when :NOT
        universal_set - left_result
      end
    end

    def magical_tree(rule)
      tokens = tokenize(rule)
      postfix = shunting_yard(tokens)
      tree = build_tree(postfix)
      evaluate_tree(tree)
    end
  end
end

