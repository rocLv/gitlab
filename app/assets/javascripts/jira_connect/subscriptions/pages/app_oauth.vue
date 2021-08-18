<script>
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
  <main class="jira-connect-app gl-px-5 gl-pt-7 gl-mx-auto">
    <subscriptions-page v-if="userSignedIn" />
    <sign-in-page v-else @sign-in="onSignIn" />
  </main>
</template>
