<script>
import axios from '~/lib/utils/axios_utils';

import SignInPage from './sign_in.vue';
import SubscriptionsPage from './subscriptions.vue';

export default {
  components: { SignInPage, SubscriptionsPage },
  data() {
    return {
      user: null,
    };
  },
  computed: {
    userSignedIn() {
      return Boolean(this.user);
    },
  },
  methods: {
    onSignIn(user) {
      this.user = user;
    },
  },
};
</script>
<template>
  <main>
    <subscriptions-page v-if="userSignedIn" />
    <sign-in-page v-else @sign-in="onSignIn" />
  </main>
</template>
