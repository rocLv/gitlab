---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# Review a merge request **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216054) in GitLab 13.5.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/245190) in GitLab 13.9.

[Merge requests](../index.md) are the primary way to change files in a
GitLab project. [Create and submit a merge request](../creating_merge_requests.md)
to propose changes. Your team [comments](../../../discussions/index.md) on
your merge request. They [suggest code changes](suggestions.md) you can accept
from the user interface. When your work is reviewed, your team members can choose
to accept or reject it.

## Review a merge request

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/4213) in GitLab Premium 11.4.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/28154) to GitLab Free in 13.1.

When you review a merge request, you can create comments that are visible only
to you. When you're ready, publish them all at once. To start your review:

1. Go to the merge request you want to review. Select the **Changes** tab.
   To learn how to navigate the diffs displayed in this tab, read
   [Changes tab in merge requests](../changes.md).
1. To expand the diff lines and display a comment box, select **Comment** (**{comment}**)
   in the gutter. In GitLab version 13.2 and later, you can
   [select multiple lines](#comment-on-multiple-lines).
1. Write your first comment. Below your comment, select **Start a review**:
   ![Starting a review](img/mr_review_start.png)
1. Continue adding comments to lines of code. When you write a comment, you can select:
   - **Add to review**: Keep this comment private and add to the current review.
     These review comments are marked **Pending**. Only you can see them.
   - **Add comment now**: Submit this comment as a regular comment, and not part of the review.
1. (Optional) You can use [quick actions](../../quick_actions.md) inside review comments.
   The comment shows the actions to perform after you publish your review. They are not performed
   until you submit your review.
1. When your review is complete, you can [submit the review](#submit-a-review):
   - Your comments are published.
   - Any [quick actions](../../quick_actions.md) in your comments are performed.

[In GitLab 13.10 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/292936),
if you [approve a merge request](../approvals/index.md#approve-a-merge-request) and
are shown in the reviewer list, a green check mark (**{check-circle-filled}**)
displays next to your name.

### Submit a review

To submit your completed review:

- Use the `/submit_review` [quick action](../../quick_actions.md) in the text of a non-review comment.
- When you create a review comment, select **Submit review**.
- Scroll to the bottom of the screen and select **Submit review**.

GitLab then:

- Publishes the comments in your review.
- Sends a single email to every notifiable user of the merge request. Your review comments
  are attached. You can create a new comment on the merge request by replying to this email.
- Performs any quick actions in your review comments.

### Resolve or unresolve thread with a comment

Review comments can also resolve or unresolve [discussion threads](../../../discussions/index.md#resolve-a-thread)).
When you reply to a comment, you can select a checkbox to resolve or unresolve
the thread when your comment is published:

![Resolve checkbox](img/mr_review_resolve.png)

Pending comments that resolve or unresolve a thread show a check mark (**{check-circle-filled}**) on the comment:

![Resolve status](img/mr_review_resolve2.png)

![Unresolve status](img/mr_review_unresolve.png)

### Add a new comment

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/8225) in GitLab 13.10.

If you have a review in progress, you can **Add to review**:

![New thread](img/mr_review_new_comment_v13_11.png)

### Approval rule information for reviewers **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/233736) in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/293742) in GitLab 13.9.

When you edit the **Reviewers** field in a merge request, GitLab
shows the name of the matching [approval rule](../approvals/rules.md)
below the name of each suggested reviewer. [Code Owners](../../code_owners.md) are
displayed as `Codeowner` without group detail:

- Reviewers and approval rules when you create a new merge request:
  ![Reviewer approval rules in new or edit form](img/reviewer_approval_rules_form_v13_8.png)
- Reviewers and approval rules in a merge request sidebar:
  ![Reviewer approval rules in sidebar](img/reviewer_approval_rules_sidebar_v13_8.png)

### Request a new review

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/293933) in GitLab 13.9.

After a reviewer completes their [merge request reviews](../../../discussions/index.md),
the merge request author can request a new review:

1. If the right sidebar in the merge request is collapsed, select
   **Expand Sidebar** (**{chevron-double-lg-left}**) to expand it.
1. Scroll to **Reviewers**. Select **Re-request a review** (**{redo}**)
   next to the reviewer's name.

GitLab creates a new [to-do item](../../../todos.md) for the reviewer, and sends
them a notification email.

## Semi-linear history merge requests

A merge commit is created for every merge. However, the branch merges only if
a fast-forward merge is possible. This ensures that if the merge request build
succeeded, the target branch build also succeeds after the merge.

1. Go to your project. Select **Settings > General**.
1. Expand **Merge requests**.
1. In the **Merge method** section, select **Merge commit with semi-linear history**.
1. Select **Save changes**.

## Comment on multiple lines

> - [Introduced](https://gitlab.com/gitlab-org/ux-research/-/issues/870) in GitLab 13.2.
> - [Added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49875) click-and-drag features in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/299121) in GitLab 13.9.

When you comment on a diff, you can select the lines of code your comment refers
to by either:

![Comment on any diff file line](img/comment-on-any-diff-line_v13_10.png)

- Dragging the **Comment** (**{comment}**) icon in the gutter to highlight
  lines in the diff. GitLab expands the diff lines and displays a comment box.
- After starting a comment:
  1. Select the **{comment}** **comment** icon in the gutter.
  1. In **Commenting on lines**, select the first line number your comment refers to.

  New comments default to one-line comments, unless you select a different starting line.

Multi-line comments show the comment's line numbers above the comment body:

![Line numbers shown above comment](img/multiline-comment-saved.png)

## Bulk edit merge requests at the project level

Users with permission level of [Developer or higher](../../../permissions.md) can manage merge requests.

When you bulk edit merge requests in a project, you can edit these attributes:

- Status (open or closed)
- Assignee
- Milestone
- Labels
- Subscriptions

To update multiple project merge requests at once:

1. In a project, go to **Merge requests**.
1. Select **Edit merge requests**. A sidebar on the right-hand side of your screen appears with
   editable fields.
1. Select the checkboxes next to each merge request to edit.
1. Select fields and their values from the sidebar.
1. Select **Update all**.

## Bulk edit merge requests at the group level

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12719) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.2.

Users with permission level of [Developer or higher](../../../permissions.md) can manage merge requests.
When you bulk edit merge requests in a group, you can edit:

- Milestones.
- Labels.

To bulk edit merge requests:

1. In a group, go to **Merge requests**.
1. Select **Edit merge requests**. A sidebar on the right-hand side of your screen appears with
   editable fields.
1. Select the checkboxes next to each merge request to edit.
1. Select the fields and their values from the sidebar.
1. Select **Update all**.

## Associated features

These features are related to merge requests:

- [Cherry-pick changes](../cherry_pick_changes.md):
  Select **Cherry-pick** in a merged commit or merge request to cherry-pick any commit in the UI.
- [Fast-forward merge requests](../fast_forward_merge.md):
  For a linear Git history. Also provides a way to accept merge requests without creating merge commits.
- [Find the merge request that introduced a change](../versions.md):
  When you view a commit's Details page, GitLab links to the commit's merge request.
- [Merge requests versions](../versions.md):
  Compare versions of merge request diffs.
- [Resolve conflicts](../resolve_conflicts.md):
  Resolve some merge request conflicts in the GitLab UI.
- [Revert changes](../revert_changes.md):
  Revert changes from any commit from a merge request.
- [Keyboard shortcuts](../../../shortcuts.md#issues-and-merge-requests):
  Access and modify specific parts of a merge request with keyboard commands.

## Troubleshooting

If things don't go as expected in a merge request, try these steps.

### Merge request cannot retrieve the pipeline status

This can occur if Sidekiq doesn't pick up the changes fast enough.

#### Sidekiq

Sidekiq didn't process the CI state change fast enough. Wait a few
seconds for the status to update.

#### Bug

Merge request pipeline statuses can't be fetched when the following occurs:

1. A merge request is created
1. The merge request is closed
1. Changes are made in the project
1. The merge request is reopened

To retrieve the pipeline status, close and reopen the merge request.

## Tips

These tips can help you be more efficient with merge requests in the command line.

### Copy the branch name for local checkout

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23767) in GitLab 13.4.

The merge request sidebar contains the branch reference for the source branch
used containing this merge request's changes.

To copy the branch reference into your clipboard, select **Copy branch name**
(**{copy-to-clipboard}**) in the right sidebar. To check out the branch locally,
run `git checkout <branch-name>` from the command line.

### Check out merge requests locally through the `head` ref

A merge request contains both:

- All the history from a repository.
- The proposed commits from the merge request branch.

You can check out a merge request locally even if the source
project is a fork (even a private fork) of the target project.

This relies on the merge request `head` ref (`refs/merge-requests/:iid/head`)
available for each merge request. With the `ref`, you can check out a merge
request with its ID instead of its branch.

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/223156) in GitLab
13.4, the `head` ref for a merge request is deleted 14 days after the merge request
is closed or merged. After the `head` ref is deleted, you can't check out the merge request
from the `head` ref any more. You can still reopen the merge request. If the merge request's
branch exists, you can still check out the branch. The branch isn't affected.

