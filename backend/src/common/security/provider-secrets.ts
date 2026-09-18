/**
 * Provider callback authentication material must never be stored in transaction
 * metadata or returned to customers. Apply on reads too: old rows can contain
 * the shared webhook challenge, including JSON-encoded historical payloads.
 */
export function redactProviderSecrets<T>(value: T): T {
  return redact(value, 0) as T;
}

function sensitiveKey(key: string): boolean {
  const normalized = key.replace(/[^a-z0-9]/gi, '').toLowerCase();
  return (
    normalized === 'auth' ||
    normalized === 'credentials' ||
    normalized.includes('challenge') ||
    normalized.includes('authorization') ||
    normalized.includes('password') ||
    normalized.includes('secret') ||
    normalized.includes('signature') ||
    normalized.endsWith('apikey') ||
    normalized.endsWith('token') ||
    normalized.endsWith('cookie')
  );
}

function redact(value: unknown, depth: number): unknown {
  if (depth > 30) return '[redacted]';
  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return value;
    try {
      return JSON.stringify(redact(JSON.parse(trimmed), depth + 1));
    } catch {
      // Malformed stored JSON cannot safely be inspected for authentication fields.
      return '[redacted]';
    }
  }
  if (Array.isArray(value))
    return value.map((entry) => redact(entry, depth + 1));
  if (value instanceof Date) return value;
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value)
        .filter(([key]) => !sensitiveKey(key))
        .map(([key, entry]) => [key, redact(entry, depth + 1)]),
    );
  }
  return value;
}
