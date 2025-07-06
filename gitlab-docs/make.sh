#!/usr/bin/env bash 
## Gitlab Product Documentation : OCI Container Image 
## The container runs a static website served by NGINX on Alpine.
## Images: https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/container_registry/8244403
## How to: https://docs.gitlab.com/administration/docs_self_host/#self-host-the-product-documentation-with-docker

app='gitlab-docs'
ver='18.1'
repo=gd9h/$app
date=$(stat --format=%y trivy*-patch-*.log 2>/dev/null |cut -d' ' -f1)
[[ $date ]] || date=$(date -Id)
tag="${ver}-patch-${date//-/}"

build(){
    docker build \
        --build-arg FORCE_REBUILD="$(date +%s)" \
        --build-arg VERSION="$ver" \
        --build-arg DATE="$(date -Id)" \
        --build-arg IMAGE="$repo:$tag" \
        -t $repo:$tag \
        -f $app.oci  .
}
inspect(){
    type -t jq >/dev/null 2>&1 &&
        docker image inspect $repo:$tag \
            |jq '.[] | {
                    "ID":.Id,
                    "Tags":.RepoTags,
                    "Digests":.RepoDigests,
                    "Config":.Config
            }' || docker image inspect "$repo:$tag"
}
scan(){
    trivy image --scanners vuln --severity 'CRITICAL,HIGH' $repo:$tag \
        |tee trivy.${repo////.}_$tag.log
}
push(){
    docker push $repo:$tag
}
run(){
    docker run -it --rm --name $app $repo:$tag "$@" 
}

"$@" || echo "  ERR : $?"
