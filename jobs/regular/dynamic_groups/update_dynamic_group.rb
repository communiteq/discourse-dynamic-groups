module Jobs
  module DynamicGroups
    class UpdateDynamicGroup < ::Jobs::Base
      def execute(args)
        group = Group.find(args[:group_id])
        me = DiscourseDynamicGroups::MembershipEvaluator.new
        me.evaluate_group(group)
      end
    end
  end
end

