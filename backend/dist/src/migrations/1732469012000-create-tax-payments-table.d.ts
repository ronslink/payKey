import { MigrationInterface, QueryRunner } from 'typeorm';
export declare class CreateTaxPaymentsTable1732469012000 implements MigrationInterface {
    name: string;
    up(queryRunner: QueryRunner): Promise<void>;
    down(queryRunner: QueryRunner): Promise<void>;
}
