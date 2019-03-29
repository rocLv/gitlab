import $ from 'jquery';
import Vue from 'vue';
import router from './router';
import App from './components/app.vue';
import apolloProvider from './graphql';

export default () => {
  const el = document.getElementById('js-design-management');

  $('.js-issue-tabs').on('shown.bs.tab', ({ target: { id } }) => {
    if (id === 'designs' && router.currentRoute.name === 'root') {
      router.push('/designs');
    } else if (id === 'discussion') {
      router.push('/');
    }
  });

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {
      projectFullPath: el.dataset.projectPath,
      issueIid: el.dataset.issueIid,
    },
  });

  return new Vue({
    el,
    router,
    apolloProvider,
    render(createElement) {
      return createElement(App);
    },
  });
};
