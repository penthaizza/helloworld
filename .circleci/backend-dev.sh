#!/bin/bash
echo "Install Python"
sudo yum install python

echo "Download pip"
sudo curl -O https://bootstrap.pypa.io/get-pip.py

echo "Install pip"
sudo python get-pip.py

echo "Check Version pip"
sudo pip --version

echo "Install awscli"
sudo pip install awscli
sudo pip install awscli --upgrade

echo "Check Version AWS CLI"
sudo aws --version

echo "Install Docker"
sudo yum remove -y docker \
                   docker-client \
                   docker-client-latest \
                   docker-common \
                   docker-latest \
                   docker-latest-logrotate \
                   docker-logrotate \
                   docker-engine
sudo yum install -y yum-utils \
  		    device-mapper-persistent-data \
  		    lvm2
sudo yum-config-manager \
     --add-repo \
     https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker

echo "Set configure AWS"
sudo aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
sudo aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
sudo aws configure set default.region $AWS_DEFAULT_REGION

echo "Build & Push to ECR"
sudo $(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)
sudo docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$AWS_RESOURCE_NAME_PREFIX:$(git rev-parse --short HEAD) .
sudo docker tag $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$AWS_RESOURCE_NAME_PREFIX:$(git rev-parse --short HEAD) $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$AWS_RESOURCE_NAME_PREFIX:latest
sudo docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$AWS_RESOURCE_NAME_PREFIX
