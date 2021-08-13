<script>
/**
 * This component is the new version of the Connect App
 * that leverages the new OAuth flow for authentication.
 *
 * It will eventually replace ./app_legacy.vue.
 */
import { GlButton } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import { setAuthorizationHeader } from '../api';

const oauthWindowSize = 800;
const oauthWindowOptions = [
  'resizable=yes',
  'scrollbars=yes',
  'status=yes',
  `width=${oauthWindowSize}`,
  `height=${oauthWindowSize}`,
  `left=${window.screen.width / 2 - oauthWindowSize / 2}`,
  `top=${window.screen.height / 2 - oauthWindowSize / 2}`,
].join(',');

export default {
  components: {
    GlButton,
  },
  inject: {
    oauthMetadata: {
      default: {},
    },
  },
  data() {
    return {
      token: null,
      loading: false,
    };
  },
  mounted() {
    window.addEventListener('message', this.handleWindowMessage);
  },
  beforeDestroy() {
    window.removeEventListener('message', this.handleWindowMessage);
  },
  methods: {
    // All the event handling should happen in this component
    startOAuthFlow() {
      const { oauth_authorize_url } = this.oauthMetadata;
      window.open(oauth_authorize_url, s__('Integrations|Sign in to GitLab'), oauthWindowOptions);
    },
    // All the event handling should happen in this component
    async handleWindowMessage(event) {
      if (window.origin !== event.origin) {
        return;
      }

      const state = event.data?.state;
      // The state should match the OAuth data
      if (state !== this.oauthMetadata.state) {
        return;
      }

      const code = event.data?.code;
      this.token = await this.getOAuthToken(code);
      setAuthorizationHeader(this.token);

      this.loading = false;

      await this.loadUser();
    },
    // This potentially should be moved to the store
    async getOAuthToken(code) {
      const { oauth_token_payload: oauthTokenPayload, oauth_token_url } = this.oauthMetadata;
      const { data } = await axios.post(oauth_token_url, { ...oauthTokenPayload, code });

      return data.access_token;
    },
    async loadUser() {
      const { data } = await axios.get('/api/v4/user', {
        headers: { Authorization: `Bearer ${this.token}` },
      });

      this.$emit('sign-in', data);
    },
  },
};
</script>
<template>
  <div class="jira-connect-app-body gl-px-5 gl-text-center">
    <h2>{{ s__('JiraService|GitLab for Jira Configuration') }}</h2>
    <p>{{ s__('JiraService|Sign in to GitLab.com to get started.') }}</p>

    <div class="gl-mt-7">
      <gl-button icon="external-link" variant="confirm" :loading="loading" @click="startOAuthFlow">
        {{ s__('Integrations|Sign in to GitLab') }}
      </gl-button>
    </div>

    <p class="gl-mt-7">
      {{ s__('JiraConnect|Note: this integration only works with accounts on GitLab.com (SaaS).') }}
    </p>
  </div>
</template>
