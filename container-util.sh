#!/bin/bash

# Copyright 2019 Ankur Sinha
# Author: Ankur Sinha <sanjay DOT ankur AT gmail DOT com> 
# File : run-container.sh

# References
# https://hacklog.in/understand-podman-networking/
# 

# Image created as localhost/redmine
image=localhost/redmine
container=redmine-osb-test
# Host port to forward to
host_port=10083
# port redmine is configured on, see Dockerfile
# when running locally with webrick, it always uses 3000
container_port=3000

# Pat of repo on local machine to mount
repo_path="/home/asinha/Documents/02_Code/00_mine/2020-OSB/redmine/"

run_container ()
{
    if [ -f /usr/bin/podman ]; then
        echo ""
        echo "This build script is using Podman to run the build in an isolated environment."
        echo ""
        podman run -it --name="$container" --rm --security-opt label=disable -v "$repo_path:$repo_path" -p $host_port:$container_port "$image"

    elif [ -f /usr/bin/docker ]; then
        echo ""
        echo "This build script is using Docker to run the build in an isolated environment."
        echo ""

        if groups | grep -wq "docker"; then
            docker exec -it "$container" bash
        else
            echo ""
            echo "This build script is using $runtime to run the build in an isolated environment. You might be asked for your password."
            echo "You can avoid this by adding your user to the 'docker' group, but be aware of the security implications. See https://docs.docker.com/install/linux/linux-postinstall/."
            echo ""
            sudo docker exec -it "$container" bash
        fi
    fi
}

build_container ()
{
    if [ -f /usr/bin/podman ]; then
        echo ""
        echo "This build script is using Podman to run the build in an isolated environment."
        echo ""
        podman build --security-opt label=disable -f Dockerfile -v "$repo_path:$repo_path" -t redmine
    elif [ -f /usr/bin/docker ]; then
        echo ""
        echo "This build script is using Docker to run the build in an isolated environment."
        echo ""

        if groups | grep -wq "docker"; then
            docker build -f Dockerfile -t redmine
        else
            echo ""
            echo "This build script is using $runtime to run the build in an isolated environment. You might be asked for your password."
            echo "You can avoid this by adding your user to the 'docker' group, but be aware of the security implications. See https://docs.docker.com/install/linux/linux-postinstall/."
            echo ""
            sudo docker build -f Dockerfile -t redmine
        fi
    fi
}

usage ()
{
    echo "container-util.sh [-b -h -r]"

    echo "Usage:"
    echo
    echo "-b: build container image"
    echo "-r: run container and drop us into a shell into it"
    echo "-h: print this help text and exit"

}

# parse options
while getopts "irbh" OPTION
do
    case $OPTION in
        r)
            run_container
            exit 0
            ;;
        b)
            build_container
            exit 0
            ;;
        h)
            usage
            exit 0
            ;;
        ?)
            echo "Nothing to do."
            usage
            exit 1
            ;;
    esac
done
