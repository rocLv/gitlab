import DesignManagement from '~/design_management';
import { DESIGN_DETAIL_READY_EVENT } from '~/design_management/constants';
import { DESIGNS_ROUTE_NAME } from '~/design_management/router/constants';
import eventHub from '../event_hub';

const singleDesignId = (() => {
  const designSingleRegexp = new RegExp(`${DESIGNS_ROUTE_NAME}/(?<id>.+)`);
  const designGroups = window.location.href.match(designSingleRegexp)?.groups;
  return designGroups?.id;
})();

export default function initIssueBootstrap({ initShow, bootstrapFn }) {
  if (singleDesignId) {
    eventHub.$once(DESIGN_DETAIL_READY_EVENT, () => {
      window.requestIdleCallback(() => {
        initShow();
        bootstrapFn();
      });
    });
    DesignManagement();
  } else {
    initShow();
    window.requestIdleCallback(() => {
      bootstrapFn();
      DesignManagement();
    });
  }
}
