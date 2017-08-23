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
  "Statement": {
    "Effect": "Allow",
    "Action": "ecs:RunTask",
    "Resource": "arn:aws:ecs:*:*:task-definition/lambci-ecs-BuildTask-1PVABCDEFKFT"
   }
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
