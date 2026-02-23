const { DataSource } = require('typeorm');
const dbConfig = {
    type: 'postgres',
    url: 'postgresql://postgres:postgres@db:5432/paykey',
    entities: [
        __dirname + '/src/**/*.entity.ts',
        __dirname + '/src/**/*.entity.js'
    ]
};

async function run() {
    const ds = new DataSource(dbConfig);
    await ds.initialize();
    try {
        const qb = ds.getRepository('AdminAuditLog').createQueryBuilder('log')
            .leftJoin('users', 'u', 'u.id = log."adminUserId"')
            .select([
                'log.id as id',
                'log.action as action',
                'log."entityType" as "entityType"',
                'log."entityId" as "entityId"',
                'log."oldValues" as "oldValues"',
                'log."newValues" as "newValues"',
                'log."ipAddress" as "ipAddress"',
                'log."createdAt" as "createdAt"',
                'u.email as "adminEmail"',
            ])
            .orderBy('log."createdAt"', 'DESC')
            .offset(0).limit(20);

        console.log('SQL:', qb.getSql());
        const [raw, count] = await Promise.all([qb.getRawMany(), qb.getCount()]);
        console.log('Success:', { raw: raw.length, count });
    } catch (err) {
        console.error('Error:', err.message);
    } finally {
        await ds.destroy();
    }
}

run();
