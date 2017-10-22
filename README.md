# LambCI ECS cluster and Docker image

More documentation should be coming soon, but to get up and running quickly,
launch the `cluster.template` file in CloudFormation and give your stack a name like `lambci-ecs`.
You can also use `cluster.spot.template` to use ECS under Spot Instances.

(You should have already created a LambCI stack as documented at https://github.com/lambci/lambci)

This will create an auto-scaling group and an ECS cluster and task definition,
which you can find in the AWS console from `Services > EC2 Container Service`

LambCI-ECS will look for a `Dockerfile.test` is in the root of the repository. This is where you put your test/build instructions.

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

This block should be added as part of the `LambdaExecution > Properties > Policies` section of the `lambci` template.

Replace the `Resource` value with the name of the ECS task definition created in your `lambci-ecs` stack.

![Example resource location](http://i.imgur.com/3U7NHQr.png)

## Project configuration

Then in the project you want to build using ECS, you'll need to ensure the following LambCI config settings are given:

```js
{
  docker: {
    cluster: 'lambci-ecs-Cluster-1TZABCDEF987',
    task: 'lambci-ecs-BuildTask-1PVABCDEFKFT',
  }
}
```

(replacing with the actual names of your ECS cluster and task)

![Example cluster and task location](http://i.imgur.com/DKgcdBU.png)

These are normal LambCI config settings which you can set in your `.lambci.js[on]` file or in the config DB.

