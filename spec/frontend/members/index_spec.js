import { createWrapper } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import MembersApp from '~/members/components/app.vue';
import { initMembersApp } from '~/members/index';
import { membersJsonString, members } from './mock_data';

describe('initMembersApp', () => {
  let el;
  let vm;
  let wrapper;

  const setup = () => {
    vm = initMembersApp(el, {
      tableFields: ['account'],
      tableAttrs: { table: { 'data-qa-selector': 'members_list' } },
      tableSortableFields: ['account'],
      requestFormatter: () => ({}),
      filteredSearchBar: { show: false },
    });
    wrapper = extendedWrapper(createWrapper(vm));
  };

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-members', membersJsonString);
    el.setAttribute('data-source-id', '234');
    el.setAttribute('data-can-manage-members', 'true');
    el.setAttribute('data-member-path', '/groups/foo-bar/-/group_members/:id');

    window.gon = { current_user_id: 123 };
  });

  afterEach(() => {
    el = null;

    wrapper.destroy();
    wrapper = null;
  });

  it('renders `MembersApp`', () => {
    setup();

    expect(wrapper.find(MembersApp).exists()).toBe(true);
  });

  it('sets `currentUserId` in provide/inject', () => {
    setup();

    expect(vm.$options.provide().currentUserId).toBe(123);
  });

  describe('when `gon.current_user_id` is not set (user is not logged in)', () => {
    it('sets `currentUserId` as `null` in provide/inject', () => {
      window.gon = {};
      setup();

      expect(vm.$options.provide().currentUserId).toBeNull();
    });
  });

  it('parses and sets `data-source-id` as `sourceId` in provide/inject', () => {
    setup();

    expect(vm.$options.provide().sourceId).toBe(234);
  });

  it('parses and sets `data-can-manage-members` as `canManageMembers` in Vuex store', () => {
    setup();

    expect(vm.$options.provide().canManageMembers).toBe(true);
  });

  it('parses and sets `members` in Vuex store', () => {
    setup();

    expect(vm.$store.state.members).toEqual(members);
  });

  it('sets `tableFields` in Vuex store', () => {
    setup();

    expect(vm.$store.state.tableFields).toEqual(['account']);
  });

  it('sets `tableAttrs` in Vuex store', () => {
    setup();

    expect(vm.$store.state.tableAttrs).toEqual({ table: { 'data-qa-selector': 'members_list' } });
  });

  it('sets `tableSortableFields` in Vuex store', () => {
    setup();

    expect(vm.$store.state.tableSortableFields).toEqual(['account']);
  });

  it('sets `requestFormatter` in Vuex store', () => {
    setup();

    expect(vm.$store.state.requestFormatter()).toEqual({});
  });

  it('sets `filteredSearchBar` in Vuex store', () => {
    setup();

    expect(vm.$store.state.filteredSearchBar).toEqual({ show: false });
  });

  it('sets `memberPath` in Vuex store', () => {
    setup();

    expect(vm.$store.state.memberPath).toBe('/groups/foo-bar/-/group_members/:id');
  });
});
