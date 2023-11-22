# Github-actions-terraform-ecs-project

## Overview

This CiCd pipeline project demonstrates the deployment of a dynamic web application on Amazon Web Services (AWS) using Terraform and Docker. The infrastructure is set up using Terraform to create a scalable, fault-tolerant, and highly available environment. The application is then deployed on an Amazon ECS (Elastic Container Service) cluster using Docker containers.

## Infrastructure Components

1. **VPC with Subnets:**
   - Configured a VPC with public and private subnets distributed across two availability zones.

2. **Internet Gateway:**
   - Utilized an Internet Gateway to enable communication between instances in the VPC and the Internet.

3. **Security Groups:**
   - Implemented security groups to control inbound and outbound traffic, acting as a firewall for the infrastructure.

4. **Availability Zones:**
   - Utilized two availability zones to enhance high availability and fault tolerance.

5. **Resources in Public Subnets:**
   - Deployed resources such as NAT Gateway, Bastion Host, and Application Load Balancer in public subnets.

6. **EC2 Instance Connect Endpoint:**
   - Leveraged the EC2 Instance Connect Endpoint for secure and seamless connectivity to resources in public and private subnets.

7. **Private Subnets:**
   - Placed web servers and database servers in private subnets to enhance security.

8. **NAT Gateway:**
   - Enabled instances in private subnets to access the internet using a NAT Gateway.

9. **RDS (Relational Database Service):**
   - Deployed an RDS instance for the dynamic website's database, ensuring scalable and managed database services.

10. **Amazon ECS Cluster:**
    - Created an ECS cluster to host Docker containers for the dynamic web application.

11. **Task Definitions:**
    - Defined ECS task definitions specifying container details, including the Docker image and port mappings.

12. **ECS Service:**
    - Created an ECS service for the ECS cluster, configuring it to run tasks and specifying the desired number of tasks.

13. **Load Balancing and Auto Scaling:**
    - Configured load balancing if required and set up Auto Scaling options and health checks for the ECS service.

14. **Route 53 (Optional):**
    - Configured DNS settings, either within Route 53 or with an external domain registrar, to point to the load balancer or service endpoint.

15. **GitHub:**
    - Stored web files on GitHub for version control and easy deployment.

16. **EC2 Instance AMI Creation:**
    - After installing the website on the EC2 instance, an Amazon Machine Image (AMI) is created for future use.

## Deployment Script

