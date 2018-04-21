def userInput = true
def didTimeout = false
node {

    stage("Clone app to workspace")
            {
                deleteDir()
                sh 'git clone ${GIT_URL} app'
                sh 'echo cloning app to workspace'
            }
    stage("Clone infrastructure config to workspace") {
        sh 'git clone https://github.com/premutos2003/ct_node_basic.git'
    }
    stage("Build Docker image/artifact") {
        sh '''
    cd ./ct_node_basic


    mv Dockerfile ../
    cd ..
    echo Building docker image...
    docker build . --build-arg port=${APP_PORT}  --build-arg folder=app -t ${PROJECT_NAME}
    docker save -o ${PROJECT_NAME}.tar ${PROJECT_NAME}:latest
    gzip ${PROJECT_NAME}.tar
    ls
    mv ${PROJECT_NAME}.tar.gz ./ct_node_basic/infrastructure
    ls
    '''
    }
    stage("Setup Deploy Keys") {
        sh '''
        export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
        export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}
echo Planning cloud infrastructre
str=$(curl -v -sS 'docker.for.mac.localhost:3000/infra' | jq -r '.[0]')

kms=$(echo $str | jq -r '.kms')
cd ./ct_node_basic/key
terraform init
terraform apply --auto-approve -var stack=${STACK} -var kms_key_arn=${kms} -var aws_access_key=${AWS_ACCESS_KEY} -var aws_secret_key=${AWS_SECRET_KEY} -var git_project=${PROJECT_NAME} -var port=${APP_PORT} -var version=${VERSION} -var region=${REGION} '''
    }


    stage("Build cloud infrastructre") {
        sh '''
        str=$(curl -v -sS 'docker.for.mac.localhost:3000/infra' | jq -r '.[0]')

        kms=$(echo $str | jq -r '.kms')
        sg_id=$(echo $str | jq -r  '.sg_id')
        subnet_id=$(echo $str |jq -r '.subnet_id')

        cd ./ct_node_basic/infrastructure
        ls
        terraform init
        terraform apply -auto-approve -var sec_gp_id=${sg_id} -var kms_key_arn=${kms} -var subnet_id=${subnet_id} -var stack=${STACK} -var aws_access_key=${AWS_ACCESS_KEY} -var aws_secret_key=${AWS_SECRET_KEY} -var git_project=${PROJECT_NAME} -var port=${APP_PORT} -var version=${VERSION} -var region=${REGION} . '''
    }
     stage("Push state to storage") {
            sh '''

            cd ./ct_node_basic/infrastructure

            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}
            sh metadata.sh
            aws s3 cp terraform.tfstate s3://${STACK}-${PROJECT_NAME}/state/terraform.tfstate --region ${REGION}
           '''
        }
}