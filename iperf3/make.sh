#!/usr/bin/env bash 
## See age repo (our fork) @ GOPATH
app='iperf'
#revision=9dbe722df9bac0dc2f49db53d19eb1c3ecd0b273
ver='3.19'
repo=gd9h/$app
tag="${ver}-hard"

build(){
    oci=$app.oci
    args="--build-arg FORCE_REBUILD=$(date +%s) --build-arg DATE=$(date -Id) --build-arg VERSION=$ver --build-arg REVISION=$revision"
    docker build $args -f $oci -t $repo:$tag .
}

run(){
    #[[ $1 ]] && docker run -it --rm --name $app $repo:$tag "$@" 
    #[[ $1 ]] || docker run -it --rm --name $app -v ~/.ssh:/mnt $repo:$tag --decrypt -i /mnt/gitlab_sempernow -o - /mnt/pem/file.xpc.pem
    docker run -it --rm --name $app $repo:$tag "$@" 
}

"$@" || echo "  ERR : $?"

