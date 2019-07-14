#!/bin/bash
installnodepend(){
    npm install
}

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

installecs(){
    echo "Install ECS_CLI"
    curl -o /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
    chmod +x /usr/local/bin/ecs-cli
    ecs-cli --version
}

pushtoecr(){
    echo "Build & Push to ECR"
    $(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)
    docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$AWS_RESOURCE_NAME_PREFIX:$(git rev-parse --short HEAD) .
    docker tag $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$AWS_RESOURCE_NAME_PREFIX:$(git rev-parse --short HEAD) $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$AWS_RESOURCE_NAME_PREFIX:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$AWS_RESOURCE_NAME_PREFIX
}

ecsconfigure(){
    echo "Configure the Amazon ECS CLI"
    ecs-cli configure --cluster vonder --region $AWS_DEFAULT_REGION --default-launch-type FARGATE --config-name vonder
    ecs-cli configure profile --access-key $AWS_ACCESS_KEY_ID --secret-key $AWS_SECRET_ACCESS_KEY --profile-name vonder
    ecs-cli up
    ecs-cli compose --project-name vonder service up --create-log-groups --cluster-config vonder
    ecs-cli compose --project-name vonder service ps --cluster-config vonder
    ecs-cli logs --cluster-config vonder --follow --cluster-config vonder
    ecs-cli compose --project-name vonder service scale 2 --cluster-config vonder
    ecs-cli compose --project-name vonder service ps --cluster-config vonder
}
 
ecsdeploy(){
    ecs-cli compose up --create-log-groups --cluster-config vonder
    ecs-cli ps
}

installnodepend
installaws
installdocker
setawsenv
installecs
pushtoecr
ecsconfigure
ecsdeploy