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
        sh 'git clone https://github.com/premutos2003/ct_node_mongo.git'
    }
    stage("Build Docker image/artifact") {
        sh '''#!/bin/bash -xe
    mv ./ct_node_mongo/Dockerfile ./
    mv ./ct_node_mongo/infrastructure/docker-compose.yml ./
    cd app
    entrypoint=$(jq -r .scripts.start package.json)
if [ "$entrypoint" = "null" ];then
	echo no start script
	entrypoint=$(jq -r .main package.json)
	if [ "$entrypoint" != "null" ];then
		echo $entrypoint main entrypoint
		entrypoint="pm2 start $entrypoint -i max  --no-daemon"
	else
		echo no main
		if [ -e index.js ];then
			entrypoint="pm2 start index.js -i max  --no-daemon"
			echo index.js found $entrypoint
		else
			echo no index.js found
			if [ -e app.js ];then
				entrypoint="pm2 start app.js -i max  --no-daemon"
				echo app.jws found $entrypoint
			else
				echo no app.js found
				if [ -e server.js ];then
					entrypoint="pm2 start server.js -i max  --no-daemon"
					echo server.js found $entrypoint
				else
					echo no entrypoint found
				fi
			fi
		fi

	fi
else
if
echo $entrypoint | grep -q node
then
entrypoint=${entrypoint/node/pm2 start}
entrypoint="$entrypoint -i max --no-daemon"
echo $entrypoint
fi
fi
cd ..
    echo Building docker image...
    docker build -t ${PROJECT_NAME}  --build-arg entry="${entrypoint}" --build-arg port=${APP_PORT}  --build-arg folder=app .
    docker save -o ${PROJECT_NAME}.tar ${PROJECT_NAME}:latest
    gzip ${PROJECT_NAME}.tar
    ls
    mv ${PROJECT_NAME}.tar.gz ./ct_node_mongo/infrastructure
    docker rmi ${PROJECT_NAME}
    '''
    }
    stage("Setup Deploy Keys") {
    try{
        sh '''
        export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
        export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}
        echo Planning cloud infrastructre
        str=$(curl -v -sS 'host.docker.internal:3000/envs/${ENV} | jq -r '.[0]')
        kms=$(echo $str | jq -r '.kms')
        region=$(echo $str | jq -r '.region')
        cd ./ct_node_mongo/key
        terraform init
        terraform apply --auto-approve -var stack=${STACK} -var kms_key_arn=${kms} -var aws_access_key=${AWS_ACCESS_KEY} -var aws_secret_key=${AWS_SECRET_KEY} -var git_project=${PROJECT_NAME} -var port=${APP_PORT} -var environment=${ENV} -var version=${VERSION} -var region=$region
        '''
        }
        catch(err){
            terraform destroy -force
        }
    }
    stage("Build cloud infrastructre") {
        sh '''
        amis=[]
        str=$(curl -v -sS 'host.docker.internal:3000/envs/$ENV-$REGION' | jq -r '.[0]')
        kms=$(echo $str | jq -r '.kms')
        region=$(echo $str | jq -r '.region')
        sg_id=$(echo $str | jq -r  '.sg_id')
        ami=$(echo $str | jq -r  '.ami')
        subnet_id=$(echo $str |jq -r '.subnet_id')

        cd ./ct_node_mongo/infrastructure
        ls
        terraform init
        terraform apply -auto-approve -var sec_gp_id=${sg_id} -var kms_key_arn=${kms} -var subnet_id=${subnet_id} -var ami=$ami -var stack=${STACK} -var aws_access_key=${AWS_ACCESS_KEY} -var aws_secret_key=${AWS_SECRET_KEY} -var environment=${ENV} -var git_project=${PROJECT_NAME} -var port=${APP_PORT} -var version=${VERSION} -var region=$region .

        app_instance_ip=$(terraform output -json  | jq -r  '.app_instance_ip.value')
        app_instance_id=$(terraform output -json  | jq -r  '.app_instance_id.value')
        app_id=$(terraform output -json  | jq -r  '.app_id.value')
        stack=$(terraform output -json  | jq -r  '.stack.value')
        region=$(terraform output -json  | jq -r  '.region.value')
        env_id=${ENV}
        id=${PROJECT_NAME}-${ENV}
        curl -X POST -d id=$id -d env_id=$env_id -d app_instance_ip=$app_instance_ip -d app_instance_id=$app_instance_id -d stack=$stack -d app_id=$app_id -d region=$region host.docker.internal:3000/apps/infra/$app_id
       '''
    }
    stage("Push state to storage") {
        sh '''
            app_id=${PROJECT_NAME}-${ENV}
            cd ./ct_node_mongo/infrastructure
            curl -X PUT -d id=$app_id -d status=running host.docker.internal:3000/apps/$app_id
            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}
            aws s3 cp terraform.tfstate s3://app-state-${STACK}-${PROJECT_NAME}/state/terraform.tfstate --region ${REGION}
           cd ../key
           aws s3 cp terraform.tfstate s3://app-state-${STACK}-${PROJECT_NAME}/keystate/terraform.tfstate --region ${REGION}
           '''
    }

}
