/**
 * Generated by @skyleague/therefore
 * Do not manually touch this
 */
/* eslint-disable */

/**
 * A secret that is used by the function.
 */
export interface SecretResource {
    secret:
        | string
        | {
              /**
               * The path to the secret.
               */
              path: string
              actions: ['read' | 'rotation', ...('read' | 'rotation')[]]
          }
}
