<script>
/**
 * This component is the new version of the Connect App
 * that leverages the new OAuth flow for authentication.
 *
 * It will eventually replace ./app_legacy.vue.
 */
import { GlButton } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';

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
      window.open(oauth_authorize_url, 'OAuth Login', oauthWindowOptions);
    },
    // All the event handling should happen in this component
    handleWindowMessage(event) {
      if (window.origin === event.origin) {
        const state = event.data?.state;
        // The state should match the OAuth data
        if (state === this.oauthMetadata.state) {
          const code = event.data?.code;
          this.getOAuthToken(code);
        }
      }
    },
    // This potentially should be moved to the store
    async getOAuthToken(code) {
      const { oauth_token_payload: oauthTokenPayload, oauth_token_url } = this.oauthMetadata;
      const { data } = await axios.post(oauth_token_url, { ...oauthTokenPayload, code });

      this.token = data.access_token;
      this.loading = false;

      await this.loadUser();
    },
    async loadUser() {
      const { data } = await axios.get(`${window.origin}/api/v4/user`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });

      this.$emit('sign-in', data);
    },
  },
};
</script>
<template>
  <div class="jira-connect-app-body gl-px-5 gl-text-center">
    <h2>GitLab for Jira Configuration</h2>
    <p>Sign in to GitLab.com to get started.</p>
    <div class="gl-mt-7">
      <gl-button
        v-if="token === null"
        icon="external-link"
        variant="confirm"
        :disabled="loading"
        @click="startOAuthFlow"
      >
        Sign in to GitLab
      </gl-button>
      <pre v-else-if="user">Token: {{ token }}, User: {{ user.username }}</pre>
    </div>
    <div class="gl-mt-7">
      <p>Note: this integration only works with accounts on GitLab.com (SaaS).</p>
    </div>
  </div>
</template>
