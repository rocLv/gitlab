<script>
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
    // Eipi: Given we consume it just here, it also could be props
    oauthConfig: { default: {} },
  },
  data() {
    return { token: null, loading: false, user: null };
  },
  mounted() {
    window.addEventListener('message', this.eventListner);
  },
  beforeDestroy() {
    window.removeEventListener('message', this.eventListner);
  },
  methods: {
    // All the event handling should happen in this component
    startOAuthFlow() {
      const { oauth_authorize_url } = this.oauthConfig;
      window.open(oauth_authorize_url, 'OAuth Login', oauthWindowOptions);
    },
    // All the event handling should happen in this component
    eventListner(event) {
      if (window.origin === event.origin) {
        const state = event.data?.state;
        // The state should match the OAuth data
        if (state === this.oauthConfig.state) {
          const code = event.data?.code;
          this.getOAuthToken(code);
        }
      }
    },
    // This potentially should be moved to the store
    async getOAuthToken(code) {
      const { oauth_token_payload: oauthTokenPayload, oauth_token_url } = this.oauthConfig;
      const { data } = await axios.post(oauth_token_url, { ...oauthTokenPayload, code });

      this.token = data.access_token;
      this.loading = false;
      // Eipi: Instead of just loading the user (which we also would need to do, we could load the subscriptions
      // and other info we need)
      await this.poc();
    },
    // Eipi: This POC function is just to show that the token works!
    async poc() {
      const { data } = await axios.get(`${window.origin}/api/v4/user`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      this.user = data;
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
      <!-- Eipi: Add the already existing APP component here! -->
    </div>
    <div class="gl-mt-7">
      <p>Note: this integration only works with accounts on GitLab.com (SaaS).</p>
    </div>
  </div>
</template>
