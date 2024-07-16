# StarChart Config Lambda: Dynamic Deployment Configuration

The StarChart Config Lambda Terraform module dynamically reads `handler.yml` files in your `functions` directory, combining them into several configuration maps for deploying various runtime resources supported by StarChart. This approach provides a more modular and streamlined deployment process for AWS Lambda functions.

## Config-Only Module

Note that this is a config-only module, meaning the outputs of this module must be used by other modules to perform the actual deployment. This design choice prevents cyclic dependencies in the Terraform graph.

## Dynamic Merging for Modular Deployment

By scanning the `functions` directory for `handler.yml` files, we achieve a modular deployment process for Lambda Functions. The full definition of each Lambda Function and its triggers is located next to the code that handles the triggers. StarChart also dynamically injects environment variables and corresponding IAM policies while maintaining the Principle of Least Privileges.

### Dynamic Events Triggering Lambda Functions

With StarChart, you can define any number of events that trigger a Lambda Function. For example, you can define a trigger definition as follows:

```yaml
events:
  - sqs:
      queueId: hello-sqs
      batchSize: 1
      eventbridge:
        eventBusId: downstream
        eventPattern:
          detail-type: [hello-sqs]
```

This configuration outputs SQS and EventBridge configurations for deploying the SQS queue, EventBridge rules and targets, and adds a custom inline policy to the Lambda definition allowing subscription to the SQS queue.

### Dynamic Publish Targets

StarChart also allows you to define any number of publish targets, specifying where the Lambda Function will publish events. For example, you can define a publish definition as follows:

```yaml
publishes:
  - eventbridge:
      eventBusId: downstream
      detailType: hello-sqs
```

This configuration adds a custom inline policy to the Lambda definition, allowing publishing to the specified EventBridge bus in the publish target. The policy is narrowed down by `source` (defined at the module level) and `detail-type`. The source and bus name are injected into the Lambda environment as `STARCHART_EVENTBRIDGE_PUBLISH_SOURCE` and `STARCHART_EVENTBRIDGE_DOWNSTREAM`, respectively.
