import { MigrationInterface, QueryRunner } from 'typeorm';

export class UpdateSupportTicketCategoryEnum1700000000000 implements MigrationInterface {
    name = 'UpdateSupportTicketCategoryEnum1700000000000';

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Update the category enum to match mobile app
        // Rename TAX to TAXES (if exists) and add new categories
        
        // First, update any existing 'TAX' values to 'GENERAL' (safe fallback)
        await queryRunner.query(`
            UPDATE "support_tickets" 
            SET "category" = 'GENERAL' 
            WHERE "category" = 'TAX'
        `);
        
        // Drop the old enum and create new one
        await queryRunner.query(`
            ALTER TABLE "support_tickets" 
            ALTER COLUMN "category" DROP DEFAULT
        `);
        
        await queryRunner.query(`
            ALTER TABLE "support_tickets" 
            ALTER COLUMN "category" TYPE VARCHAR(50)
        `);
        
        await queryRunner.query(`
            DROP TYPE IF EXISTS "support_tickets_category_enum"
        `);
        
        await queryRunner.query(`
            CREATE TYPE "support_tickets_category_enum" AS ENUM ('BILLING', 'PAYROLL', 'TECHNICAL', 'ACCOUNT', 'GENERAL')
        `);
        
        await queryRunner.query(`
            ALTER TABLE "support_tickets" 
            ALTER COLUMN "category" TYPE "support_tickets_category_enum" USING "category"::"support_tickets_category_enum"
        `);
        
        await queryRunner.query(`
            ALTER TABLE "support_tickets" 
            ALTER COLUMN "category" SET DEFAULT 'GENERAL'
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Revert to old enum
        await queryRunner.query(`
            ALTER TABLE "support_tickets" 
            ALTER COLUMN "category" DROP DEFAULT
        `);
        
        await queryRunner.query(`
            ALTER TABLE "support_tickets" 
            ALTER COLUMN "category" TYPE VARCHAR(50)
        `);
        
        await queryRunner.query(`
            DROP TYPE IF EXISTS "support_tickets_category_enum"
        `);
        
        await queryRunner.query(`
            CREATE TYPE "support_tickets_category_enum" AS ENUM ('BILLING', 'PAYROLL', 'TECHNICAL', 'TAX', 'GENERAL')
        `);
        
        await queryRunner.query(`
            ALTER TABLE "support_tickets" 
            ALTER COLUMN "category" TYPE "support_tickets_category_enum" USING "category"::"support_tickets_category_enum"
        `);
        
        await queryRunner.query(`
            ALTER TABLE "support_tickets" 
            ALTER COLUMN "category" SET DEFAULT 'GENERAL'
        `);
    }
}