```bash
#!/bin/bash

# This command updates all the packages on the server to their latest versions
sudo yum update -y

# This series of commands installs the Apache web server, enables it to start on boot, and then starts the server immediately
sudo yum install -y httpd
sudo systemctl enable httpd 
sudo systemctl start httpd

## This command installs PHP 8 along with several necessary extensions for the application to run
sudo dnf install -y php8.2 php-cli php-fpm php-mysqlnd php-bcmath php-ctype php-fileinfo php-json php-mbstring php-openssl php-pdo php-gd php-tokenizer php-xml

## These commands Installs MySQL version 8
# Install the MySQL Community repository
sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm 
#
# Install the MySQL server
sudo dnf install -y mysql80-community-release-el9-1.noarch.rpm 
dnf repolist enabled | grep "mysql.*-community.*"
sudo dnf install -y mysql-community-server 
#
# Start and enable the MySQL server
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Install the cURL and PHP cURL packages
sudo yum install -y curl libcurl libcurl-devel php-curl --allowerasing

# Restart the PHP-FPM service to apply the changes
sudo service php-fpm restart

# Update the settings, memory_limit to 128M and max_execution_time to 300 in the php.ini file
sudo sed -i 's/^\s*;\?\s*memory_limit =.*/memory_limit = 128M/' /etc/php.ini
sudo sed -i 's/^\s*;\?\s*max_execution_time =.*/max_execution_time = 300/' /etc/php.ini

# This command enables the 'mod_rewrite' module in Apache on an EC2 Linux instance. It allows the use of .htaccess files for URL rewriting and other directives in the '/var/www/html' directory
sudo sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf


# Install and configure the application.


# This command downloads the contents of the specified S3 bucket to the '/var/www/html' directory on the EC2 instance
sudo aws s3 sync s3://safo-nest /var/www/html

# This command changes the current working directory to '/var/www/html', which is the standard directory for hosting web pages on a Unix-based server
cd /var/www/html

# This command is used to extract the contents of the application code zip file that was previously downloaded from the S3 bucket
sudo unzip nest-app.zip

# This command recursively copies all files, including hidden ones, from the 'nest-app' directory to the '/var/www/html/'.
sudo cp -R nest-app/. /var/www/html/

# This command permanently deletes the 'nest-app' directory and the 'nest-app.zip' file.
sudo rm -rf nest-app nest-app.zip

# This command set permissions 777 for the '/var/www/html' directory and the 'storage/' directory
sudo chmod -R 777 /var/www/html
sudo chmod -R 777 storage/
sudo chown apache:apache -R /var/www/html 

# This command uses `sed` to search the .env file for a line that starts with APP_NAME= and replaces everything after the "=" character with the app's name.
sudo sed -i "/^APP_NAME=/ s/=.*$/=${PROJECT_NAME}-${ENVIRONMENT}/" .env

# This command uses `sed` to search the .env file for a line that starts with APP_URL= and replaces everything after the "=" character with the app's domain name.
sudo sed -i "/^APP_URL=/ s/=.*$/=https:\/\/${RECORD_NAME}.${DOMAIN_NAME}\//" .env

# This command uses `sed` to search the .env file for a line that starts with DB_HOST= and replaces everything after the "=" character with the RDS endpoint.
sudo sed -i "/^DB_HOST=/ s/=.*$/=${RDS_ENDPOINT}/" .env

# This command uses `sed` to search the .env file for a line that starts with DB_DATABASE= and replaces everything after the "=" character with the RDS database name.
sudo sed -i "/^DB_DATABASE=/ s/=.*$/=${RDS_DB_NAME}/" .env

# This command uses `sed` to search the .env file for a line that starts with DB_USERNAME= and replaces everything after the "=" character with the RDS database username.
sudo sed -i "/^DB_USERNAME=/ s/=.*$/=${USERNAME}/" .env

# This command uses `sed` to search the .env file for a line that starts with DB_PASSWORD= and replaces everything after the "=" character with the RDS database password.
sudo sed -i "/^DB_PASSWORD=/ s/=.*$/=${PASSWORD}/" .env

# This command will replace the AppServiceProvider.php file
sudo aws s3 cp s3://appserviceprovider/AppServiceProvider.php /var/www/html/app/Providers/AppServiceProvider.php

#10. enable mod_rewrite on ec2 linux
sudo sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

# This command will restart the Apache server
sudo service httpd restart
```

## Data Migration Script

```bash
 resource "aws_instance" "data_migrate_ec2" {
  ami                    = var.amazon_linux_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.private_app_subnet_az1.id
  vpc_security_group_ids = [aws_security_group.webserver_sg.id, aws_security_group.eice_security_group.id]
  iam_instance_profile   = aws_iam_instance_profile.s3_full_access_instance_profile.id


  user_data = base64encode(templatefile("${path.module}/install-and-configure-nest-app.sh.tpl", {
    RDS_ENDPOINT = aws_db_instance.database_instance.endpoint
    RDS_DB_NAME  = var.RDS_DB_NAME
    USERNAME     = var.USERNAME
    PASSWORD     = var.PASSWORD
    PROJECT_NAME = var.PROJECT_NAME
    ENVIRONMENT  = var.ENVIRONMENT
    RECORD_NAME  = var.RECORD_NAME
    DOMAIN_NAME  = var.DOMAIN_NAME
    
    

  }))

  depends_on = [aws_db_instance.database_instance]

  tags = {
    Name = "nest-ec2-migrate"
  }
}


```

## CiCd Workflow YAML Script

