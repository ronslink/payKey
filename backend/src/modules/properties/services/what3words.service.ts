import {
  BadGatewayException,
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';

export interface What3wordsLookup {
  words: string;
  latitude: number;
  longitude: number;
  nearestPlace: string | null;
  country: string | null;
}

const WORDS_PATTERN = /^[a-z]+\.[a-z]+\.[a-z]+$/;

/** The subset of the what3words response this service reads. */
interface What3wordsApiResponse {
  coordinates?: { lat?: unknown; lng?: unknown };
  words?: unknown;
  nearestPlace?: unknown;
  country?: unknown;
  error?: { message?: unknown };
}

function asString(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}

/**
 * Turns a what3words address into coordinates (and back) for property geofence
 * setup, where a street address is not enough to find the site.
 *
 * The API key never reaches the app: the backend is the only caller. When no
 * key is configured the endpoints answer 503 with an actionable message so the
 * app can fall back to GPS or manual coordinates instead of failing obscurely.
 */
@Injectable()
export class What3wordsService {
  private readonly logger = new Logger(What3wordsService.name);
  private readonly baseUrl = 'https://api.what3words.com/v3';

  get isConfigured(): boolean {
    return !!process.env.W3W_API_KEY;
  }

  /**
   * The key is required for every lookup.
   *
   * The public docs also allow the key in an `X-Api-Key` header, but the query
   * parameter is the form verified against the live API for this account
   * (it answers 402 plan/quota errors rather than 401 InvalidKey), so it stays.
   */
  private requireKey(): string {
    const key = process.env.W3W_API_KEY;
    if (!key) {
      throw new ServiceUnavailableException(
        'what3words lookup is not configured on this deployment. Use your current location or enter the coordinates directly.',
      );
    }
    return key;
  }

  /** `///filled.count.soap` -> coordinates */
  async resolveWords(rawWords: string): Promise<What3wordsLookup> {
    const key = this.requireKey();
    const words = (rawWords ?? '').trim().replace(/^\/+/, '').toLowerCase();

    if (!WORDS_PATTERN.test(words)) {
      throw new BadRequestException(
        'Enter a what3words address as three words, for example filled.count.soap.',
      );
    }

    const body = await this.request('convert-to-coordinates', { words, key });

    const latitude = body.coordinates?.lat;
    const longitude = body.coordinates?.lng;
    if (typeof latitude !== 'number' || typeof longitude !== 'number') {
      throw new BadGatewayException(
        'what3words returned a response without usable coordinates.',
      );
    }

    return {
      words: asString(body.words) ?? words,
      latitude,
      longitude,
      nearestPlace: asString(body.nearestPlace),
      country: asString(body.country),
    };
  }

  /** Coordinates -> `///filled.count.soap`, used to confirm a GPS pin. */
  async resolveCoordinates(
    lat: number,
    lng: number,
  ): Promise<Omit<What3wordsLookup, 'latitude' | 'longitude'>> {
    const key = this.requireKey();

    if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
      throw new BadRequestException('Latitude must be between -90 and 90.');
    }
    if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
      throw new BadRequestException('Longitude must be between -180 and 180.');
    }

    const body = await this.request('convert-to-3wa', {
      coordinates: `${lat},${lng}`,
      key,
    });

    const words = asString(body.words);
    if (words === null) {
      throw new BadGatewayException(
        'what3words returned a response without a usable address.',
      );
    }

    return {
      words,
      nearestPlace: asString(body.nearestPlace),
      country: asString(body.country),
    };
  }

  private async request(
    path: string,
    params: Record<string, string>,
  ): Promise<What3wordsApiResponse> {
    const query = new URLSearchParams(params).toString();
    const url = `${this.baseUrl}/${path}?${query}`;

    let response: Response;
    try {
      response = await fetch(url, { signal: AbortSignal.timeout(8000) });
    } catch (error) {
      this.logger.warn(
        `what3words request failed: ${(error as Error).message}`,
      );
      throw new BadGatewayException(
        'Could not reach the what3words service. Try again or use your current location.',
      );
    }

    const parsed: unknown = await response.json().catch(() => null);
    const body = (parsed ?? {}) as What3wordsApiResponse;

    if (!response.ok) {
      const detail = asString(body.error?.message);

      // 400 BadWords (and similar) means the request itself is wrong: a
      // well-formed address that does not exist, for example. That is the
      // caller's error, not a gateway fault.
      if (response.status === 400) {
        throw new BadRequestException(
          detail ?? 'That what3words address could not be resolved.',
        );
      }
      if (response.status === 404) {
        throw new NotFoundException(
          detail ?? 'That what3words address does not exist.',
        );
      }
      if (response.status === 401 || response.status === 403) {
        this.logger.error(
          'what3words rejected the configured API key; check W3W_API_KEY',
        );
        throw new ServiceUnavailableException(
          'what3words rejected the configured API key; enter the coordinates directly.',
        );
      }
      // 402/429 mean the key is fine but the account cannot make lookups right
      // now (plan or quota). That is a configuration problem, not a gateway
      // fault, and the upstream message says exactly what to change.
      if (response.status === 402 || response.status === 429) {
        this.logger.warn(
          'what3words plan or quota does not permit lookups; falling back is expected',
        );
        throw new ServiceUnavailableException(
          detail ??
            'The what3words plan for this deployment cannot look up addresses right now. Use your current location or enter the coordinates directly.',
        );
      }

      throw new BadGatewayException(
        detail ?? `what3words lookup failed (${response.status}).`,
      );
    }

    return body;
  }
}
