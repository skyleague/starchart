/**
 * Generated by @skyleague/therefore
 * Do not manually touch this
 */
/* eslint-disable */

import type { HttpTrigger } from './http.type.js'
import type { ScheduledTrigger } from './scheduled.type.js'
import type { SqsTrigger } from './sqs.type.js'

/**
 * The events that will trigger the handler.
 */
export type Events = (HttpTrigger | SqsTrigger | ScheduledTrigger)[]
