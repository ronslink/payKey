import { MigrationInterface, QueryRunner } from "typeorm";

export class CreateSystemConfigTable1769673652351 implements MigrationInterface {
    name = 'CreateSystemConfigTable1769673652351'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            CREATE TABLE "system_config" (
                "key" character varying NOT NULL,
                "value" character varying NOT NULL,
                "description" character varying,
                CONSTRAINT "PK_system_config_key" PRIMARY KEY ("key")
            )
        `);

        // Seed FRONTEND_URL
        // Default to a known safe production URL if one isn't provided, or verify domain
        // Use https://paydome.co as confirmed by user in previous context/plan
        await queryRunner.query(`
            INSERT INTO "system_config" ("key", "value", "description")
            VALUES ('FRONTEND_URL', 'https://paydome.co', 'Base URL for redirection')
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE "system_config"`);
    }
}
