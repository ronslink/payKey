const { DataSource } = require('typeorm');
// Import entities from the compiled dist folder
const { Worker } = require('./dist/src/modules/workers/entities/worker.entity.js');
const { User } = require('./dist/src/modules/users/entities/user.entity.js');
const { Property } = require('./dist/src/modules/properties/entities/property.entity.js');

const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [Worker, User, Property],
    synchronize: false,
    ssl: { rejectUnauthorized: false },
});

async function checkRecentData() {
    try {
        await AppDataSource.initialize();
        console.log('Connected to database via TypeORM');

        const userRepo = AppDataSource.getRepository(User);
        const workerRepo = AppDataSource.getRepository(Worker);

        // Get users created in the last 24 hours
        // const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

        const users = await userRepo.find({
            // where: { createdAt: MoreThan(oneDayAgo) }, // Need MoreThan
            order: { createdAt: 'DESC' },
            take: 5
        });

        console.log(`\n--- Last 5 Users ---`);
        for (const u of users) {
            console.log(`ID: ${u.id}, Email: ${u.email}, Name: ${u.firstName} ${u.lastName}, Created: ${u.createdAt}`);

            // Get workers for this user
            const workers = await workerRepo.find({
                where: { userId: u.id },
                order: { createdAt: 'DESC' }
            });

            console.log(`   Workers (${workers.length}):`);
            for (const w of workers) {
                console.log(`     - Name: ${w.name}, Phone: ${w.phoneNumber}, Created: ${w.createdAt}`);
            }
        }

        await AppDataSource.destroy();
    } catch (error) {
        console.error('Error:', error);
        try { await AppDataSource.destroy(); } catch (e) { }
        process.exit(1);
    }
}

checkRecentData();
