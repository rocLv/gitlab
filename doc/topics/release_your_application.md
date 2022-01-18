---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Deploy and release your application **(FREE)**

Deploy your application internally or to the public. Use
flags to release features incrementally.

## Deployments

Deployment is the step of the software delivery process when your application gets deployed to its
final, target infrastructure.

### Deploy with Auto DevOps

[Auto DevOps](autodevops/index.md) is an automated CI/CD-based workflow that supports the entire software
supply chain: build, test, lint, package, deploy, secure, and monitor applications using GitLab CI/CD.
It provides a set of ready-to-use templates that serve the vast majority of use cases.

[Auto Deploy](autodevops/stages.md#auto-deploy) is the DevOps stage dedicated to software
deployment using GitLab CI/CD.

### Deploy applications to Kubernetes clusters

With the extensive integration between GitLab and Kubernetes, you can safely deploy your applications
to Kubernetes clusters using the [GitLab Agent](../user/clusters/agent/install/index.md).

#### GitOps deployments **(PREMIUM)**

With the [GitLab Agent](../user/clusters/agent/install/index.md), you can perform pull-based
deployments using Kubernetes manifests. This provides a scalable, secure, and cloud-native
approach to manage Kubernetes deployments.

#### Deploy to Kubernetes with the CI/CD Tunnel

With the [GitLab Agent](../user/clusters/agent/install/index.md), you can perform push-based
deployments with the [CI/CD Tunnel](../user/clusters/agent/ci_cd_tunnel.md). It provides
a secure and reliable connection between GitLab and your Kubernetes cluster.

### Deploy to AWS with GitLab CI/CD

GitLab provides Docker images that you can use to run AWS commands from GitLab CI/CD, and a template to
facilitate [deployment to AWS](../ci/cloud_deployment). Moreover, Auto Deploy has built-in support
for EC2 and ECS deployments.

### General software deployment with GitLab CI/CD

You can use GitLab CI/CD to target any type of infrastructure accessible by the GitLab Runner.
[User and pre-defined environment variables](../ci/variables/index.md) and CI/CD templates
support setting up a vast number of deployment strategies.

## Environments

To keep track of your deployments and gain insights into your infrastructure, we recommend
connecting them to [a GitLab Environment](../ci/environments/index.md).

## Releases

Use GitLab [Releases](../user/project/releases/index.md) to plan, build, and deliver your applications.

### Feature flags

Use [feature flags](../operations/feature_flags.md) to control and strategically roullout application deployments.
