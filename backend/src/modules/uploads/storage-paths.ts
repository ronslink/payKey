import { NotFoundException } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

export function storageRoot(): string {
  return path.resolve(
    process.env.STORAGE_ROOT || path.join(process.cwd(), 'storage'),
  );
}

export function legacyUploadsRoot(): string {
  return path.resolve(
    process.env.LEGACY_UPLOADS_DIR ||
      process.env.UPLOADS_DIR ||
      path.join(process.cwd(), 'uploads'),
  );
}

export function publicAvatarRoots(): string[] {
  return [
    path.join(storageRoot(), 'public', 'avatars'),
    path.join(legacyUploadsRoot(), 'avatars'),
  ];
}

export function privateGovDirectory(kind: 'kra' | 'shif' | 'nssf'): string {
  return path.join(storageRoot(), 'private', 'gov-files', kind);
}

export function privateExportsDirectory(): string {
  return path.join(storageRoot(), 'private', 'exports');
}

/** Resolve real paths as well as lexical paths so symlinks cannot escape storage. */
export async function existingFileWithin(
  root: string,
  relative: string,
): Promise<string | undefined> {
  const resolvedRoot = path.resolve(root);
  const candidate = path.resolve(resolvedRoot, relative);
  // Include the separator so a sibling such as "documents-extra" cannot match.
  const rootBoundary = resolvedRoot.endsWith(path.sep)
    ? resolvedRoot
    : `${resolvedRoot}${path.sep}`;
  if (candidate === resolvedRoot || !candidate.startsWith(rootBoundary))
    return undefined;
  try {
    const [realRoot, realFile] = await Promise.all([
      fs.promises.realpath(resolvedRoot),
      fs.promises.realpath(candidate),
    ]);
    const realBoundary = realRoot.endsWith(path.sep)
      ? realRoot
      : `${realRoot}${path.sep}`;
    if (realFile === realRoot || !realFile.startsWith(realBoundary))
      return undefined;
    return (await fs.promises.stat(realFile)).isFile() ? realFile : undefined;
  } catch {
    return undefined;
  }
}

function safeParts(value: string): string[] | undefined {
  const parts = value.split('/');
  return parts.every(
    (part) => /^[a-zA-Z0-9_.-]+$/.test(part) && part !== '.' && part !== '..',
  )
    ? parts
    : undefined;
}

/**
 * Persist new private storage keys rather than host-specific absolute paths.
 * Existing public URLs/paths map only to the equivalent private or legacy directory.
 * Authorization must be checked by the caller before resolving a reference.
 */
export async function resolvePrivateFile(
  reference: string,
  category: 'documents' | 'gov-files',
  ownerDirectory?: string,
): Promise<string> {
  let key = reference;
  try {
    if (/^https?:\/\//i.test(key)) key = new URL(key).pathname;
    key = decodeURIComponent(key).replace(/\\/g, '/');
  } catch {
    throw new NotFoundException('File not found');
  }

  // Support absolute paths saved by older application versions without permitting
  // arbitrary filesystem reads. The original uploads mount may now be read-only.
  for (const root of [
    storageRoot(),
    legacyUploadsRoot(),
    path.join(process.cwd(), 'uploads'),
  ]) {
    const normalizedRoot = root.replace(/\\/g, '/').replace(/\/$/, '');
    if (key.startsWith(`${normalizedRoot}/`)) {
      key = `${root === storageRoot() ? '' : 'uploads/'}${key.slice(normalizedRoot.length + 1)}`;
      break;
    }
  }
  key = key.replace(/^\//, '');
  const parts = safeParts(key);
  if (
    !parts ||
    parts.length !== 4 ||
    !['private', 'uploads'].includes(parts[0]) ||
    parts[1] !== category ||
    (ownerDirectory !== undefined && parts[2] !== ownerDirectory) ||
    (category === 'gov-files' && !['kra', 'shif', 'nssf'].includes(parts[2]))
  ) {
    throw new NotFoundException('File not found');
  }

  const relative = parts.slice(2).join(path.sep);
  const roots = [path.join(storageRoot(), 'private', category)];
  if (parts[0] === 'uploads')
    roots.push(path.join(legacyUploadsRoot(), category));
  for (const root of roots) {
    const file = await existingFileWithin(root, relative);
    if (file) return file;
  }
  throw new NotFoundException('File not found');
}

/** Resolve stored accounting exports only after checking the export owner. */
export async function resolvePrivateExport(reference: string): Promise<string> {
  let key = reference.replace(/\\/g, '/');
  for (const root of [
    privateExportsDirectory(),
    path.join(legacyUploadsRoot(), 'exports'),
    path.join(process.cwd(), 'exports'),
  ]) {
    const normalizedRoot = root.replace(/\\/g, '/').replace(/\/$/, '');
    if (key.startsWith(`${normalizedRoot}/`)) {
      key = `${root === privateExportsDirectory() ? 'private/' : ''}exports/${key.slice(normalizedRoot.length + 1)}`;
      break;
    }
  }
  const parts = safeParts(key);
  const isPrivate = parts?.length === 3 && parts[0] === 'private';
  const categoryIndex = isPrivate ? 1 : 0;
  if (
    !parts ||
    parts.length !== (isPrivate ? 3 : 2) ||
    parts[categoryIndex] !== 'exports'
  ) {
    throw new NotFoundException('File not found');
  }
  const roots = [privateExportsDirectory()];
  if (!isPrivate) {
    roots.push(
      path.join(legacyUploadsRoot(), 'exports'),
      path.join(process.cwd(), 'exports'),
    );
  }
  for (const root of roots) {
    const file = await existingFileWithin(root, parts[categoryIndex + 1]);
    if (file) return file;
  }
  throw new NotFoundException('File not found');
}
