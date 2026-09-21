import { Controller, Get, Query, Request, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/jwt-auth.guard';
import { PlatinumGuard } from '../../auth/platinum.guard';
import {
  What3wordsLookup,
  What3wordsService,
} from '../services/what3words.service';

/**
 * Location helpers for setting a property's geofence anchor, where a street
 * address is not precise enough to find the site.
 */
@ApiTags('Property location')
@Controller('property-location')
@UseGuards(JwtAuthGuard, PlatinumGuard)
export class PropertyLocationController {
  constructor(private readonly what3wordsService: What3wordsService) {}

  @Get('what3words')
  @ApiOperation({ summary: 'Resolve a what3words address to coordinates' })
  async resolveWhat3words(
    @Request() _req: any,
    @Query('words') words: string,
  ): Promise<What3wordsLookup> {
    return this.what3wordsService.resolveWords(words);
  }

  @Get('words')
  @ApiOperation({ summary: 'Resolve coordinates to a what3words address' })
  async resolveWords(
    @Request() _req: any,
    @Query('lat') lat: string,
    @Query('lng') lng: string,
  ) {
    return this.what3wordsService.resolveCoordinates(Number(lat), Number(lng));
  }
}
