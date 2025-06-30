FROM registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:18.1 

USER root

## Upgrade apk index, then install latest version of declared package and report the version
RUN apk update &&     apk upgrade libxml2 &&     apk info -v libxml2 |grep libxml2

