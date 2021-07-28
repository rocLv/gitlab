import initIssueApp from '~/pages/projects/issues/show/bootstrap';
import initRelatedIssues from '~/related_issues';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initShow from '../show';

const bootstrapFn = () => {
  initSidebarBundle();
  initRelatedIssues();
};

initIssueApp({
  initShow,
  bootstrapFn,
});
