/**
 * Generated by @skyleague/therefore
 * Do not manually touch this
 */
/* eslint-disable */

type S3ResourceActionsArray = 'read' | 'write' | 'delete' | 'get' | 'list'

/**
 * An S3 bucket that is used by the function.
 */
export interface S3Resource {
    /**
     * An S3 bucket that is used by the function.
     */
    s3: {
        /**
         * The ID of the bucket.
         */
        bucketId: string
        actions: [S3ResourceActionsArray, ...S3ResourceActionsArray[]]
        /**
         * Custom IAM actions to add to the role.
         */
        iamActions?: string[] | undefined
    }
}
