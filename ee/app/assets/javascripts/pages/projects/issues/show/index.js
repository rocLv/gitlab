import initRelatedFeatureFlags from 'ee/related_feature_flags';
import initSidebarBundle from 'ee/sidebar/sidebar_bundle';

import initShow from '~/pages/projects/issues/show';
import initIssueBootstrap from '~/pages/projects/issues/show/bootstrap';
import initRelatedIssues from '~/related_issues';
import UserCallout from '~/user_callout';

const bootstrapFn = () => {
  initSidebarBundle();
  initRelatedIssues();
  initRelatedFeatureFlags();

  // eslint-disable-next-line no-new
  new UserCallout({ className: 'js-epics-sidebar-callout' });
  // eslint-disable-next-line no-new
  new UserCallout({ className: 'js-weight-sidebar-callout' });
};

initIssueBootstrap({
  initShow,
  bootstrapFn,
});
