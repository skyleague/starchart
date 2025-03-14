/**
 * Generated by @skyleague/therefore
 * Do not manually touch this
 */
/* eslint-disable */

import type { CustomResource } from './custom.type.js'
import type { DynamodbResource } from './dynamodb.type.js'
import type { ParameterResource } from './parameter.type.js'
import type { S3Resource } from './s3.type.js'
import type { SecretResource } from './secret.type.js'

type ResourcesArray = DynamodbResource | SecretResource | ParameterResource | S3Resource | CustomResource

/**
 * The resources that the function will use.
 */
export type Resources = ResourcesArray[]
