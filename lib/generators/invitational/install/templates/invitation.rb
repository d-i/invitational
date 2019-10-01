class Invitation < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include Invitational::InvitationCore

  belongs_to :user<%= @custom_user_class %>, optional: true

  accepts_system_roles_as

end
