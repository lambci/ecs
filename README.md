# LambCI ECS cluster and Docker image

More documentation should be coming soon, but to get up and running quickly,
launch the `cluster.template` file in CloudFormation and give your stack a name like `lambci-ecs`

(You should have already created a LambCI stack as documented at https://github.com/lambci/lambci)

This will create an auto-scaling group and an ECS cluster and task definition,
which you can find in the AWS console from `Services > EC2 Container Service`

## LambCI configuration

You'll need to give the Lambda function in your LambCI stack access to run the task, so will need add to IAM
permissions something like this:

```json
{
  "Effect": "Allow",
  "Action": "ecs:RunTask",
  "Resource": "arn:aws:ecs:*:*:task-definition/lambci-ecs-BuildTask-1PVABCDEFKFT"
}
```

Where you replace the resource with the name of the ECS task definition created in your `lambci-ecs` stack.

Then in the project you want to build using ECS, you'll need to ensure the following LambCI config settings are given:

```js
{
  docker: {
    cluster: 'lambci-ecs-Cluster-1TZABCDEF987',
    task: 'lambci-ecs-BuildTask-1PVABCDEFKFT',
  }
}
```

(replacing with the actual names of your cluster and task)

These are normal LambCI config settings which you can set in your `.lambci.js[on]` file or in the config DB.

## Policies
A few of the resources require full access due to the nature of serverless and of the custom CI pipeline. For example, in order to allow custom client environments, the pipeline needs to be able to create S3 buckets, update CORS policy, etc. Afterwards it needs to be able to destroy those buckets.

## Update KMS Keys
In order to give IAM permissions for the CI to decrypt KMS encrypted secrets, ensure that the KMS key ID is added to the "ServerlessDeploy" IAM policy in cluster.template

## Increase Performance
If you application needs more than 800MB Ram to build, you can increase this value by changing BuildTask.Properties.ContainerDefinitions.Memory in cluster.template.

If you need to execute additional concurrent builds, you can change the ECS host instance type in
Parameters.InstanceType.Type.Default in cluster.template.

Autoscaling is not being used because the build requests do not come at regular intervals. By the time a new instance is spun up by autoscaling group, it is no longer needed.
A future improvement would be whenever lambci/lambci Lambda function calls ecs.runTask, it would check for out of memory error. In that case, either keep retrying or spin up new ECS instance to handle load.

## Deploy Docker Image
If you want to use an image other than lambci/ecs, the steps to upload a new image are described here: http://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html

## Deploy stack
Before deploying the stack, you need to update parameters.json with:
- The ARN of the Lambda Function that sends Hipchat notification
- The Name of the IAM Role associated with the Lambda Function that runs LambCi
These values should be updated in parameters.json.

Execute:
```
# New stack:
$ aws cloudformation create-stack --stack-name [STACK-NAME] --template-body file://cluster.template --capabilities CAPABILITY_IAM --parameters file://parameters.json

# View updates to stack without applying changes:
$ aws cloudformation deploy --stack-name [STACK-NAME] --template-file cluster.template --capabilities CAPABILITY_IAM --no-execute-changeset --parameter-override file://parameters.json

# Update existing stack:
$ aws cloudformation deploy --stack-name [STACK-NAME] --template-file cluster.template --capabilities CAPABILITY_IAM --parameter-override file://parameters.json
```