```bash
 
 name: Deploy Pipeline

on:
  push:
    branches: [main]

env: 
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  AWS_REGION: us-east-1
  TERRAFORM_ACTION: destroy
  GITHUB_USERNAME: Olacodes-hub
  REPOSITORY_NAME: application-codes
  WEB_FILE_ZIP: rentzone.zip
  WEB_FILE_UNZIP: rentzone
  FLYWAY_VERSION: 9.8.1

jobs:
  # Configure AWS credentials 
  configure_aws_credentials: 
    name: Configure AWS credentials
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1-node16
        with:
          aws-access-key-id: ${{ env.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ env.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}


  # Build AWS infrastructure
  deploy_aws_infrastructure:
    name: Build AWS infrastructure
    needs: configure_aws_credentials
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.1.7

      - name: Run Terraform initialize
        working-directory: ./iac
        run: terraform init

      - name: Run Terraform apply/destroy
        working-directory: ./iac
        run: terraform ${{ env.TERRAFORM_ACTION }} -auto-approve

      - name: Get Terraform output image name
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          IMAGE_NAME_VALUE=$(terraform output -raw image_name | grep -Eo "^[^:]+" | tail -n 1)
          echo "IMAGE_NAME=$IMAGE_NAME_VALUE" >> $GITHUB_ENV

      - name: Get Terraform output domain name
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          DOMAIN_NAME_VALUE=$(terraform output -raw domain_name | grep -Eo "^[^:]+" | tail -n 1)
          echo "DOMAIN_NAME=$DOMAIN_NAME_VALUE" >> $GITHUB_ENV

      - name: Get Terraform output RDS endpoint
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          RDS_ENDPOINT_VALUE=$(terraform output -raw rds_endpoint | grep -Eo "^[^:]+" | tail -n 1)
          echo "RDS_ENDPOINT=$RDS_ENDPOINT_VALUE" >> $GITHUB_ENV

      - name: Get Terraform output image tag
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          IMAGE_TAG_VALUE=$(terraform output -raw image_tag | grep -Eo "^[^:]+" | tail -n 1)
          echo "IMAGE_TAG=$IMAGE_TAG_VALUE" >> $GITHUB_ENV

      - name: Get Terraform output private data subnet az1 id
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          PRIVATE_DATA_SUBNET_AZ1_ID_VALUE=$(terraform output -raw private_data_subnet_az1_id | grep -Eo "^[^:]+" | tail -n 1)
          echo "PRIVATE_DATA_SUBNET_AZ1_ID=$PRIVATE_DATA_SUBNET_AZ1_ID_VALUE" >> $GITHUB_ENV

      - name: Get Terraform output runner security group id
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          RUNNER_SECURITY_GROUP_ID_VALUE=$(terraform output -raw runner_security_group_id | grep -Eo "^[^:]+" | tail -n 1)
          echo "RUNNER_SECURITY_GROUP_ID=$RUNNER_SECURITY_GROUP_ID_VALUE" >> $GITHUB_ENV

      - name: Get Terraform output task definition name
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          TASK_DEFINITION_NAME_VALUE=$(terraform output -raw task_definition_name | grep -Eo "^[^:]+" | tail -n 1)
          echo "TASK_DEFINITION_NAME=$TASK_DEFINITION_NAME_VALUE" >> $GITHUB_ENV

      - name: Get Terraform output ecs cluster name
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          ECS_CLUSTER_NAME_VALUE=$(terraform output -raw ecs_cluster_name | grep -Eo "^[^:]+" | tail -n 1)
          echo "ECS_CLUSTER_NAME=$ECS_CLUSTER_NAME_VALUE" >> $GITHUB_ENV

      - name: Get Terraform output ecs service name
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          ECS_SERVICE_NAME_VALUE=$(terraform output -raw ecs_service_name | grep -Eo "^[^:]+" | tail -n 1)
          echo "ECS_SERVICE_NAME=$ECS_SERVICE_NAME_VALUE" >> $GITHUB_ENV

      - name: Get Terraform output environment file name
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          ENVIRONMENT_FILE_NAME_VALUE=$(terraform output -raw environment_file_name | grep -Eo "^[^:]+" | tail -n 1)
          echo "ENVIRONMENT_FILE_NAME=$ENVIRONMENT_FILE_NAME_VALUE" >> $GITHUB_ENV

      - name: Get Terraform output env file bucket name
        if: env.TERRAFORM_ACTION == 'apply'
        working-directory: ./iac
        run: |
          ENV_FILE_BUCKET_NAME_VALUE=$(terraform output -raw env_file_bucket_name | grep -Eo "^[^:]+" | tail -n 1)
          echo "ENV_FILE_BUCKET_NAME=$ENV_FILE_BUCKET_NAME_VALUE" >> $GITHUB_ENV

      - name: Print GITHUB_ENV contents
        run: cat $GITHUB_ENV

    outputs:
      terraform_action: ${{ env.TERRAFORM_ACTION }}
      image_name: ${{ env.IMAGE_NAME }}
      domain_name: ${{ env.DOMAIN_NAME }}
      rds_endpoint: ${{ env.RDS_ENDPOINT }}
      image_tag: ${{ env.IMAGE_TAG }}
      private_data_subnet_az1_id: ${{ env.PRIVATE_DATA_SUBNET_AZ1_ID }}
      runner_security_group_id: ${{ env.RUNNER_SECURITY_GROUP_ID }}
      task_definition_name: ${{ env.TASK_DEFINITION_NAME }}
      ecs_cluster_name: ${{ env.ECS_CLUSTER_NAME }}
      ecs_service_name: ${{ env.ECS_SERVICE_NAME }}
      environment_file_name: ${{ env.ENVIRONMENT_FILE_NAME }}
      env_file_bucket_name: ${{ env.ENV_FILE_BUCKET_NAME }}

  
# Create ECR repository
  create_ecr_repository:
    name: Create ECR repository
    needs: 
      - configure_aws_credentials
      - deploy_aws_infrastructure
    if: needs.deploy_aws_infrastructure.outputs.terraform_action != 'destroy'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Check if ECR repository exists
        env:
          IMAGE_NAME: ${{ needs.deploy_aws_infrastructure.outputs.image_name }}
        run: |
          result=$(aws ecr describe-repositories --repository-names "${{ env.IMAGE_NAME }}" | jq -r '.repositories[0].repositoryName')
          echo "repo_name=$result" >> $GITHUB_ENV
        continue-on-error: true

      - name: Create ECR repository
        env:
          IMAGE_NAME: ${{ needs.deploy_aws_infrastructure.outputs.image_name }}
        if: env.repo_name != env.IMAGE_NAME
        run: |
          aws ecr create-repository --repository-name ${{ env.IMAGE_NAME }}


  # Start self-hosted EC2 runner
  start_runner:
    name: Start self-hosted EC2 runner
    needs: 
      - configure_aws_credentials
      - deploy_aws_infrastructure
    if: needs.deploy_aws_infrastructure.outputs.terraform_action != 'destroy'
    runs-on: ubuntu-latest
    steps:
      - name: Check for running EC2 runner
        run: |
          instances=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=ec2-github-runner" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId' --output text)

          if [ -n "$instances" ]; then
            echo "runner-running=true" >> $GITHUB_ENV
          else
            echo "runner-running=false" >> $GITHUB_ENV
          fi

      - name: Start EC2 runner
        if: env.runner-running != 'true'
        id: start-ec2-runner
        uses: machulav/ec2-github-runner@v2
        with:
          mode: start
          github-token: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
          ec2-image-id: ami-01201671df869f81a
          ec2-instance-type: t2.micro
          subnet-id: ${{ needs.deploy_aws_infrastructure.outputs.private_data_subnet_az1_id }}
          security-group-id: ${{ needs.deploy_aws_infrastructure.outputs.runner_security_group_id }}
          aws-resource-tags: > 
            [
              {"Key": "Name", "Value": "ec2-github-runner"},
              {"Key": "GitHubRepository", "Value": "${{ github.repository }}"}
            ]

    outputs:
      label: ${{ steps.start-ec2-runner.outputs.label }}
      ec2-instance-id: ${{ steps.start-ec2-runner.outputs.ec2-instance-id }}


  # Build and push Docker image to ECR
  build_and_push_image:
    name: Build and push Docker image to ECR
    needs:
      - configure_aws_credentials
      - deploy_aws_infrastructure
      - create_ecr_repository
      - start_runner
    if: needs.deploy_aws_infrastructure.outputs.terraform_action != 'destroy'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Login to Amazon ECR
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build Docker image
        env:
          DOMAIN_NAME: ${{ needs.deploy_aws_infrastructure.outputs.domain_name }}
          RDS_ENDPOINT: ${{ needs.deploy_aws_infrastructure.outputs.rds_endpoint }}
          IMAGE_NAME: ${{ needs.deploy_aws_infrastructure.outputs.image_name }}
          IMAGE_TAG: ${{ needs.deploy_aws_infrastructure.outputs.image_name }}
        run: |
          docker build \
          --build-arg PERSONAL_ACCESS_TOKEN=${{ secrets.PERSONAL_ACCESS_TOKEN }} \
          --build-arg GITHUB_USERNAME=${{ env.GITHUB_USERNAME }} \
          --build-arg REPOSITORY_NAME=${{ env.REPOSITORY_NAME }} \
          --build-arg WEB_FILE_ZIP=${{ env.WEB_FILE_ZIP }} \
          --build-arg WEB_FILE_UNZIP=${{ env.WEB_FILE_UNZIP }} \
          --build-arg DOMAIN_NAME=${{ env.DOMAIN_NAME }} \
          --build-arg RDS_ENDPOINT=${{ env.RDS_ENDPOINT }} \
          --build-arg RDS_DB_NAME=${{ secrets.RDS_DB_NAME }} \
          --build-arg RDS_DB_USERNAME=${{ secrets.RDS_DB_USERNAME }} \
          --build-arg RDS_DB_PASSWORD=${{ secrets.RDS_DB_PASSWORD }} \
          -t ${{ env.IMAGE_NAME }} .

      - name: Retag Docker image
        env:
          IMAGE_NAME: ${{ needs.deploy_aws_infrastructure.outputs.image_name }}
        run: |
          docker tag ${{ env.IMAGE_NAME }} ${{ secrets.ECR_REGISTRY }}/${{ env.IMAGE_NAME }}

      - name: Push Docker Image to Amazon ECR
        env:
          IMAGE_NAME: ${{ needs.deploy_aws_infrastructure.outputs.image_name }}
        run: |
          docker push ${{ secrets.ECR_REGISTRY }}/${{ env.IMAGE_NAME }}


  # Create environment file and export to S3 
  export_env_variables:
    name: Create environment file and export to S3 
    needs:
      - configure_aws_credentials
      - deploy_aws_infrastructure
      - start_runner
      - build_and_push_image
    if: needs.deploy_aws_infrastructure.outputs.terraform_action != 'destroy'
    runs-on: ubuntu-latest
    steps:
      - name: Export environment variable values to file
        env:
          DOMAIN_NAME: ${{ needs.deploy_aws_infrastructure.outputs.image_name }}
          RDS_ENDPOINT: ${{ needs.deploy_aws_infrastructure.outputs.rds_endpoint }}
          ENVIRONMENT_FILE_NAME: ${{ needs.deploy_aws_infrastructure.outputs.environment_file_name }}
        run: |
          echo "PERSONAL_ACCESS_TOKEN=${{ secrets.PERSONAL_ACCESS_TOKEN }}" > ${{ env.ENVIRONMENT_FILE_NAME }}
          echo "GITHUB_USERNAME=${{ env.GITHUB_USERNAME }}" >> ${{ env.ENVIRONMENT_FILE_NAME }}
          echo "REPOSITORY_NAME=${{ env.REPOSITORY_NAME }}" >> ${{ env.ENVIRONMENT_FILE_NAME }}
          echo "WEB_FILE_ZIP=${{ env.WEB_FILE_ZIP }}" >> ${{ env.ENVIRONMENT_FILE_NAME }}
          echo "WEB_FILE_UNZIP=${{ env.WEB_FILE_UNZIP }}" >> ${{ env.ENVIRONMENT_FILE_NAME }}
          echo "DOMAIN_NAME=${{ env.DOMAIN_NAME }}" >> ${{ env.ENVIRONMENT_FILE_NAME }}
          echo "RDS_ENDPOINT=${{ env.RDS_ENDPOINT }}" >> ${{ env.ENVIRONMENT_FILE_NAME }}
          echo "RDS_DB_NAME=${{ secrets.RDS_DB_NAME }}" >> ${{ env.ENVIRONMENT_FILE_NAME }}
          echo "RDS_DB_USERNAME=${{ secrets.RDS_DB_USERNAME  }}" >> ${{ env.ENVIRONMENT_FILE_NAME }}
          echo "RDS_DB_PASSWORD=${{ secrets.RDS_DB_PASSWORD }}" >> ${{ env.ENVIRONMENT_FILE_NAME }}

      - name: Upload environment file to S3
        env:
          ENVIRONMENT_FILE_NAME: ${{ needs.deploy_aws_infrastructure.outputs.environment_file_name }}
          ENV_FILE_BUCKET_NAME: ${{ needs.deploy_aws_infrastructure.outputs.env_file_bucket_name }}
        run: aws s3 cp ${{ env.ENVIRONMENT_FILE_NAME }} s3://${{ env.ENV_FILE_BUCKET_NAME }}/${{ env.ENVIRONMENT_FILE_NAME }}


          # Migrate data into RDS database with Flyway
  migrate_data:
    name: Migrate data into RDS database with Flyway
    needs:
      - deploy_aws_infrastructure
      - start_runner
      - build_and_push_image
    if: needs.deploy_aws_infrastructure.outputs.terraform_action != 'destroy'
    runs-on: self-hosted
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Download Flyway
        run: |
          wget -qO- https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${{ env.FLYWAY_VERSION }}/flyway-commandline-${{ env.FLYWAY_VERSION }}-linux-x64.tar.gz | tar xvz && sudo ln -s `pwd`/flyway-${{ env.FLYWAY_VERSION }}/flyway /usr/local/bin 

      - name: Remove the placeholder (sql) directory
        run: |
          rm -rf flyway-${{ env.FLYWAY_VERSION }}/sql/

      - name: Copy the sql folder into the Flyway sub-directory
        run: |
          cp -r sql flyway-${{ env.FLYWAY_VERSION }}/

      - name: Run Flyway migrate command
        env:
          FLYWAY_URL: jdbc:mysql://${{ needs.deploy_aws_infrastructure.outputs.rds_endpoint }}:3306/${{ secrets.RDS_DB_NAME }}
          FLYWAY_USER: ${{ secrets.RDS_DB_USERNAME }}
          FLYWAY_PASSWORD: ${{ secrets.RDS_DB_PASSWORD }}
          FLYWAY_LOCATION: filesystem:sql
        working-directory: ./flyway-${{ env.FLYWAY_VERSION }}
        run: |
          flyway -url=${{ env.FLYWAY_URL }} \
            -user=${{ env.FLYWAY_USER }} \
            -password=${{ env.FLYWAY_PASSWORD }} \
            -locations=${{ env.FLYWAY_LOCATION }} migrate


  # Stop the self-hosted EC2 runner
  stop_runner:
    name: Stop self-hosted EC2 runner
    needs:
      - configure_aws_credentials
      - deploy_aws_infrastructure
      - start_runner
      - build_and_push_image
      - export_env_variables
      - migrate_data
    if: needs.deploy_aws_infrastructure.outputs.terraform_action != 'destroy' && always() 
    runs-on: ubuntu-latest
    steps:
      - name: Stop EC2 runner
        uses: machulav/ec2-github-runner@v2
        with:
          mode: stop
          github-token: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
          label: ${{ needs.start_runner.outputs.label }}
          ec2-instance-id: ${{ needs.start_runner.outputs.ec2-instance-id }}


  # Create new task definition revision
  create_td_revision:
    name: Create new task definition revision
    needs: 
      - configure_aws_credentials
      - deploy_aws_infrastructure 
      - create_ecr_repository
      - start_runner
      - build_and_push_image
      - export_env_variables
      - migrate_data
      - stop_runner
    if: needs.deploy_aws_infrastructure.outputs.terraform_action != 'destroy'
    runs-on: ubuntu-latest
    steps:
      - name: Create new task definition revision
        env:
          ECS_FAMILY: ${{ needs.deploy_aws_infrastructure.outputs.task_definition_name }}
          ECS_IMAGE: ${{ secrets.ECR_REGISTRY }}/${{ needs.deploy_aws_infrastructure.outputs.image_name }}:${{ needs.deploy_aws_infrastructure.outputs.image_tag }}
        run: |
          # Get existing task definition
          TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition ${{ env.ECS_FAMILY }})

          # update the existing task definition by performing the following actions:
          # 1. Update the `containerDefinitions[0].image` to the new image we want to deploy
          # 2. Remove fields from the task definition that are not compatibile with `register-task-definition` --cli-input-json
          NEW_TASK_DEFINITION=$(echo "$TASK_DEFINITION" | jq --arg IMAGE "${{ env.ECS_IMAGE }}" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities) | del(.registeredAt) | del(.registeredBy)')

          # Register the new task definition and capture the output as JSON
          NEW_TASK_INFO=$(aws ecs register-task-definition --cli-input-json "$NEW_TASK_DEFINITION")

          # Grab the new revision from the output
          NEW_TD_REVISION=$(echo "$NEW_TASK_INFO" | jq '.taskDefinition.revision')

          # Set the new revision as an environment variable
          echo "NEW_TD_REVISION=$NEW_TD_REVISION" >> $GITHUB_ENV

    outputs:
      new_td_revision: ${{ env.NEW_TD_REVISION }}


  # Restart ECS Fargate service
  restart_ecs_service:
    name: Restart ECS Fargate service
    needs: 
      - configure_aws_credentials
      - deploy_aws_infrastructure 
      - create_ecr_repository
      - start_runner
      - build_and_push_image
      - export_env_variables
      - migrate_data
      - stop_runner
      - create_td_revision
    if: needs.deploy_aws_infrastructure.outputs.terraform_action != 'destroy'
    runs-on: ubuntu-latest
    steps:
      - name: Update ECS Service
        env:
          ECS_CLUSTER_NAME: ${{ needs.deploy_aws_infrastructure.outputs.ecs_cluster_name }}
          ECS_SERVICE_NAME: ${{ needs.deploy_aws_infrastructure.outputs.ecs_service_name }}
          TD_NAME: ${{ needs.deploy_aws_infrastructure.outputs.task_definition_name }}
        run: |
          aws ecs update-service --cluster ${{ env.ECS_CLUSTER_NAME }} --service ${{ env.ECS_SERVICE_NAME }} --task-definition ${{ env.TD_NAME }}:${{ needs.create_td_revision.outputs.new_td_revision }} --force-new-deployment

      - name: Wait for ECS service to become stable
        env:
          ECS_CLUSTER_NAME: ${{ needs.deploy_aws_infrastructure.outputs.ecs_cluster_name }}
          ECS_SERVICE_NAME: ${{ needs.deploy_aws_infrastructure.outputs.ecs_service_name }}
        run: |
          aws ecs wait services-stable --cluster ${{ env.ECS_CLUSTER_NAME }} --services ${{ env.ECS_SERVICE_NAME }}


```
## Usage

