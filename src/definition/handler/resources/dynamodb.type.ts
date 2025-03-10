/**
 * Generated by @skyleague/therefore
 * Do not manually touch this
 */
/* eslint-disable */

type DynamodbResourceActionsArray = 'read' | 'write' | 'scan' | 'delete' | 'put' | 'update' | 'get' | 'query'

/**
 * A DynamoDB table that is used by the function.
 */
export interface DynamodbResource {
    /**
     * A DynamoDB table that is used by the function.
     */
    dynamodb: {
        /**
         * The ID of the table.
         */
        tableId: string
        /**
         * The actions to allow on the table.
         */
        actions: [DynamodbResourceActionsArray, ...DynamodbResourceActionsArray[]]
        /**
         * Custom IAM actions to add to the role.
         */
        iamActions?: string[] | undefined
    }
}
