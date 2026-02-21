import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SystemConfig } from './entities/system-config.entity';
import { SystemConfigService } from './system-config.service';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([SystemConfig])],
  providers: [SystemConfigService],
  exports: [SystemConfigService],
})
export class SystemConfigModule {}
