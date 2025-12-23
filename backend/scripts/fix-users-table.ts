import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { User } from '../src/modules/users/entities/user.entity';
import { ConfigService } from '@nestjs/config';

async function fixUsersTable() {
  const configService = new ConfigService();

  const dataSource = new DataSource({
    type: 'postgres',
    host: configService.get('DB_HOST', 'localhost'),
    port: parseInt(configService.get('DB_PORT', '5432')),
    username: configService.get('DB_USERNAME', 'postgres'),
    password: configService.get('DB_PASSWORD', 'admin'),
    database: configService.get('DB_NAME', 'paykey'),
    entities: [User],
    synchronize: false,
    logging: true,
  });

  try {
    await dataSource.initialize();
    console.log('✅ Database connected successfully!');

    // Check current columns
    const queryRunner = dataSource.createQueryRunner();
    await queryRunner.connect();

    const columns = await queryRunner.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      ORDER BY ordinal_position
    `);

    console.log('Current users table columns:');
    columns.forEach((col: any) => {
      console.log(
        `  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'YES' ? '(nullable)' : '(not null)'} ${col.column_default ? `default: ${col.column_default}` : ''}`,
      );
    });

    // Check if isOnboardingCompleted column exists
    const hasIsOnboardingCompleted = columns.some(
      (col: any) => col.column_name === 'isOnboardingCompleted',
    );

    if (!hasIsOnboardingCompleted) {
      console.log('Adding missing isOnboardingCompleted column...');
      await queryRunner.query(`
        ALTER TABLE "users" ADD COLUMN "isOnboardingCompleted" boolean NOT NULL DEFAULT false
      `);
      console.log('✅ Successfully added isOnboardingCompleted column');
    } else {
      console.log('✅ isOnboardingCompleted column already exists');
    }

    await queryRunner.release();
  } catch (error) {
    console.error('❌ Error fixing users table:', error.message);
  } finally {
    await dataSource.destroy();
  }
}

fixUsersTable();
