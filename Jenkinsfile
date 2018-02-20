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
    mv Dockerfile ../'''
        sh ''' echo Building docker image...
    docker build . --build-arg port=${APP_PORT} -t ${PROJECT_NAME}
    docker save -o ${PROJECT_NAME}.tar ${PROJECT_NAME}:latest
    gzip ${PROJECT_NAME}.tar
    '''
    }
    stage("Plan cloud infrastructre") {
        sh '''
echo Planning cloud infrastructre
cd ./ct_node_basic/infrastructure
terraform init
terraform plan -var stack=${STACK} -var aws_access_key=${AWS_ACCESS_KEY} -var aws_secret_key=${AWS_SECRET_KEY} -var git_project=${PROJECT_NAME} -var port=${APP_PORT} -var version=${VERSION} -var region=${REGION} '''
    }
    stage("Build cloud infrastructre") {
        sh ''' cd ./ct_node_basic/infrastructure
terraform apply -auto-approve -var stack=${STACK} -var aws_access_key=${AWS_ACCESS_KEY} -var aws_secret_key=${AWS_SECRET_KEY} -var git_project=${PROJECT_NAME} -var port=${APP_PORT} -var version=${VERSION} -var region=${REGION} . '''
    }
    stage("Destroy") {
        try {
            timeout(time: 5, unit: 'MINUTES') {
                // change to a convenient timeout for you
                userInput = input(id: 'Proceed1', message: 'Was this successful?',
                        parameters: [[$class: 'BooleanParameterDefinition', defaultValue: true, description: '', name: 'Please confirm you agree with this']])
            }
        }
        catch (err) {
            // timeout reached or input false
            def user = err.getCauses()[0].getUser()
            if ('SYSTEM' == user.toString()) {
                // SYSTEM means timeout.
                didTimeout = true
            } else {
                userInput = false echo "Aborted by: [${user}]"
            }
        }
        if (userInput == true) {
            sh '''
        cd ./ct_node_basic/infrastructure
         terraform destroy -force -var stack=${STACK} -var aws_access_key=${AWS_ACCESS_KEY} -var aws_secret_key=${AWS_SECRET_KEY} -var git_project=${PROJECT_NAME} -var port=${APP_PORT} -var version=${VERSION} -var region=${REGION}
         '''
        }
    }
}