# frozen_string_literal: true

module Groups
  class SeatUsageExportService
    def self.execute(group, user)
      new.(group, user).execute
    end

    def initialize(group, user)
      @group = group
      @user = user
    end

    def execute
      Notify.issues_csv_email(user, project, csv_data, csv_builder.status).deliver_now
    end

    private

    attr_reader :group

    def csv_data
      # result = BilledUsersFinder.new(group, order_by: 'id_asc').execute
      #  iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: result[:users])
      #  iterator.each_batch(of: 2) {|r| puts r.to_sql}
    end
  end
end
