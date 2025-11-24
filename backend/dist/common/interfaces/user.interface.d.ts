export interface JwtUser {
    userId: string;
    email: string;
    tier: string;
    role?: string;
}
export interface AuthenticatedRequest extends Request {
    user: JwtUser;
}
