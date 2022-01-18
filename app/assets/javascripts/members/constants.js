import { __ } from '~/locale';

export const FIELD_KEY_ACCOUNT = 'account';
export const FIELD_KEY_SOURCE = 'source';
export const FIELD_KEY_GRANTED = 'granted';
export const FIELD_KEY_INVITED = 'invited';
export const FIELD_KEY_REQUESTED = 'requested';
export const FIELD_KEY_MAX_ROLE = 'maxRole';
export const FIELD_KEY_EXPIRATION = 'expiration';
export const FIELD_KEY_LAST_SIGN_IN = 'lastSignIn';
export const FIELD_KEY_ACTIONS = 'actions';

export const FIELDS = [
  {
    key: FIELD_KEY_ACCOUNT,
    label: __('Account'),
    sort: {
      asc: 'name_asc',
      desc: 'name_desc',
    },
  },
  {
    key: FIELD_KEY_SOURCE,
    label: __('Source'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: FIELD_KEY_GRANTED,
    label: __('Access granted'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
    sort: {
      asc: 'last_joined',
      desc: 'oldest_joined',
    },
  },
  {
    key: FIELD_KEY_INVITED,
    label: __('Invited'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: FIELD_KEY_REQUESTED,
    label: __('Requested'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: FIELD_KEY_MAX_ROLE,
    label: __('Max role'),
    thClass: 'col-max-role',
    tdClass: 'col-max-role',
    sort: {
      asc: 'access_level_asc',
      desc: 'access_level_desc',
    },
  },
  {
    key: FIELD_KEY_EXPIRATION,
    label: __('Expiration'),
    thClass: 'col-expiration',
    tdClass: 'col-expiration',
  },
  {
    key: FIELD_KEY_LAST_SIGN_IN,
    label: __('Last sign-in'),
    sort: {
      asc: 'recent_sign_in',
      desc: 'oldest_sign_in',
    },
  },
  {
    key: FIELD_KEY_ACTIONS,
    thClass: 'col-actions',
  },
];

export const DEFAULT_SORT = {
  sortByKey: 'account',
  sortDesc: false,
};

export const AVATAR_SIZE = 48;

export const MEMBER_TYPES = {
  user: 'user',
  group: 'group',
  invite: 'invite',
  accessRequest: 'accessRequest',
};

export const TAB_QUERY_PARAM_VALUES = {
  group: 'groups',
  invite: 'invited',
  accessRequest: 'access_requests',
};

/**
 * This user state value comes from the User model
 * see the state machine in app/models/user.rb
 */
export const USER_STATE_BLOCKED_PENDING_APPROVAL = 'blocked_pending_approval';

/**
 * This and following member state constants' values
 * come from ee/app/models/ee/member.rb
 */
export const MEMBER_STATE_CREATED = 0;
export const MEMBER_STATE_AWAITING = 1;
export const MEMBER_STATE_ACTIVE = 2;

export const BADGE_LABELS_PENDING_OWNER_APPROVAL = __('Pending owner approval');

export const DAYS_TO_EXPIRE_SOON = 7;

export const LEAVE_MODAL_ID = 'member-leave-modal';

export const REMOVE_GROUP_LINK_MODAL_ID = 'remove-group-link-modal-id';

export const SEARCH_TOKEN_TYPE = 'filtered-search-term';

export const SORT_QUERY_PARAM_NAME = 'sort';
export const ACTIVE_TAB_QUERY_PARAM_NAME = 'tab';

export const MEMBER_ACCESS_LEVEL_PROPERTY_NAME = 'access_level';

export const GROUP_LINK_BASE_PROPERTY_NAME = 'group_link';
export const GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME = 'group_access';
