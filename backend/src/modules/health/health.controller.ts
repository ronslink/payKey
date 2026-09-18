import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { HealthService } from './health.service';

@Controller('health')
export class HealthController {
  constructor(private readonly health: HealthService) {}

  @Get()
  live() {
    return { status: 'up' };
  }

  @Get('ready')
  async ready() {
    const result = await this.health.check();
    if (result.status !== 'ready')
      throw new ServiceUnavailableException(result);
    return result;
  }
}
