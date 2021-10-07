# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PgFullTextSearchable do
  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      include PgFullTextSearchable

      self.table_name = 'issues'

      has_one :search_data, class_name: 'Issues::SearchData'

      def self.name
        'Issue'
      end
    end
  end

  describe '.pg_full_text_searchable' do
    it 'sets pg_full_text_searchable_columns' do
      model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }]

      expect(model_class.pg_full_text_searchable_columns).to eq({ 'title' => 'A' })
    end

    it 'raises an error when called twice' do
      model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }]

      expect { model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }] }.to raise_error('Full text search columns already defined!')
    end
  end

  describe 'after commit hook' do
    let(:model) { model_class.create! }

    before do
      model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }]
    end

    context 'when specified columns are changed' do
      it 'calls update_search_data!' do
        expect(model).to receive(:update_search_data!)

        model.update!(title: 'A new title')
      end
    end

    context 'when specified columns are not changed' do
      it 'does not enqueue worker' do
        expect(model).not_to receive(:update_search_data!)

        model.update!(description: 'A new description')
      end
    end
  end

  describe '#update_search_data!' do
    let(:model) { model_class.create!(title: 'title', description: 'description') }

    before do
      model_class.pg_full_text_searchable columns: [{ name: 'title', weight: 'A' }, { name: 'description', weight: 'B' }]
    end

    it 'sets the correct weights' do
      model.update_search_data!

      expect(model.search_data.search_vector).to match(/'titl':1A/)
      expect(model.search_data.search_vector).to match(/'descript':2B/)
    end

    context 'with accented and non-Latin characters' do
      let(:model) { model_class.create!(title: '日本語', description: 'Jürgen') }

      it 'transliterates accented characters and removes non-Latin ones' do
        model.update_search_data!

        expect(model.search_data.search_vector).not_to match(/日本語/)
        expect(model.search_data.search_vector).to match(/jurgen/)
      end
    end

    context 'when upsert times out' do
      it 're-raises the exception' do
        expect(Issues::SearchData).to receive(:upsert).once.and_raise(ActiveRecord::StatementTimeout)

        expect { model.update_search_data! }.to raise_error(ActiveRecord::StatementTimeout)
      end
    end

    context 'with strings that go over tsvector limit', :delete do
      let(:long_string) { Array.new(30_000) { SecureRandom.hex }.join(' ') }
      let(:model) { model_class.create!(title: 'title', description: long_string) }

      it 'does not raise an exception' do
        expect(Gitlab::AppJsonLogger).to receive(:error).with(
          a_hash_including(class: model_class.name, model_id: model.id)
        )

        expect { model.update_search_data! }.not_to raise_error

        expect(model.search_data).to eq(nil)
      end
    end
  end
end
