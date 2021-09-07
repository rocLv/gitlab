import MockAdapter from 'axios-mock-adapter';
import codeQualityQuery from 'ee/codequality_report/graphql/queries/get_code_quality_violations.query.graphql';
import * as actions from 'ee/codequality_report/store/actions';
import { VIEW_EVENT_NAME } from 'ee/codequality_report/store/constants';
import * as types from 'ee/codequality_report/store/mutation_types';
import initialState from 'ee/codequality_report/store/state';
import { gqClient } from 'ee/codequality_report/store/utils';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import {
  unparsedIssues,
  parsedIssues,
  mockGraphqlResponse,
  mockGraphqlPagination,
} from '../mock_data';

jest.mock('~/api.js');
jest.mock('~/flash');

describe('Codequality report actions', () => {
  let mock;
  let state;

  const endpoint = `${TEST_HOST}/codequality_report.json`;
  const defaultState = {
    ...initialState(),
    endpoint,
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = defaultState;
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setPage', () => {
    it('sets the page number with feature flag disabled', (done) => {
      const origGon = window.gon;
      window.gon = { features: { graphqlCodeQualityFullReport: false } };

      return testAction(
        actions.setPage,
        12,
        state,
        [{ type: types.SET_PAGE, payload: { page: 12 } }],
        [],
        done,
      ).then(() => {
        window.gon = origGon;
      });
    });

    it('sets the page number with feature flag enabled', (done) => {
      const origGon = window.gon;
      window.gon = { features: { graphqlCodeQualityFullReport: true } };

      return testAction(
        actions.setPage,
        12,
        state,
        [{ type: types.SET_PAGE, payload: { after: '', currentPage: 12 } }],
        [{ type: 'fetchReport' }],
        done,
      ).then(() => {
        window.gon = origGon;
      });
    });
  });

  describe('requestReport', () => {
    it('sets the loading flag', (done) => {
      testAction(actions.requestReport, null, state, [{ type: types.REQUEST_REPORT }], [], done);
    });

    it('tracks a service ping event', () => {
      actions.requestReport({ commit: jest.fn() });

      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(VIEW_EVENT_NAME);
    });
  });

  describe('receiveReportSuccess', () => {
    it('parses the list of issues from the report with feature flag disabled', (done) => {
      const origGon = window.gon;
      window.gon = { features: { graphqlCodeQualityFullReport: false } };

      return testAction(
        actions.receiveReportSuccess,
        unparsedIssues,
        { blobPath: '/root/test-codequality/blob/feature-branch', ...state },
        [{ type: types.RECEIVE_REPORT_SUCCESS, payload: parsedIssues }],
        [],
        done,
      ).then(() => {
        window.gon = origGon;
      });
    });

    it('parses the list of issues from the report with feature flag enabled', (done) => {
      const origGon = window.gon;
      window.gon = { features: { graphqlCodeQualityFullReport: true } };

      const data = {
        edges: unparsedIssues.map((issue) => {
          return { node: issue };
        }),
      };

      return testAction(
        actions.receiveReportSuccess,
        data,
        { blobPath: '/root/test-codequality/blob/feature-branch', ...state },
        [{ type: types.RECEIVE_REPORT_SUCCESS_GRAPHQL, payload: { data, parsedIssues } }],
        [],
        done,
      ).then(() => {
        window.gon = origGon;
      });
    });
  });

  describe('receiveReportError', () => {
    it('accepts a report error', (done) => {
      testAction(
        actions.receiveReportError,
        'error',
        state,
        [{ type: types.RECEIVE_REPORT_ERROR, payload: 'error' }],
        [],
        done,
      );
    });
  });

  describe('fetchReport', () => {
    describe('with graphql feature flag disabled', () => {
      beforeEach(() => {
        mock.onGet(endpoint).replyOnce(200, unparsedIssues);
      });

      it('fetches the report', (done) => {
        const origGon = window.gon;
        window.gon = { features: { graphqlCodeQualityFullReport: false } };

        return testAction(
          actions.fetchReport,
          null,
          { blobPath: 'blah', ...state },
          [],
          [{ type: 'requestReport' }, { type: 'receiveReportSuccess', payload: unparsedIssues }],
          done,
        ).then(() => {
          window.gon = origGon;
        });
      });

      it('shows a flash message when there is an error', (done) => {
        testAction(
          actions.fetchReport,
          'error',
          state,
          [],
          [{ type: 'requestReport' }, { type: 'receiveReportError', payload: expect.any(Error) }],
          () => {
            expect(createFlash).toHaveBeenCalledWith({
              message: 'There was an error fetching the codequality report.',
            });
            done();
          },
        );
      });

      it('shows an error when blob path is missing', (done) => {
        testAction(
          actions.fetchReport,
          null,
          state,
          [],
          [{ type: 'requestReport' }, { type: 'receiveReportError', payload: expect.any(Error) }],
          () => {
            expect(createFlash).toHaveBeenCalledWith({
              message: 'There was an error fetching the codequality report.',
            });
            done();
          },
        );
      });
    });

    describe('with graphql feature flag enabled', () => {
      beforeEach(() => {
        jest.spyOn(gqClient, 'query').mockResolvedValue(mockGraphqlResponse);
        state.paginationData = mockGraphqlPagination;
      });

      it('fetches the report', () => {
        const origGon = window.gon;
        window.gon = { features: { graphqlCodeQualityFullReport: true } };

        return testAction(
          actions.fetchReport,
          null,
          { blobPath: 'blah', ...state },
          [],
          [
            { type: 'requestReport' },
            {
              type: 'receiveReportSuccess',
              payload: mockGraphqlResponse.data.project.pipeline.codeQualityReports,
            },
          ],
          () => {
            expect(gqClient.query).toHaveBeenCalledWith({
              query: codeQualityQuery,
              variables: { after: '', first: 25, iid: null, projectPath: null },
            });
          },
        ).then(() => {
          window.gon = origGon;
        });
      });
    });

    it('shows a flash message when there is an error', (done) => {
      testAction(
        actions.fetchReport,
        'error',
        state,
        [],
        [{ type: 'requestReport' }, { type: 'receiveReportError', payload: expect.any(Error) }],
        () => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'There was an error fetching the codequality report.',
          });
          done();
        },
      );
    });

    it('shows an error when blob path is missing', (done) => {
      testAction(
        actions.fetchReport,
        null,
        state,
        [],
        [{ type: 'requestReport' }, { type: 'receiveReportError', payload: expect.any(Error) }],
        () => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'There was an error fetching the codequality report.',
          });
          done();
        },
      );
    });
  });
});
