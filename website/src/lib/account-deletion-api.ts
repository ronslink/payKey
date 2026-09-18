import { apiRequest, readSession } from './billing-api';

export async function requestAccountDeletion(details: {
  email: string; password?: string; reason?: string;
}): Promise<{ requestId: string }> {
  const session = readSession();
  const email = details.email.trim().toLowerCase();
  if (!email) throw new Error('Enter the email address of the account to delete.');
  if (session && email !== session.email.trim().toLowerCase()) {
    throw new Error('You can only request deletion of the account you are signed in to.');
  }
  if (!session && !details.password) {
    throw new Error('Enter your account password. For a Google or Apple account, contact support@paydome.co so we can verify ownership.');
  }
  const result = await apiRequest<{ requestId: string }>(
    session ? '/data-deletion/request/me' : '/data-deletion/request',
    {
      method: 'POST', authenticated: Boolean(session),
      body: {
        email,
        ...(details.password ? { password: details.password } : {}),
        ...(details.reason?.trim() ? { reason: details.reason.trim() } : {}),
      },
    },
  );
  if (typeof result.requestId !== 'string' || !result.requestId) {
    throw new Error('The server did not confirm your deletion request. Contact support before trying again.');
  }
  return result;
}
