import createState from 'ee/user_lists/store/new/state';
import * as types from 'ee/user_lists/store/new/mutation_types';
import mutations from 'ee/user_lists/store/new/mutations';

describe('User List Edit Mutations', () => {
  let state;

  beforeEach(() => {
    state = createState({ projectId: '1' });
  });

  describe(types.RECIEVE_USER_LIST_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_CREATE_USER_LIST_ERROR](state, ['network error']);
    });

    it('sets the error message to the recieved one', () => {
      expect(state.errorMessage).toEqual(['network error']);
    });

    it('sets the error message to the recevied API message if present', () => {
      const message = ['name is blank', 'name is too short'];

      mutations[types.RECEIVE_CREATE_USER_LIST_ERROR](state, message);
      expect(state.errorMessage).toEqual(message);
    });
  });

  describe(types.DISMISS_ERROR_ALERT, () => {
    beforeEach(() => {
      mutations[types.DISMISS_ERROR_ALERT](state);
    });

    it('clears the error message', () => {
      expect(state.errorMessage).toBe('');
    });
  });
});
