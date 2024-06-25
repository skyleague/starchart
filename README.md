# SkyLeague StarChart: Streamlined Serverless Deployment on AWS

StarChart is a collection of Terraform modules designed to simplify the development of serverless microservices using AWS Lambda and other AWS services, such as SQS, EventBridge, DynamoDB, S3, and more.

## Streamlined Function Deployment

With StarChart, managing multiple Lambda functions in a single repository becomes easy. Simply create `handler.yml` files alongside your handler definitions (e.g., `index.ts`). Specify the location of the `handler.yml` files, and StarChart handles the rest! The basic function definition resembles the Serverless framework, but with added opinionated syntax to accelerate development. It adheres to the Principle of Least Privilege, eliminating the need to manually create a policy for each Lambda Function you deploy.

## Deployment Options: Managed or Modular

StarChart offers two ways to deploy your microservice:

1. **Fully-Managed Module**: Deploy your microservice based on the `handler.yml` files next to your functions.
2. **Modular Components**: Customize your deployment by selecting from several modular components that StarChart defines.

## Effortless Deployment with Low Configuration

Deploying a new Lambda Function with StarChart is seamless. Apart from the initial setup, you rarely need to modify the Terraform code. StarChart requires minimal configuration for basic deployments but allows additional customization if necessary. For example, you can configure extra IAM policies for Lambda Functions, add environment variables, or adjust settings for other resources such as SQS queues and API Gateway properties. StarChart's flexible and modular design lets you adapt it to suit your specific needs.

## Deployment Best Practices

### Separate Runtime and Persistent Components

While StarChart handles deploying the runtime components of your application, such as AWS Lambda and SQS, it is recommended to define the persistent deployment of your stack as a separate Terraform deployment. The persistent part of the stack refers to anything that holds data or plays a crucial role in your AWS account's infrastructure.

### Two-Stage Microservice Deployment

For example, a central repository could deploy EventBridge and an S3 bucket that holds Lambda Function artifacts, along with centrally managed resources such as an API Gateway logging role. Then, several microservice repositories could deploy in two stages: a `persistent` stage and a `runtime` stage. In the `persistent` stage, define resources like S3 or DynamoDB, Textract, or Secrets Manager Secret placeholders. In the `runtime` stage, deploy all your Lambda Functions, SQS and EventBridge rules that connect them, an API Gateway with Lambda behind it, etc., – anything that can be safely discarded.

## Example Reference Project

To better understand how to use StarChart, refer to the [`skyleague-standards`](https://github.com/skyleague-internal/standards) project. This project provides a complete example of deploying a Lambda Function with TypeScript using StarChart, and demonstrates how to use the StarChart module as a starter template.
