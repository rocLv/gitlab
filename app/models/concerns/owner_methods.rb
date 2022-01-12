# frozen_string_literal: true

module OwnerMethods
  extend ActiveSupport::Concern

  def blocked_owners
    members.blocked.where(access_level: Gitlab::Access::OWNER)
  end

  def default_owner
    return owners.first if owners.any?

    parent&.default_owner || owner
  end

  # Check if user is a last owner of the group.
  def last_owner?(user)
    has_owner?(user) && single_owner?
  end

  def member_last_owner?(member)
    return member.last_owner unless member.last_owner.nil?

    last_owner?(member.user)
  end

  # Return the highest access level for a user
  #
  # A special case is handled here when the user is a GitLab admin
  # which implies it has "OWNER" access everywhere, but should not
  # officially appear as a member of a group unless specifically added to it
  #
  # @param user [User]
  # @param only_concrete_membership [Bool] whether require admin concrete membership status
  def max_member_access_for_user(user, only_concrete_membership: false)
    return GroupMember::NO_ACCESS unless user
    return GroupMember::OWNER if user.can_admin_all_resources? && !only_concrete_membership

    max_member_access([user.id])[user.id]
  end

  def member_last_blocked_owner?(member)
    return member.last_blocked_owner unless member.last_blocked_owner.nil?

    return false if members_with_parents.owners.any?

    single_blocked_owner? && blocked_owners.exists?(user_id: member.user)
  end

  def single_blocked_owner?
    blocked_owners.size == 1
  end

  def single_owner?
    members_with_parents.owners.size == 1
  end
end

OwnerMethods.prepend_mod_with('OwnerMethods')
