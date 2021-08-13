# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob, :clean_gitlab_redis_queues do
  using RSpec::Parameterized::TableSyntax

  subject(:duplicate_job) do
    described_class.new(job, queue)
  end

  let(:wal_locations) do
    {
      main: '0/D525E3A8',
      ci: 'AB/12345'
    }
  end

  let(:job) { { 'class' => 'AuthorizedProjectsWorker', 'args' => [1], 'jid' => '123', 'wal_locations' => wal_locations } }
  let(:queue) { 'authorized_projects' }

  let(:idempotency_key) do
    hash = Digest::SHA256.hexdigest("#{job['class']}:#{Sidekiq.dump_json(job['args'])}")
    "#{Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE}:duplicate:#{queue}:#{hash}"
  end

  describe '#schedule' do
    shared_examples 'scheduling with deduplication class' do |strategy_class|
      it 'calls schedule on the strategy' do
        expect do |block|
          expect_next_instance_of("Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::#{strategy_class}".constantize) do |strategy|
            expect(strategy).to receive(:schedule).with(job, &block)
          end

          duplicate_job.schedule(&block)
        end.to yield_control
      end
    end

    it_behaves_like 'scheduling with deduplication class', 'UntilExecuting'

    context 'when the deduplication depends on a FF' do
      before do
        skip_feature_flags_yaml_validation
        skip_default_enabled_yaml_check

        allow(AuthorizedProjectsWorker).to receive(:get_deduplication_options).and_return(feature_flag: :my_feature_flag)
      end

      context 'when the feature flag is enabled' do
        before do
          stub_feature_flags(my_feature_flag: true)
        end

        it_behaves_like 'scheduling with deduplication class', 'UntilExecuting'
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(my_feature_flag: false)
        end

        it_behaves_like 'scheduling with deduplication class', 'None'
      end
    end
  end

  describe '#perform' do
    it 'calls perform on the strategy' do
      expect do |block|
        expect_next_instance_of(Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuting) do |strategy|
          expect(strategy).to receive(:perform).with(job, &block)
        end

        duplicate_job.perform(&block)
      end.to yield_control
    end
  end

  describe '#check!' do
    context 'when there was no job in the queue yet' do
      it { expect(duplicate_job.check!).to eq('123') }

      it "adds a idempotency key with ttl set to #{described_class::DUPLICATE_KEY_TTL}" do
        expect { duplicate_job.check! }
          .to change { read_idempotency_key_with_ttl(idempotency_key) }
                .from([nil, -2])
                .to(['123', be_within(1).of(described_class::DUPLICATE_KEY_TTL)])
      end

      it "adds a existing wal locations key with ttl set to #{described_class::DUPLICATE_KEY_TTL}" do
        expect { duplicate_job.check! }
          .to change { read_idempotency_key_with_ttl(existing_wal_location_key(idempotency_key, :main)) }
                .from([nil, -2])
                .to([wal_locations[:main], be_within(1).of(described_class::DUPLICATE_KEY_TTL)])
          .and change { read_idempotency_key_with_ttl(existing_wal_location_key(idempotency_key, :ci)) }
                      .from([nil, -2])
                      .to([wal_locations[:ci], be_within(1).of(described_class::DUPLICATE_KEY_TTL)])
      end

      it "adds the idempotency key to the jobs payload" do
        expect { duplicate_job.check! }.to change { job['idempotency_key'] }.from(nil).to(idempotency_key)
      end
    end

    context 'when there was already a job with same arguments in the same queue' do
      before do
        set_idempotency_key(idempotency_key, 'existing-key')
        wal_locations.each do |config_name, location|
          set_idempotency_key(existing_wal_location_key(idempotency_key, config_name), location)
        end
      end

      it { expect(duplicate_job.check!).to eq('existing-key') }

      it "does not change the existing key's TTL" do
        expect { duplicate_job.check! }
          .not_to change { read_idempotency_key_with_ttl(idempotency_key) }
                .from(['existing-key', -1])
      end

      it "does not change the existing wal locations key's TTL" do
        expect { duplicate_job.check! }
          .to not_change { read_idempotency_key_with_ttl(existing_wal_location_key(idempotency_key, :main)) }
                .from([wal_locations[:main], -1])
          .and not_change { read_idempotency_key_with_ttl(existing_wal_location_key(idempotency_key, :ci)) }
                .from([wal_locations[:ci], -1])
      end

      it 'sets the existing jid' do
        duplicate_job.check!

        expect(duplicate_job.existing_jid).to eq('existing-key')
      end
    end
  end

  describe '#update_latest_wal_location!' do
    let(:offset) { '1024' }

    before do
      allow(duplicate_job).to receive(:pg_wal_lsn_diff).with(:main).and_return(offset)
      allow(duplicate_job).to receive(:pg_wal_lsn_diff).with(:ci).and_return(offset)
    end

    shared_examples 'updates wal location' do
      it "updates a wal location to redis with an offset" do
        expect { duplicate_job.update_latest_wal_location! }
          .to change { read_range_from_redis(wal_location_key(idempotency_key, :main)) }
                .from(existing_wal_with_offset[:main])
                .to(new_wal_with_offset[:main])
          .and change { read_range_from_redis(wal_location_key(idempotency_key, :ci)) }
                .from(existing_wal_with_offset[:ci])
                .to(new_wal_with_offset[:ci])
      end
    end

    context "when the key doesn't exists in redis" do
      include_examples 'updates wal location' do
        let(:existing_wal_with_offset) { { main: [], ci: [] } }
        let(:new_wal_with_offset) { wal_locations.transform_values { |v| [v, offset] } }
      end
    end

    context "when the key exists in redis" do
      let(:existing_offset) { '1023'}
      let(:existing_wal_locations) do
        {
          main: '0/D525E3NM',
          ci: 'AB/111112'
        }
      end

      before do
        rpush_to_redis_key(wal_location_key(idempotency_key, :main), existing_wal_locations[:main], existing_offset)
        rpush_to_redis_key(wal_location_key(idempotency_key, :ci), existing_wal_locations[:ci], existing_offset)
      end

      context "when the new offset is bigger then the existing one" do
        include_examples 'updates wal location' do
          let(:existing_wal_with_offset) { existing_wal_locations.transform_values { |v| [v, existing_offset] } }
          let(:new_wal_with_offset) { wal_locations.transform_values { |v| [v, offset] } }
        end
      end

      context "when the old offset is not bigger then the existing one" do
        let(:existing_offset) { offset }

        it "does not update a wal location to redis with an offset" do
          expect { duplicate_job.update_latest_wal_location! }
            .to not_change { read_range_from_redis(wal_location_key(idempotency_key, :main)) }
                  .from([existing_wal_locations[:main], existing_offset])
            .and not_change { read_range_from_redis(wal_location_key(idempotency_key, :ci)) }
                   .from([existing_wal_locations[:ci], existing_offset])
        end
      end
    end
  end

  describe '#latest_wal_locations' do
    before do
      rpush_to_redis_key(wal_location_key(idempotency_key, :main), wal_locations[:main], 1024)
      rpush_to_redis_key(wal_location_key(idempotency_key, :ci), wal_locations[:ci], 1024)
    end

    it { expect(duplicate_job.latest_wal_locations).to eq(wal_locations) }
  end

  describe '#delete!' do
    context "when we didn't track the definition" do
      it { expect { duplicate_job.delete! }.not_to raise_error }
    end

    context 'when the key exists in redis' do
      before do
        set_idempotency_key(idempotency_key, 'existing-jid')
        wal_locations.each do |config_name, location|
          set_idempotency_key(existing_wal_location_key(idempotency_key, config_name), location)
          set_idempotency_key(wal_location_key(idempotency_key, config_name), location)
        end
      end

      shared_examples 'deleting the duplicate job' do
        shared_examples 'deleting keys from redis' do |key_name|
          it "removes the #{key_name} from redis" do
            expect { duplicate_job.delete! }
              .to change { read_idempotency_key_with_ttl(key) }
                    .from([from_value, -1])
                    .to([nil, -2])
          end
        end

        it_behaves_like 'deleting keys from redis', 'idempotent key' do
          let(:key) { idempotency_key }
          let(:from_value) { 'existing-jid' }
        end

        it_behaves_like 'deleting keys from redis', 'existing wal location keys for main database' do
          let(:key) { existing_wal_location_key(idempotency_key, :main) }
          let(:from_value) { wal_locations[:main] }
        end

        it_behaves_like 'deleting keys from redis', 'existing wal location keys for ci database' do
          let(:key) { existing_wal_location_key(idempotency_key, :ci) }
          let(:from_value) { wal_locations[:ci] }
        end

        it_behaves_like 'deleting keys from redis', 'latest wal location keys for main database' do
          let(:key) { wal_location_key(idempotency_key, :main) }
          let(:from_value) { wal_locations[:main] }
        end

        it_behaves_like 'deleting keys from redis', 'latest wal location keys for ci database' do
          let(:key) { wal_location_key(idempotency_key, :ci) }
          let(:from_value) { wal_locations[:ci] }
        end
      end

      context 'when the idempotency key is not part of the job' do
        it_behaves_like 'deleting the duplicate job'

        it 'recalculates the idempotency hash' do
          expect(duplicate_job).to receive(:idempotency_hash).and_call_original

          duplicate_job.delete!
        end
      end

      context 'when the idempotency key is part of the job' do
        let(:idempotency_key) { 'not the same as what we calculate' }
        let(:job) { super().merge('idempotency_key' => idempotency_key) }

        it_behaves_like 'deleting the duplicate job'

        it 'does not recalculate the idempotency hash' do
          expect(duplicate_job).not_to receive(:idempotency_hash)

          duplicate_job.delete!
        end
      end
    end
  end

  describe '#scheduled?' do
    it 'returns false for non-scheduled jobs' do
      expect(duplicate_job.scheduled?).to be(false)
    end

    context 'scheduled jobs' do
      let(:job) do
        { 'class' => 'AuthorizedProjectsWorker',
          'args' => [1],
          'jid' => '123',
          'at' => 42 }
      end

      it 'returns true' do
        expect(duplicate_job.scheduled?).to be(true)
      end
    end
  end

  describe '#duplicate?' do
    it "raises an error if the check wasn't performed" do
      expect { duplicate_job.duplicate? }.to raise_error /Call `#check!` first/
    end

    it 'returns false if the existing jid equals the job jid' do
      duplicate_job.check!

      expect(duplicate_job.duplicate?).to be(false)
    end

    it 'returns false if the existing jid is different from the job jid' do
      set_idempotency_key(idempotency_key, 'a different jid')
      duplicate_job.check!

      expect(duplicate_job.duplicate?).to be(true)
    end
  end

  describe '#scheduled_at' do
    let(:scheduled_at) { 42 }
    let(:job) do
      { 'class' => 'AuthorizedProjectsWorker',
        'args' => [1],
        'jid' => '123',
        'at' => scheduled_at }
    end

    it 'returns when the job is scheduled at' do
      expect(duplicate_job.scheduled_at).to eq(scheduled_at)
    end
  end

  describe '#options' do
    let(:worker_options) { { foo: true } }

    it 'returns worker options' do
      allow(AuthorizedProjectsWorker).to(
        receive(:get_deduplication_options).and_return(worker_options))

      expect(duplicate_job.options).to eq(worker_options)
    end
  end

  describe '#idempotent?' do
    context 'when worker class does not exist' do
      let(:job) { { 'class' => '' } }

      it 'returns false' do
        expect(duplicate_job).not_to be_idempotent
      end
    end

    context 'when worker class does not respond to #idempotent?' do
      before do
        stub_const('AuthorizedProjectsWorker', Class.new)
      end

      it 'returns false' do
        expect(duplicate_job).not_to be_idempotent
      end
    end

    context 'when worker class is not idempotent' do
      before do
        allow(AuthorizedProjectsWorker).to receive(:idempotent?).and_return(false)
      end

      it 'returns false' do
        expect(duplicate_job).not_to be_idempotent
      end
    end

    context 'when worker class is idempotent' do
      before do
        allow(AuthorizedProjectsWorker).to receive(:idempotent?).and_return(true)
      end

      it 'returns true' do
        expect(duplicate_job).to be_idempotent
      end
    end
  end

  def existing_wal_location_key(idempotency_key, config_name)
    "#{idempotency_key}:#{config_name}:existing_wal_location"
  end

  def wal_location_key(idempotency_key, config_name)
    "#{idempotency_key}:#{config_name}:wal_location"
  end

  def set_idempotency_key(key, value = '1')
    Sidekiq.redis { |r| r.set(key, value) }
  end

  def rpush_to_redis_key(key, wal, offset)
    Sidekiq.redis { |r| r.rpush(key, [wal, offset]) }
  end

  def read_idempotency_key_with_ttl(key)
    Sidekiq.redis do |redis|
      redis.pipelined do |p|
        p.get(key)
        p.ttl(key)
      end
    end
  end

  def read_range_from_redis(key)
    Sidekiq.redis do |redis|
      redis.lrange(key, 0, -1)
    end
  end
end
