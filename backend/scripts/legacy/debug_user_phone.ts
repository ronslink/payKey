
import { DataSource } from 'typeorm';

// Docker-friendly defaults
const host = process.env.DB_HOST || 'db';
const username = process.env.DB_USER || 'postgres';
const password = process.env.DB_PASSWORD || 'admin';
const database = process.env.DB_NAME || 'paykey';

const AppDataSource = new DataSource({
    type: "postgres",
    host: host,
    port: 5432,
    username: username,
    password: password,
    database: database,
    synchronize: false,
    logging: false,
    entities: [],
});

async function run() {
    console.log("Initializing DataSource...");
    await AppDataSource.initialize();

    const phoneInput = '+254722256899';
    console.log(`Searching for User with phone: ${phoneInput}`);

    const users = await AppDataSource.query(`
        SELECT id, email, "phoneNumber", "pin", "passwordHash" 
        FROM users 
        WHERE "phoneNumber" = $1
    `, [phoneInput]);

    if (users.length > 0) {
        const user = users[0];
        console.log('User Found:');
        console.log(`ID: ${user.id}`);
        console.log(`Email: ${user.email}`);
        console.log(`Phone: ${user.phoneNumber}`);
        console.log(`Has Pin: ${!!user.pin}`);
        console.log(`Has PasswordHash: ${!!user.passwordHash}`);
    } else {
        console.log('No User found with this phone number.');
    }

    // Also check worker again just to be 100% sure
    // Assuming columns are inviteCode, isInviteAccepted -> "inviteCode", "isInviteAccepted" in camelCase context or snake_case
    // My previous successful runs used quoted "phoneNumber" for users.
    // Let's assume workers also has camelCase columns in entity -> mapped to snake_case or quoted.
    // Wait, the previous error was on 'isInviteAccepted'. Let's look at Worker entity.
    // Safest bet for raw query is usually snake_case if standard, but TypeORM creates columns as camelCase if not specified?

    // Let's check Worker entity first if possible, or just try quoted camelCase which worked for Users.
    const workers = await AppDataSource.query(`
        SELECT id, email, "phoneNumber", "inviteCode", "linkedUserId"
        FROM workers
        WHERE "phoneNumber" = $1
    `, [phoneInput]);

    if (workers.length > 0) {
        const worker = workers[0];
        console.log('Worker Found:');
        console.log(`ID: ${worker.id}`);
        console.log(`Email: ${worker.email}`);
        console.log(`Phone: ${worker.phoneNumber}`);
        console.log(`Invite Code: ${worker.inviteCode}`);
        console.log(`Invite Accepted: ${worker.isInviteAccepted}`);
    } else {
        console.log('No Worker found with this phone number.');
    }

    await AppDataSource.destroy();
}

run();
