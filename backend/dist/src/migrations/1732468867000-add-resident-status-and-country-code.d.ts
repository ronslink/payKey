import { MigrationInterface, QueryRunner } from 'typeorm';
export declare class AddResidentStatusAndCountryCode1732468867000 implements MigrationInterface {
    name: string;
    up(queryRunner: QueryRunner): Promise<void>;
    down(queryRunner: QueryRunner): Promise<void>;
}
