// require('dotenv').config(); // Not needed for mock test

// MOCKED Config Service
const mockConfig = {
    INTASEND_IS_LIVE: process.env.INTASEND_IS_LIVE,
    NODE_ENV: process.env.NODE_ENV,
    INTASEND_PUBLISHABLE_KEY: process.env.INTASEND_PUBLISHABLE_KEY || 'LIVE_PUB_KEY',
    INTASEND_SECRET_KEY: process.env.INTASEND_SECRET_KEY || 'LIVE_SECRET_KEY',
    INTASEND_PUBLISHABLE_KEY_TEST: process.env.INTASEND_PUBLISHABLE_KEY_TEST || 'TEST_PUB_KEY',
    INTASEND_SECRET_KEY_TEST: process.env.INTASEND_SECRET_KEY_TEST || 'TEST_SECRET_KEY',
};

class MockConfigService {
    get(key) {
        return mockConfig[key];
    }
}

class MockHttpService { }
class MockLogger {
    log(msg) { console.log('[LOG]', msg); }
    warn(msg) { console.warn('[WARN]', msg); }
    error(msg) { console.error('[ERROR]', msg); }
}

// SIMULATED IntaSendService (Simplified version of the real one)
class IntaSendService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new MockLogger();

        const isLive =
            this.configService.get('INTASEND_IS_LIVE') === 'true' ||
            this.configService.get('NODE_ENV') === 'production';

        this.baseUrl = isLive
            ? 'https://payment.intasend.com/api'
            : 'https://sandbox.intasend.com/api';

        if (isLive) {
            this.publishableKey = this.configService.get('INTASEND_PUBLISHABLE_KEY') || '';
            this.secretKey = this.configService.get('INTASEND_SECRET_KEY') || '';
        } else {
            // In Sandbox, prefer TEST keys, fall back to standard if not present (but warn)
            const testPubKey = this.configService.get('INTASEND_PUBLISHABLE_KEY_TEST');
            const testSecretKey = this.configService.get('INTASEND_SECRET_KEY_TEST');

            if (testPubKey && testSecretKey) {
                this.publishableKey = testPubKey;
                this.secretKey = testSecretKey;
            } else {
                this.publishableKey = this.configService.get('INTASEND_PUBLISHABLE_KEY') || '';
                this.secretKey = this.configService.get('INTASEND_SECRET_KEY') || '';
                this.logger.warn('⚠️ SANDBOX MODE: Using standard keys because TEST keys are missing. Ensure this is intentional.');
            }
        }

        console.log(`\n--- CONFIG REPORT ---`);
        console.log(`Enviromnent: ${isLive ? 'LIVE' : 'SANDBOX'}`);
        console.log(`Base URL:    ${this.baseUrl}`);
        console.log(`Pub Key:     ${this.publishableKey}`);
        console.log(`Secret Key:  ${this.secretKey}`);
        console.log(`---------------------\n`);
    }
}

// TEST SCENARIOS
console.log('🧪 Testing IntaSend Configuration Logic...\n');

// Scenario 1: SANDBOX with TEST KEYS present
console.log('Test 1: Sandbox with TEST Keys (Expected: Use TEST keys)');
mockConfig.INTASEND_IS_LIVE = 'false';
mockConfig.NODE_ENV = 'development';
mockConfig.INTASEND_PUBLISHABLE_KEY_TEST = 'pk_test_123';
mockConfig.INTASEND_SECRET_KEY_TEST = 'sk_test_123';
new IntaSendService(new MockConfigService());

// Scenario 2: SANDBOX with NO Test keys (Expected: Fallback to Live keys + Warn)
console.log('Test 2: Sandbox MISSING Test Keys (Expected: Fallback to LIVE keys + WARN)');
mockConfig.INTASEND_PUBLISHABLE_KEY_TEST = undefined;
mockConfig.INTASEND_SECRET_KEY_TEST = undefined;
new IntaSendService(new MockConfigService());

// Scenario 3: LIVE Mode (Expected: Use LIVE keys)
console.log('Test 3: LIVE Mode (Expected: Use LIVE keys)');
mockConfig.INTASEND_IS_LIVE = 'true';
new IntaSendService(new MockConfigService());