#### Check out locally by adding a Git alias

Add this alias to your `~/.gitconfig`:

```plaintext
[alias]
    mr = !sh -c 'git fetch $1 merge-requests/$2/head:mr-$1-$2 && git checkout mr-$1-$2' -
```

With this alias, you can check out a merge request from any repository and any
remote. To check out the merge request with ID `5` from the `origin` remote:

```shell
git mr origin 5
```

This fetches the merge request into a local `mr-origin-5` branch and checks
it out.

#### Check out locally by modifying `.git/config` for a repository

In your `.git/config` file, find the section for your GitLab remote, like this:

```plaintext
[remote "origin"]
  url = https://gitlab.com/gitlab-org/gitlab-foss.git
  fetch = +refs/heads/*:refs/remotes/origin/*
```

To open the file:

```shell
git config -e
```

Add the following line to the section:

```plaintext
fetch = +refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

It should look like this:

```plaintext
[remote "origin"]
  url = https://gitlab.com/gitlab-org/gitlab-foss.git
  fetch = +refs/heads/*:refs/remotes/origin/*
  fetch = +refs/merge-requests/*/head:refs/remotes/origin/merge-requests/*
```

Now you can fetch all the merge requests:

```shell
git fetch origin

...
From https://gitlab.com/gitlab-org/gitlab-foss.git
 * [new ref]         refs/merge-requests/1/head -> origin/merge-requests/1
 * [new ref]         refs/merge-requests/2/head -> origin/merge-requests/2
...
```

To check out a specific merge request:

```shell
git checkout origin/merge-requests/1
```

The [`git-mr`](https://gitlab.com/glensc/git-mr) script can do all of these commands.
