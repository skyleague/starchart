# StarChart EventBridge-SQS: Efficient Deployment of Rules and Targets

The StarChart EventBridge Rules Terraform module deploys EventBridge rules and targets for a given set of SQS queues. This module streamlines the process of setting up EventBridge rules and targets, ensuring that patterns described in the `handler.yml` files are correctly applied and necessary permissions are granted to SQS queues.

## Module Dependencies

This module utilizes outputs from both the `config-lambda` module and deployed `sqs` modules, creating a cohesive deployment process for EventBridge rules and targets associated with SQS queues.

## Pattern Application and Permission Management

The StarChart EventBridge Rules module ensures that the patterns described in the `handler.yml` files are accurately applied to the EventBridge rules. Additionally, it configures the correct permissions for the SQS queues to allow EventBridge to publish messages to them.
