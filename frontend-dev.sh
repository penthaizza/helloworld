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

# cleanup(){
#     echo "Cleanup all stack"
#     ecs-cli compose --project-name ecsdemo-frontend service rm --delete-namespace --cluster-config ecscleanup-demo
#     aws cloudformation delete-stack --stack-name ecs-demo-alb
#     aws cloudformation wait stack-delete-complete --stack-name ecs-demo-alb
#     aws cloudformation delete-stack --stack-name ecs-demo
# }

createenv(){
    aws cloudformation deploy --stack-name ecs-demo --template-file private-vpc.yml --capabilities CAPABILITY_IAM
    aws cloudformation deploy --stack-name ecs-demo-alb --template-file alb-external.yml
}

setenv(){
    export clustername=$(aws cloudformation describe-stacks --stack-name ecs-demo --query 'Stacks[0].Outputs[?OutputKey==`ClusterName`].OutputValue' --output text)
    export target_group_arn=$(aws cloudformation describe-stack-resources --stack-name ecs-demo-alb | jq -r '.[][] | select(.ResourceType=="AWS::ElasticLoadBalancingV2::TargetGroup").PhysicalResourceId')
    export vpc=$(aws cloudformation describe-stacks --stack-name ecs-demo --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' --output text)
    export ecsTaskExecutionRole=$(aws cloudformation describe-stacks --stack-name ecs-demo --query 'Stacks[0].Outputs[?OutputKey==`ECSTaskExecutionRole`].OutputValue' --output text)
    export subnet_1=$(aws cloudformation describe-stacks --stack-name ecs-demo --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnetOne`].OutputValue' --output text)
    export subnet_2=$(aws cloudformation describe-stacks --stack-name ecs-demo --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnetTwo`].OutputValue' --output text)
    export subnet_3=$(aws cloudformation describe-stacks --stack-name ecs-demo --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnetThree`].OutputValue' --output text)
    export security_group=$(aws cloudformation describe-stacks --stack-name ecs-demo --query 'Stacks[0].Outputs[?OutputKey==`ContainerSecurityGroup`].OutputValue' --output text)
}

ecsconfigure(){
    echo "Configure the Amazon ECS CLI"
    ecs-cli configure --region $AWS_DEFAULT_REGION --cluster ecs-demo --default-launch-type FARGATE --config-name ecs-demo
}

authorizetraffic(){
    echo "Authorize traffic"
    aws ec2 authorize-security-group-ingress --group-id "$security_group" --protocol tcp --port 3000 --cidr 0.0.0.0/0
}
 
ecsdeploy(){
    echo "Deploy and View running container"
    ecs-cli compose --project-name ecsdemo-frontend service up \
        --create-log-groups \
        --target-group-arn $target_group_arn \
        --private-dns-namespace service \
        --enable-service-discovery \
        --container-name ecsdemo-frontend \
        --container-port 3000 \
        --cluster-config ecs-demo \
        --vpc $vpc
    ecs-cli compose --project-name ecsdemo-frontend service ps \
        --cluster-config ecs-demo
    alb_url=$(aws cloudformation describe-stacks --stack-name ecs-demo-alb --query 'Stacks[0].Outputs[?OutputKey==`ExternalUrl`].OutputValue' --output text)
    echo "Open $alb_url in your browser"
}

scaletasks(){
    echo "Scale container"
    ecs-cli compose --project-name ecsdemo-frontend service scale 3 \
        --cluster-config ecs-demo
    ecs-cli compose --project-name ecsdemo-frontend service ps \
        --cluster-config ecs-demo   
}


installnodepend
installaws
installdocker
setawsenv
installecs
pushtoecr
# cleanup
createenv
setenv
ecsconfigure
authorizetraffic
ecsdeploy
scaletasks