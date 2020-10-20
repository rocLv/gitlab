import Vue from 'vue';
import * as types from './mutation_types';
import projectMutations from './mutations/project';
import mergeRequestMutation from './mutations/merge_request';
import fileMutations from './mutations/file';
import treeMutations from './mutations/tree';
import branchMutations from './mutations/branch';
import {
  sortTree,
  swapInParentTreeWithSorting,
  updateFileCollections,
  removeFromParentTree,
  pathsAreEqual,
} from './utils';

export default {
  [types.SET_INITIAL_DATA](state, data) {
    Object.assign(state, data);
  },
  [types.TOGGLE_LOADING](state, { entry, forceValue = undefined }) {
    if (entry.path) {
      Object.assign(state.entries[entry.path], {
        loading: forceValue !== undefined ? forceValue : !state.entries[entry.path].loading,
      });
    } else {
      Object.assign(entry, {
        loading: forceValue !== undefined ? forceValue : !entry.loading,
      });
    }
  },
  [types.SET_RESIZING_STATUS](state, resizing) {
    Object.assign(state, {
      panelResizing: resizing,
    });
  },
  [types.SET_LAST_COMMIT_MSG](state, lastCommitMsg) {
    Object.assign(state, {
      lastCommitMsg,
    });
  },
  [types.SET_ENTRIES](state, entries) {
    Object.assign(state, {
      entries,
    });
  },
  [types.CREATE_TMP_ENTRY](state, { data }) {
    Object.keys(data.entries).reduce((acc, key) => {
      const entry = data.entries[key];
      const foundEntry = state.entries[key];

      // NOTE: We can't clone `entry` in any of the below assignments because
      // we need `state.entries` and the `entry.tree` to reference the same object.
      if (!foundEntry || foundEntry.deleted) {
        Object.assign(state.entries, {
          [key]: entry,
        });
      } else {
        const tree = entry.tree.filter(
          f => foundEntry.tree.find(e => e.path === f.path) === undefined,
        );
        Object.assign(foundEntry, {
          tree: sortTree(foundEntry.tree.concat(tree)),
        });
      }

      return acc.concat(key);
    }, []);

    const currentTree = state.trees[`${state.currentProjectId}/${state.currentBranchId}`];
    const foundEntry = currentTree.tree.find(e => e.path === data.treeList[0].path);

    if (!foundEntry) {
      Object.assign(currentTree, {
        tree: sortTree(currentTree.tree.concat(data.treeList)),
      });
    }
  },
  [types.UPDATE_TEMP_FLAG](state, { path, tempFile }) {
    Object.assign(state.entries[path], {
      tempFile,
      changed: tempFile,
    });
  },
  [types.UPDATE_VIEWER](state, viewer) {
    Object.assign(state, {
      viewer,
    });
  },
  [types.UPDATE_DELAY_VIEWER_CHANGE](state, delayViewerUpdated) {
    Object.assign(state, {
      delayViewerUpdated,
    });
  },
  [types.UPDATE_ACTIVITY_BAR_VIEW](state, currentActivityView) {
    Object.assign(state, {
      currentActivityView,
    });
  },
  [types.SET_EMPTY_STATE_SVGS](
    state,
    {
      emptyStateSvgPath,
      noChangesStateSvgPath,
      committedStateSvgPath,
      pipelinesEmptyStateSvgPath,
      promotionSvgPath,
    },
  ) {
    Object.assign(state, {
      emptyStateSvgPath,
      noChangesStateSvgPath,
      committedStateSvgPath,
      pipelinesEmptyStateSvgPath,
      promotionSvgPath,
    });
  },
  [types.TOGGLE_FILE_FINDER](state, fileFindVisible) {
    Object.assign(state, {
      fileFindVisible,
    });
  },
  [types.UPDATE_FILE_AFTER_COMMIT](state, { file, lastCommit }) {
    const changedFile = state.changedFiles.find(f => f.path === file.path);
    const { prevPath } = file;

    Object.assign(state.entries[file.path], {
      raw: file.content,
      changed: Boolean(changedFile),
      lastCommitSha: lastCommit.commit.id,

      prevId: undefined,
      prevPath: undefined,
      prevName: undefined,
      prevParentPath: undefined,
    });

    if (prevPath) {
      // Update URLs after file has moved
      const regex = new RegExp(`${prevPath}$`);

      Object.assign(state.entries[file.path], {
        rawPath: file.rawPath.replace(regex, file.path),
      });
    }
  },
  [types.SET_LINKS](state, links) {
    Object.assign(state, { links });
  },
  [types.CLEAR_PROJECTS](state) {
    Object.assign(state, { projects: {}, trees: {} });
  },
  [types.SET_ERROR_MESSAGE](state, errorMessage) {
    Object.assign(state, { errorMessage });
  },
  [types.DELETE_ENTRY](state, path) {
    const entry = state.entries[path];
    const { tempFile = false } = entry;
    const parent = entry.parentPath
      ? state.entries[entry.parentPath]
      : state.trees[`${state.currentProjectId}/${state.currentBranchId}`];

    entry.deleted = true;

    if (parent) {
      parent.tree = parent.tree.filter(f => f.path !== entry.path);
    }

    if (entry.type === 'blob') {
      if (tempFile) {
        state.changedFiles = state.changedFiles.filter(f => f.path !== path);
      } else {
        state.changedFiles = state.changedFiles.concat(entry);
      }
    }
  },
  [types.RENAME_ENTRY](state, { path, name, parentPath }) {
    const oldEntry = state.entries[path];
    const newPath = parentPath ? `${parentPath}/${name}` : name;
    const isRevert = newPath === oldEntry.prevPath;

    const baseProps = {
      ...oldEntry,
      name,
      id: newPath,
      path: newPath,
      parentPath: parentPath || '',
    };

    const prevProps =
      oldEntry.tempFile || isRevert
        ? {
            prevId: undefined,
            prevPath: undefined,
            prevName: undefined,
            prevParentPath: undefined,
          }
        : {
            prevId: oldEntry.prevId || oldEntry.id,
            prevPath: oldEntry.prevPath || oldEntry.path,
            prevName: oldEntry.prevName || oldEntry.name,
            prevParentPath: oldEntry.prevParentPath || oldEntry.parentPath,
          };

    Vue.set(state.entries, newPath, {
      ...baseProps,
      ...prevProps,
    });

    if (pathsAreEqual(oldEntry.parentPath, parentPath)) {
      swapInParentTreeWithSorting(state, oldEntry.id, newPath, parentPath);
    } else {
      removeFromParentTree(state, oldEntry.id, oldEntry.parentPath);
      swapInParentTreeWithSorting(state, oldEntry.id, newPath, parentPath);
    }

    if (oldEntry.type === 'blob') {
      updateFileCollections(state, oldEntry.id, newPath);
    }

    Vue.delete(state.entries, oldEntry.path);
  },

  ...projectMutations,
  ...mergeRequestMutation,
  ...fileMutations,
  ...treeMutations,
  ...branchMutations,
};
