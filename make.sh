#!/usr/bin/env bash 
[[ $3 ]] || {
    echo "  USAGE: ${BASH_SOURCE##*/} "'build|inspect|push|run '"APP VER COMMIT" >&2 
    echo '         (Build definition is at APP.oci)' >&2 
    echo "         ${BASH_SOURCE##*/} scan IMAGE" >&2 

    exit 11
}
repo=gd9h
app=$2
ver=$3
commit=$4
date=$(stat --format=%y trivy*$app*.log 2>/dev/null |cut -d' ' -f1 |head -n1)
[[ $date ]] || date=$(date -Id)
tag="${ver}-patch-${date//-/}"

scan(){
    fname=${1////.}
    trivy image --scanners vuln --severity 'CRITICAL,HIGH' $1 \
        |tee trivy.${fname//:/_}.log
}
build(){
    [[ -f $app.oci ]] || return 22
    docker build \
        --build-arg force_rebuild="$(date +%s)" \
        --build-arg VERSION="$ver" \
        --build-arg TAG="$tag" \
        --build-arg DATE="$(date -Id)" \
        --build-arg IMAGE_TARGET="$repo/$app:$tag" \
        --build-arg COMMIT="$commit" \
        -t $repo/$app:$tag \
        -f $app.oci .

    scan $repo/$app $tag
}
inspect(){
    type -t yq >/dev/null 2>&1 && {
        docker image inspect $repo/$app:$tag \
            |yq eval -P -o yaml \
            |yq '.[] | (.RepoTags,.RepoDigests,.Config)'

        return $?  
    }
    type -t jq >/dev/null 2>&1 && {
        docker image inspect $repo/$app:$tag |jq '.[] | {
            "Tags": .RepoTags,
            "Digests": .RepoDigests,
            "Config": .Config
        }'
        return $?
    }
    docker image inspect "$repo/$app:$tag"
}
push(){
    docker push $repo/$app:$tag || return 33
    docker tag $repo/$app:$tag $repo/$app:latest
    docker push $repo/$app:latest || return 34
}
run(){
    shift;shift
    docker run -it --rm --name $app $repo/$app:$tag "$@" 
}

"$@" || echo "❌  ERR : $?" >&2
