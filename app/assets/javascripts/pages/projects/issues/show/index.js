import DesignManagement from '~/design_management';
import initRelatedIssues from '~/related_issues';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initShow from '../show';

initShow();
DesignManagement();

window.requestIdleCallback(() => {
  initSidebarBundle();
  initRelatedIssues();
});
