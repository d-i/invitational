module Invitational
  module InvitationCore
    extend ActiveSupport::Concern

    included do
      belongs_to :invitable, :polymorphic => true, optional: true

      before_create :setup_hash

      validates :email,  :presence => true
      validates :role,  :presence => true
      validates :invitable,  :presence => true, :if => :standard_role?

      scope :uberadmin, lambda {
        where("invitable_id IS NULL AND role = 'uberadmin'")
      }

      scope :for_email, lambda {|email|
        where('email = ?', email)
      }

      scope :pending_for, lambda {|email|
        where('email = ? AND user_id IS NULL', email)
      }

      scope :for_claim_hash, lambda {|claim_hash|
        where('claim_hash = ?', claim_hash)
      }

      scope :for_invitable, lambda {|type, id|
        where('invitable_type = ? AND invitable_id = ?', type, id)
      }

      scope :by_role, lambda {|role|
        where('role = ?', role.to_s)
      }

      scope :for_system_role, lambda {|role|
        where('invitable_id IS NULL AND role = ?', role.to_s)
      }

      scope :pending, lambda { where('user_id IS NULL') }
      scope :claimed, lambda { where('user_id IS NOT NULL') }

      @system_roles = [:uberadmin]

      def self.system_roles
        @system_roles
      end
    end

    module ClassMethods
      def claim claim_hash, user
        Invitational::ClaimsInvitation.for claim_hash, user
      end

      def claim_all_for user
        Invitational::ClaimsAllInvitations.for user
      end

      def invite_uberadmin target
        Invitational::CreatesUberAdminInvitation.for target
      end

      def invite_system_user target, role
        Invitational::CreatesSystemUserInvitation.for target, role
      end

      def accepts_system_roles_as *args
        args.each do |role|
          relation = role.to_s.pluralize.to_sym

          scope relation, -> {where("invitable_id IS NULL AND role = '#{role.to_s}'")}

          self.system_roles << role
        end
      end

    end

    def setup_hash
      self.date_sent = DateTime.now
      self.claim_hash = SecureRandom.alphanumeric(40)
    end

    def standard_role?
      roles = Invitation.system_roles + [:uberadmin]
      !roles.include?(role)
    end

    def role
      unless super.nil?
        super.to_sym
      end
    end

    def role=(value)
      super(value.to_sym)
      role
    end

    def role_title
      if uberadmin?
        "Uber Admin"
      else
        role.to_s.titleize
      end
    end

    def uberadmin?
      invitable.nil? == true && role == :uberadmin
    end

    def claimed?
      date_accepted.nil? == false
    end

    def unclaimed?
      !claimed?
    end
  end
end
