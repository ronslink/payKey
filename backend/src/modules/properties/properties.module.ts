import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Property } from './entities/property.entity';
import { PropertiesService } from './services/properties.service';
import { What3wordsService } from './services/what3words.service';
import { PropertiesController } from './controllers/properties.controller';
import { PropertyLocationController } from './controllers/property-location.controller';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Property]),
    UsersModule, // Required for PlatinumGuard dependency
  ],
  controllers: [PropertiesController, PropertyLocationController],
  providers: [PropertiesService, What3wordsService],
  exports: [PropertiesService, What3wordsService],
})
export class PropertiesModule {}
