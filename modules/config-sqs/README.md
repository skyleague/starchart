# StarChart Config SQS: Dynamic SQS Deployment Configuration

The StarChart Config SQS Terraform module dynamically reads `handler.yml` files in your `functions` directory, combining them into a configuration map for deploying the SQS resources supported by StarChart.

## Config-Only Module

Note that this is a config-only module, meaning the outputs of this module must be used by other modules to perform the actual deployment. This design choice prevents cyclic dependencies in the Terraform graph. The module is separated from the `config-lambda` module to enable SQS resource deployment without deploying Lambda Functions, as it would introduce cyclic dependencies.

By separating the `config-sqs` module from the `config-lambda` module, we can also use the deployed SQS queues as additional input for the `config-lambda` module. This enables a more flexible and modular approach to managing and deploying Lambda functions and SQS resources.

## Dynamic Merging for Modular Deployment

By scanning the `functions` directory for `handler.yml` files, we achieve a modular deployment process for SQS resources. The full definition of the SQS resource is located next to the code that handles the triggers.

## Examples

Refer to the [`config-lambda` examples](../config-lambda/README.md) for examples on how to use this module.