1. **Clone the Repository:**
   - Clone this GitHub repository to your local machine.

2. **Configure AWS CLI:**
   - Ensure that the AWS CLI is configured with the necessary access and secret keys.

3. **CiCd Pipeline Workflow:**
* 		Configure AWS Credentials:
    * Configures AWS credentials using aws-actions/configure-aws-credentials.
* 		Deploy AWS Infrastructure:
    * Uses Terraform to deploy AWS infrastructure.
    * Extracts output values like image name, domain name, RDS endpoint, etc., and sets them as environment variables.
* 		Create ECR Repository:
    * Checks if the ECR repository exists.
    * Creates the ECR repository if it doesn't exist.
* 		Start Self-hosted EC2 Runner:
    * Checks if there is a running EC2 runner.
    * Starts a new EC2 runner if no runner is currently running.
* 		Build and Push Docker Image to ECR:
    * Logs in to Amazon ECR.
    * Builds the Docker image with various build arguments.
    * Retags and pushes the Docker image to ECR.
* 		Create Environment File and Export to S3:
    * Creates an environment file with sensitive information.
    * Uploads the environment file to an S3 bucket.
* 		Migrate Data into RDS Database with Flyway:
    * Downloads Flyway.
    * Configures Flyway with database connection details.
    * Runs Flyway migrate command to apply database migrations.
* 		Stop Self-hosted EC2 Runner:
    * Stops the EC2 runner.
* 		Create New Task Definition Revision:
    * Creates a new revision of the ECS task definition.
    * Registers the new task definition.
* 		Restart ECS Fargate Service:
*  * Updates the ECS service with the new task definition revision.
   * Waits for the ECS service to become stable.

4. **Access the Website:**
   - Once the deployment is complete, access the website using the provided domain name.
     
5. **Manage ECS Cluster and Task Definitions:

   - Manage your ECS cluster by navigating to the ECS service in the AWS Management Console.
   Monitor and adjust the number of tasks running in the ECS cluster based on demand.
   Update or create new task definitions to accommodate changes or improvements to your Docker containers.
6. Important!
   Remember to set up the necessary secrets in your GitHub repository for sensitive information such as AWS credentials, personal access tokens, and Docker registry credentials.          Additionally, ensure that IAM roles and permissions are appropriately configured for the AWS resources and actions performed in the workflow.

## Contributors

* Olalekan Famoroti

## License

This project is licensed under the [License Name] - see the [LICENSE.md](LICENSE.md) file for details.

