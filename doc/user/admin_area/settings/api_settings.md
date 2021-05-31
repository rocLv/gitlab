---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# API settings **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/330519) in GitLab 14.0.

GitLab administrators can change specific settings in the API.

To access the API settings:

1. Sign in to GitLab as a user with administrator [permissions](../../permissions.md).
1. Go to **Admin Area > Settings > General**.
1. Expand the **API settings controls** section.

## Allow unscoped issue lists via API

In an environment with many issues, listing them or even gathering statistics can take a long time unless
some basic filtering is provided.

The following endpoints accept the `scope` parameter with the `all` option:

```plaintext
GET /api/v4/issues?scope=all
GET /api/v4/issues_statistics?scope=all
```

`scope=all` returns all the issues you have access to, even for unauthenticated requests (public issues).

Allow unscoped issue lists via API is enabled by default. Disabling it causes requests using the `scope=all` parameter to
return an error if no additional filtering parameters are provided. You must provide at least one of the following
when this setting is disabled:

- `assignee_id`
- `assignee_username`
- `author_id`
- `author_username`
- `epic_id` (available if you have access to [Epics](../../group/epics/index.md))
- `iteration_id` (available if you have access to [Iterations](../../group/iterations/index.md))
- `iteration_title` (available if you have access to [Iterations](../../group/iterations/index.md))
- `labels`
- `milestone`
