#!/usr/bin/env bash
## GitLab Product Documentation v18.1
img=registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:18.1
patch='patch-0.0.1'
app=gdocs

## Patch CVEs reported by trivy scan 

mkdir -p gitlab-product-doc
pushd gitlab-product-doc/

## 1. Pull the base image
docker pull $img
## Save IMAGE_ID NAME:TAG
dit |grep technical-writing |tee image.log
## Scan for CVEs
trivy image $img |tee trivy.log
## Create the build definition of the patch
tee dockerfile <<EOH
FROM $img 

USER root

## Upgrade libxml2 to a fixed version (2.13.4-r6 or later)
RUN apk update && \
    apk upgrade libxml2 && \
    apk info -v libxml2 | grep libxml2

EOH

## Build patched image
docker build -t $img-$patch . 

## Verify patched version 
docker run --rm $img-$patch apk info -ev libxml2

## Verify patch is effective
trivy image $img-$patch |tee trivy-$patch.log

## Run the patched image 
docker run -d --rm --name $app -p 4000:4000 $img-$patch

## Smoke test : Print the process (Want match that of FROM image)
docker exec -it $app ps 

# Smoke test : GET the landing page : /18.1/
curl -IX GET http://localhost:4000/18.1/

# Smoke test : Show logs
docker logs $app

## Teardown (redundant)
docker container stop $app 2>/dev/null
docker container rm $app 2>/dev/null


