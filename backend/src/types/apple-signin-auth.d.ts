declare module 'apple-signin-auth' {
    interface AppleIdTokenPayload {
        iss: string;
        aud: string;
        exp: number;
        iat: number;
        sub: string;
        at_hash?: string;
        email?: string;
        email_verified?: string | boolean;
        is_private_email?: string | boolean;
        auth_time?: number;
        nonce_supported?: boolean;
    }

    interface VerifyIdTokenOptions {
        idToken: string;
        clientId?: string | string[];
        nonce?: string;
        ignoreExpiration?: boolean;
    }

    export function verifyIdToken(
        idToken: string,
        options?: {
            audience?: string | string[];
            nonce?: string;
            ignoreExpiration?: boolean;
        }
    ): Promise<AppleIdTokenPayload>;

    export function getAuthorizationUrl(options?: {
        clientId?: string;
        redirectUri?: string;
        responseType?: string;
        scope?: string;
        state?: string;
    }): string;

    export function getClientSecret(options: {
        clientId: string;
        teamId: string;
        keyIdentifier: string;
        privateKey: string;
        expAfter?: number;
    }): string;

    export function getAuthorizationToken(
        code: string,
        options: {
            clientId: string;
            clientSecret: string;
            redirectUri?: string;
        }
    ): Promise<{
        access_token: string;
        token_type: string;
        expires_in: number;
        refresh_token: string;
        id_token: string;
    }>;

    export function refreshAuthorizationToken(
        refreshToken: string,
        options: {
            clientId: string;
            clientSecret: string;
        }
    ): Promise<{
        access_token: string;
        token_type: string;
        expires_in: number;
        id_token: string;
    }>;
}
