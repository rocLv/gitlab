# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::IssuesHelpers do
  let_it_be(:issues_helper) do
    Class.new do
      include API::Helpers::IssuesHelpers
    end.new
  end

  describe '#validate_list_scope!' do
    shared_examples 'does not return an error' do
      it 'does not return an error' do
        expect(issues_helper).not_to receive(:unprocessable_entity!)

        issues_helper.validate_list_scope!
      end
    end

    shared_examples 'returns an unprocessable_entity error' do
      it 'returns an error' do
        expect(issues_helper).to receive(:unprocessable_entity!)

        issues_helper.validate_list_scope!
      end
    end

    before do
      allow(issues_helper).to receive(:params).and_return(params)
    end

    context 'when unscoped_issue_list_api is true' do
      context 'when scope param is all an no other filters are provided' do
        let(:params) { { scope: 'all' } }

        it_behaves_like 'does not return an error'
      end
    end

    context 'when unscoped_issue_list_api is false' do
      before do
        stub_application_setting(unscoped_issue_list_api: false)
      end

      context 'when scope param is not all' do
        context 'when one of the required params is provided' do
          let(:params) { { scope: 'all', assignee_username: 'vvega' } }

          it_behaves_like 'does not return an error'
        end

        context 'when non of the other required params are provided' do
          let(:params) { {} }

          it_behaves_like 'does not return an error'
        end
      end

      context 'when scope param is all' do
        context 'when one of the required params is provided' do
          let(:params) { { scope: 'all', assignee_username: 'vvega' } }

          it_behaves_like 'does not return an error'
        end

        context 'when non of the other required params are provided' do
          let(:params) { { scope: 'all' } }

          it_behaves_like 'returns an unprocessable_entity error'
        end
      end
    end
  end
end
