# frozen_string_literal: true

module DiscourseDynamicGroups
  class RuleEngine
    def initialize
      @group_names = Group.pluck(:name).map { |name| name.downcase } +
        Badge.pluck(:name).map { |name| "badge:#{slugify(name)}" } +
        Badge.pluck(:id).map { |id| "badge:#{id}" }

    end

    def slugify(name)
      slug = name.downcase
        .gsub(/[^a-z0-9\s-]/, '')  # Remove non-alphanumeric characters except spaces and hyphens
        .gsub(/\s+/, '-')         # Replace spaces with hyphens
        .gsub(/-+/, '-') 
    end

    def tokenize(expression)
      tokens = expression.scan(/AND|OR|NOT|\(|\)|[a-z\-]+(?:\:[a-z0-9\-]+)?/)

      tokens.map do |token|
        case token
        when 'AND', 'OR', 'NOT'
          token.to_sym
        when '('
          "LBRACKET".to_sym
        when ')'
          "RBRACKET".to_sym
        else
          if @group_names.include? token.downcase
            token
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
          if operators.last && [:AND, :OR, :NOT].include?(operators.last)
            raise "Consecutive operators detected: ... #{operators.last} #{token} ..."
          end
    
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

    def get_truth_for_user(user)
      user.groups.pluck(:name).map { |name| name.downcase } +
        user.badges.pluck(:name).map { |name| "badge:#{slugify(name)}" } +
        user.badges.pluck(:id).map { |id| "badge:#{id}" }
    end

    def evaluate_rule(user, rule)
      true_vars = get_truth_for_user(user)
      tokens = tokenize(rule)
      postfix = shunting_yard(tokens)
      result = evaluate_postfix(postfix, true_vars)
    end
  end
end

