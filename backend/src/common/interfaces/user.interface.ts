export interface JwtUser {
  userId: string;
  email: string;
  tier: string;
  role: string;
  employerId?: string;
  workerId?: string;
}

export interface AuthenticatedRequest extends Request {
  user: JwtUser;
}
