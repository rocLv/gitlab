import DesignManagement from '~/design_management';
import { DESIGN_DETAIL_READY_EVENT } from '~/design_management/constants';
import eventHub from '../event_hub';

const singleDesignId = (() => {
  const designSingleRegexp = new RegExp('designs/(?<id>.+)');
  const designGroups = window.location.href.match(designSingleRegexp)?.groups;
  return designGroups?.id;
})();

export default ({ initShow, bootstrapFn }) => {
  if (singleDesignId) {
    eventHub.$once(DESIGN_DETAIL_READY_EVENT, () => {
      initShow();
      bootstrapFn();
    });
    DesignManagement();
  } else {
    initShow();
    window.requestIdleCallback(() => {
      DesignManagement();
      bootstrapFn();
    });
  }
};
