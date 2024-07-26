declare module 'better-ajv-errors' {
    export interface Options {
        indent?: number
    }
    export default function betterAjvErrors(_schema: unknown, _data: unknown, _errors: unknown, _options: Options): string
}
