/**
 * Generated by @skyleague/therefore@v1.0.0-local
 * Do not manually touch this
 */
/* eslint-disable */

export interface ApiKeySecurityScheme {
    /**
     * The type of the security scheme.
     */
    type: 'apiKey'
    /**
     * The description of the security scheme.
     */
    description?: string | undefined
    /**
     * The name of the API key.
     */
    name: string
    /**
     * The location of the API key.
     */
    in: 'query' | 'header' | 'cookie'
}

export interface HttpSecurityScheme {
    /**
     * The type of the security scheme.
     */
    type: 'http'
    /**
     * The description of the security scheme.
     */
    description?: string | undefined
    /**
     * The name of the HTTP Authorization scheme to be used.
     */
    scheme: string
    /**
     * A hint to the client to identify how the bearer token is formatted.
     */
    bearerFormat?: string | undefined
}

export interface Oauth2SecurityScheme {
    /**
     * The type of the security scheme.
     */
    type: 'oauth2'
    /**
     * The description of the security scheme.
     */
    description?: string | undefined
    /**
     * The available flows for the OAuth2 security scheme.
     */
    flows?:
        | {
              implicit?:
                  | {
                        /**
                         * The authorization URL to be used for this flow.
                         */
                        authorizationUrl: string
                        /**
                         * The URL to be used for obtaining refresh tokens.
                         */
                        refreshUrl?: string | undefined
                        /**
                         * The available scopes for the OAuth2 security scheme.
                         */
                        scopes: {
                            [k: string]: string | undefined
                        }
                    }
                  | undefined
              password?:
                  | {
                        /**
                         * The token URL to be used for this flow.
                         */
                        tokenUrl: string
                        /**
                         * The URL to be used for obtaining refresh tokens.
                         */
                        refreshUrl?: string | undefined
                        /**
                         * The available scopes for the OAuth2 security scheme.
                         */
                        scopes: {
                            [k: string]: string | undefined
                        }
                    }
                  | undefined
              clientCredentials?:
                  | {
                        /**
                         * The token URL to be used for this flow.
                         */
                        tokenUrl: string
                        /**
                         * The URL to be used for obtaining refresh tokens.
                         */
                        refreshUrl?: string | undefined
                        /**
                         * The available scopes for the OAuth2 security scheme.
                         */
                        scopes: {
                            [k: string]: string | undefined
                        }
                    }
                  | undefined
              authorizationCode?:
                  | {
                        /**
                         * The authorization URL to be used for this flow.
                         */
                        authorizationUrl: string
                        /**
                         * The token URL to be used for this flow.
                         */
                        tokenUrl: string
                        /**
                         * The URL to be used for obtaining refresh tokens.
                         */
                        refreshUrl?: string | undefined
                        /**
                         * The available scopes for the OAuth2 security scheme.
                         */
                        scopes: {
                            [k: string]: string | undefined
                        }
                    }
                  | undefined
          }
        | undefined
}

export interface OpenIdConnectSecurityScheme {
    /**
     * The type of the security scheme.
     */
    type: 'openIdConnect'
    /**
     * The description of the security scheme.
     */
    description?: string | undefined
    /**
     * The OpenID Connect URL to discover OAuth2 configuration values.
     */
    openIdConnectUrl: string
}

/**
 * The security requirements to use for the route.
 */
export type SecurityRequirement = {
    [k: string]: string[] | undefined
}[]

export type SecurityScheme = ApiKeySecurityScheme | HttpSecurityScheme | Oauth2SecurityScheme | OpenIdConnectSecurityScheme

export interface Server {
    /**
     * The description of the server.
     */
    description?: string | undefined
    /**
     * The URL of the server.
     */
    url: string
    /**
     * The variables to pass to the server.
     */
    variables?:
        | {
              [k: string]: ServerVariable | undefined
          }
        | undefined
}

/**
 * The servers to use for the route.
 */
export type Servers = Server[]

export interface ServerVariable {
    /**
     * The default value to use for substitution.
     */
    default: string
    /**
     * The description of the server variable.
     */
    description?: string | undefined
    /**
     * An enumeration of string values to be used if the substitution options are from a limited set.
     */
    enum?: string[] | undefined
}
