import { MigrationInterface, QueryRunner } from 'typeorm';
export declare class CreateAccountingExportsTable1735200000004 implements MigrationInterface {
    name: string;
    up(queryRunner: QueryRunner): Promise<void>;
    down(queryRunner: QueryRunner): Promise<void>;
}
