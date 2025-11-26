import { MigrationInterface, QueryRunner } from 'typeorm';
export declare class CreateLeaveRequestsTable1735200000001 implements MigrationInterface {
    name: string;
    up(queryRunner: QueryRunner): Promise<void>;
    down(queryRunner: QueryRunner): Promise<void>;
}
