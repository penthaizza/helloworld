#!/bin/bash
installaws(){
    echo "Install awscli"
    pip install awscli
    pip install awscli --upgrade
    echo "Check Version AWS CLI"
    aws --version
}

installdocker(){
    echo "Install Docker"
    set -x
    VER="18.09.7"
    curl -L -o /tmp/docker-$VER.tgz https://download.docker.com/linux/static/stable/x86_64/docker-$VER.tgz
    tar -xz -C /tmp -f /tmp/docker-$VER.tgz
    mv /tmp/docker/* /usr/bin
}

setawsenv(){
    echo "Set configure AWS"
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
    aws configure set default.region $AWS_DEFAULT_REGION
}

pushtoecr(){
    echo "Build & Push to ECR"
    $(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)
    docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$FRONTEND_MICRO:$(git rev-parse --short HEAD) .
    docker tag $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$FRONTEND_MICRO:$(git rev-parse --short HEAD) $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$FRONTEND_MICRO:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$FRONTEND_MICRO
}

installaws
installdocker
setawsenv
pushtoecr