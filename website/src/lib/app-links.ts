/** Only publish configured HTTPS links to official store or beta pages. */
export function validatedAppLink(value: string | undefined, platform: 'android' | 'ios'): string | null {
  if (!value?.trim()) return null;
  try {
    const url = new URL(value.trim());
    if (url.protocol !== 'https:' || url.username || url.password || url.port) return null;
    const valid = platform === 'android'
      ? url.hostname === 'play.google.com' && (
          (url.pathname === '/store/apps/details' && Boolean(url.searchParams.get('id')))
          || /^\/apps\/testing\/[^/]+\/?$/.test(url.pathname)
        )
      : (url.hostname === 'apps.apple.com' && /\/id\d+\/?$/.test(url.pathname))
        || (url.hostname === 'testflight.apple.com' && /^\/join\/[a-zA-Z0-9]+\/?$/.test(url.pathname));
    return valid ? url.href : null;
  } catch {
    return null;
  }
}

export const appLinks = {
  android: validatedAppLink(import.meta.env.VITE_ANDROID_APP_URL, 'android'),
  ios: validatedAppLink(import.meta.env.VITE_IOS_APP_URL, 'ios'),
};
