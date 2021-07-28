# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnersResolver do
  include GraphqlHelpers

  include_context 'runners resolver setup'

  it_behaves_like Resolvers::Ci::RunnersResolver

  describe '#resolve' do
    subject { resolve(described_class, obj: obj, ctx: { current_user: user }, args: {}) }

    context 'with obj set to nil value' do
      let(:obj) { nil }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with obj set to unsupported value' do
      let_it_be(:obj) { build(:group) }

      it 'returns no runners' do
        expect { subject }.to raise_error("Unexpected parent type: #{obj.class}")
      end
    end
  end
end
