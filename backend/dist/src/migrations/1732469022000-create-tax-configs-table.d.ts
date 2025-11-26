import { MigrationInterface, QueryRunner } from 'typeorm';
export declare class CreateTaxConfigsTable1732469022000 implements MigrationInterface {
    name: string;
    up(queryRunner: QueryRunner): Promise<void>;
    down(queryRunner: QueryRunner): Promise<void>;
}
