# frozen_string_literal: true

module EE
  module OwnerMethods
    extend ActiveSupport::Concern

    def owners_emails
      owners.pluck(:email)
    end
  end
end
