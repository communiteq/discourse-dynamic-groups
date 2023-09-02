# frozen_string_literal: true

module DiscourseDynamicGroups
  class MembershipEvaluator

    def progress_chunk_size(cnt)
      [cnt/100, 5].max
    end

    def progress(group, chunk_size, i, total)
      if i % chunk_size == 0
        progress = (i*100/total).to_i
        if progress == 100
          group.custom_fields.delete(:membership_progress)
        else
          group.custom_fields[:membership_progress] = (i*100/total).to_i
        end
        group.save_custom_fields
      end
    end

    def evaluate_group(group)
      engine = ::DiscourseDynamicGroups::RuleEngine.new
      user_ids = engine.magical_tree(group.dynamic_rule)
      current_users = group.users.pluck(:id)
      to_be_removed = current_users - user_ids
      to_be_added = user_ids - current_users

      t = to_be_removed.count + to_be_added.count
      c = progress_chunk_size(t)
      i = 0

      User.where(id: to_be_removed).each do |user|
        progress(group,c,i,t)
        i+=1
        group.remove(user)
      end
      User.where(id: to_be_added).each do |user|
        progress(group,c,i,t)
        i+=1
        group.add(user)
      end

      progress(group,t,t,t) # 100%
      t
    end
  end
end
    