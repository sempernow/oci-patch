#!/usr/bin/env bash 
[[ $3 ]] || {
    echo "⚠️  Missing required ARGs" >&2 

    exit 11
}
app=$2
ver=$3
repo=gd9h/$app
date=$(stat --format=%y trivy*$app*.log 2>/dev/null |cut -d' ' -f1 |head -n1)
[[ $date ]] || date=$(date -Id)
tag="${ver}-patch-${date//-/}"

build(){
    [[ -f $app.oci ]] || return 22
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
    docker push $repo:$tag || return 33
}
run(){
    docker run -it --rm --name $app $repo:$tag "$3" 
}

"$@" || echo "❌  ERR : $?" >&2
