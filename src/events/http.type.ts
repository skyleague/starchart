/**
 * Generated by @skyleague/therefore@v1.0.0-local
 * Do not manually touch this
 */
/* eslint-disable */

export interface HttpTrigger {
    /**
     * Subscribes to an HTTP route.
     */
    http: {
        method: 'get' | 'post' | 'put' | 'delete' | 'patch' | 'options' | 'head'
        /**
         * The HTTP path for the route. Must start with / and must not end with /.
         */
        path: string
        /**
         * The name of the authorizer to use for the route.
         */
        authorizer?: string | undefined
    }
}
