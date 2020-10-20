import { leftSidebarViews, viewerTypes } from '../constants';
import { DEFAULT_THEME } from '../lib/themes';

export default () => ({
  currentProjectId: '',
  currentBranchId: '',
  currentMergeRequestId: '',
  changedFiles: [],
  endpoints: {},
  lastCommitMsg: '',
  loading: false,
  openFiles: [],
  trees: {},
  projects: {},
  panelResizing: false,
  entries: {},
  viewer: viewerTypes.edit,
  delayViewerUpdated: false,
  currentActivityView: leftSidebarViews.edit.name,
  fileFindVisible: false,
  links: {},
  errorMessage: null,
  entryModal: {
    type: '',
    path: '',
    entry: {},
  },
  clientsidePreviewEnabled: false,
  renderWhitespaceInCode: false,
  editorTheme: DEFAULT_THEME,
  codesandboxBundlerUrl: null,
});
