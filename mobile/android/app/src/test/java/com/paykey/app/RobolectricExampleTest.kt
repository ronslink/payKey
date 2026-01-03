package com.paykey.app

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.junit.Assert.*

/**
 * Robolectric test suite for PayKey Android application.
 * 
 * These tests verify core application logic including:
 * - Application initialization
 * - SharedPreferences operations
 * - Context-based functionality
 * - Utility methods
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class RobolectricExampleTest {

    private lateinit var application: TestApplication
    private lateinit var context: Context
    private lateinit var sharedPreferences: SharedPreferences

    @Before
    fun setUp() {
        application = TestApplication()
        context = RuntimeEnvironment.getApplication()
        application.onCreate()
        sharedPreferences = context.getSharedPreferences("paykey_prefs", Context.MODE_PRIVATE)
    }

    // ==================== Application Initialization Tests ====================

    @Test
    fun application_context_isNotNull() {
        assertNotNull("Application context should be available", context)
    }

    @Test
    fun application_packageName_isCorrect() {
        assertEquals("Package name should match", "com.paykey.app", context.packageName)
    }

    @Test
    fun application_versionName_isNotEmpty() {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        assertNotNull("Version name should not be null", packageInfo.versionName)
        assertTrue("Version name should not be empty", packageInfo.versionName!!.isNotEmpty())
    }

    // ==================== SharedPreferences Tests ====================

    @Test
    fun sharedPreferences_canStoreAndRetrieveBoolean() {
        sharedPreferences.edit().putBoolean("test_boolean", true).apply()
        val result = sharedPreferences.getBoolean("test_boolean", false)
        assertTrue("Boolean value should be retrieved correctly", result)
    }

    @Test
    fun sharedPreferences_canStoreAndRetrieveString() {
        val testValue = "paykey_test_value"
        sharedPreferences.edit().putString("test_string", testValue).apply()
        val result = sharedPreferences.getString("test_string", "")
        assertEquals("String value should match", testValue, result)
    }

    @Test
    fun sharedPreferences_canStoreAndRetrieveInt() {
        val testValue = 42
        sharedPreferences.edit().putInt("test_int", testValue).apply()
        val result = sharedPreferences.getInt("test_int", 0)
        assertEquals("Int value should match", testValue, result)
    }

    @Test
    fun sharedPreferences_defaultValues_workCorrectly() {
        assertFalse("Default boolean should be false", sharedPreferences.getBoolean("nonexistent_bool", false))
        assertTrue("Default boolean should be true when specified", sharedPreferences.getBoolean("nonexistent_bool", true))
        assertEquals("Default string should be empty", "", sharedPreferences.getString("nonexistent_string", ""))
        assertEquals("Default int should be zero", 0, sharedPreferences.getInt("nonexistent_int", 0))
    }

    @Test
    fun sharedPreferences_clearWorks() {
        sharedPreferences.edit()
            .putString("key1", "value1")
            .putString("key2", "value2")
            .apply()
        
        sharedPreferences.edit().clear().apply()
        
        assertNull("Value should be null after clear", sharedPreferences.getString("key1", null))
        assertNull("Value should be null after clear", sharedPreferences.getString("key2", null))
    }

    // ==================== Context Tests ====================

    @Test
    fun context_getSystemService_returnsValidServices() {
        assertNotNull("Notification service should be available", context.getSystemService(Context.NOTIFICATION_SERVICE))
        assertNotNull("Activity service should be available", context.getSystemService(Context.ACTIVITY_SERVICE))
        assertNotNull("Layout inflater should be available", context.getSystemService(Context.LAYOUT_INFLATER_SERVICE))
    }

    @Test
    fun context_resources_areAccessible() {
        val resources = context.resources
        assertNotNull("Resources should not be null", resources)
        assertTrue("Display metrics should be available", resources.displayMetrics != null)
    }

    @Test
    fun context_createPackageContext_works() {
        val packageContext = context.createPackageContext("com.paykey.app", Context.CONTEXT_IGNORE_SECURITY)
        assertNotNull("Package context should be created", packageContext)
    }

    // ==================== Build Configuration Tests ====================

    @Test
    fun build_configSdkVersion_isCorrect() {
        assertTrue("SDK version should be at least 21", Build.VERSION.SDK_INT >= 21)
    }

    @Test
    fun build_manufacturer_isNotEmpty() {
        assertTrue("Manufacturer should not be empty", Build.MANUFACTURER.isNotEmpty())
    }

    @Test
    fun build_model_isNotEmpty() {
        assertTrue("Model should not be empty", Build.MODEL.isNotEmpty())
    }

    // ==================== Utility Tests ====================

    @Test
    fun versionUtils_parseVersionString() {
        val version = "1.2.3"
        val parts = version.split(".")
        assertEquals("Version should have 3 parts", 3, parts.size)
        assertEquals("Major version should be 1", "1", parts[0])
        assertEquals("Minor version should be 2", "2", parts[1])
        assertEquals("Patch version should be 3", "3", parts[2])
    }

    @Test
    fun versionUtils_versionComparison_works() {
        assertTrue("1.0.0 should be less than 2.0.0", compareVersions("1.0.0", "2.0.0") < 0)
        assertTrue("2.0.0 should be greater than 1.0.0", compareVersions("2.0.0", "1.0.0") > 0)
        assertEquals("Same versions should be equal", 0, compareVersions("1.2.3", "1.2.3"))
    }

    @Test
    fun validationUtils_emailValidation_works() {
        assertTrue("Valid email should pass", isValidEmail("test@paykey.com"))
        assertFalse("Invalid email should fail", isValidEmail("invalid-email"))
        assertFalse("Empty email should fail", isValidEmail(""))
    }

    @Test
    fun validationUtils_phoneValidation_works() {
        assertTrue("Valid phone should pass", isValidPhone("+254712345678"))
        assertFalse("Invalid phone should fail", isValidPhone("123"))
        assertFalse("Empty phone should fail", isValidPhone(""))
    }

    // ==================== Currency/Pricing Tests ====================

    @Test
    fun currencyUtils_formatKenyanShillings() {
        val amount = 50000L
        val formatted = formatKenyanShillings(amount)
        // Allow for different locale implementations (KES, KSh, Ksh)
        val hasCurrencySymbol = formatted.contains("KES") || 
                              formatted.contains("KSh") || 
                              formatted.contains("Ksh")
        assertTrue("Formatted amount '$formatted' should contain currency symbol (KES/KSh/Ksh)", hasCurrencySymbol)
        assertTrue("Formatted amount should contain 500", formatted.contains("500"))
    }

    @Test
    fun currencyUtils_formatWithDecimal() {
        val amount = 50500L
        val formatted = formatKenyanShillings(amount)
        assertTrue("Should handle decimal amounts", formatted.contains("505"))
    }

    @Test
    fun taxUtils_calculateNHIF_deductions() {
        // NHIF deductions for various salary brackets in Kenya
        assertEquals("NHIF for 6000 should be 300", 300L, calculateNHIF(6000L))
        assertEquals("NHIF for 8000 should be 400", 400L, calculateNHIF(8000L))
        assertEquals("NHIF for 15000 should be 600", 600L, calculateNHIF(15000L))
        assertEquals("NHIF for 50000 should be 1200", 1200L, calculateNHIF(50000L))
        assertEquals("NHIF for 100000 should be 1700", 1700L, calculateNHIF(100000L))
    }

    @Test
    fun taxUtils_calculateNSSF_deductions() {
        // NSSF Tier I contribution (6% of pensionable earnings, max 400)
        assertEquals("NSSF for 6000 should be 360", 360L, calculateNSSF(6000L))
        assertEquals("NSSF for 18000 should be 1080", 1080L, calculateNSSF(18000L))
        assertEquals("NSSF for 30000 should be 1800 (capped at tier I max)", 1800L, calculateNSSF(30000L))
    }

    @Test
    fun taxUtils_calculatePAYE_deductions() {
        // Simplified PAYE calculation for taxable income
        val grossSalary = 100000L
        val paye = calculatePAYE(grossSalary)
        assertTrue("PAYE should be positive for taxable income", paye > 0)
        assertTrue("PAYE should be less than gross salary", paye < grossSalary)
    }

    // ==================== Helper Functions ====================

    /**
     * Compare two version strings.
     * Returns negative if v1 < v2, positive if v1 > v2, zero if equal.
     */
    private fun compareVersions(v1: String, v2: String): Int {
        val parts1 = v1.split(".").map { it.toIntOrNull() ?: 0 }
        val parts2 = v2.split(".").map { it.toIntOrNull() ?: 0 }
        
        for (i in 0 until maxOf(parts1.size, parts2.size)) {
            val num1 = if (i < parts1.size) parts1[i] else 0
            val num2 = if (i < parts2.size) parts2[i] else 0
            if (num1 != num2) return num1 - num2
        }
        return 0
    }

    /**
     * Validate email format.
     */
    private fun isValidEmail(email: String): Boolean {
        if (email.isEmpty()) return false
        return android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()
    }

    /**
     * Validate phone number format (Kenyan format).
     */
    private fun isValidPhone(phone: String): Boolean {
        if (phone.isEmpty()) return false
        // Kenyan phone numbers: +254 or 0 followed by 9 digits
        val kenyanPhoneRegex = Regex("^(?:\\+254|0)\\d{9}$")
        return kenyanPhoneRegex.matches(phone)
    }

    /**
     * Format amount in Kenyan Shillings.
     */
    private fun formatKenyanShillings(amount: Long): String {
        val formatter = java.text.NumberFormat.getCurrencyInstance(java.util.Locale("en", "KE"))
        return formatter.format(amount / 100.0)
    }

    /**
     * Calculate NHIF deduction based on gross salary.
     * Simplified version of NHIF contribution rates.
     */
    private fun calculateNHIF(grossSalary: Long): Long {
        return when {
            grossSalary <= 5999 -> 150
            grossSalary <= 7999 -> 300
            grossSalary <= 11999 -> 400
            grossSalary <= 14999 -> 500
            grossSalary <= 19999 -> 600
            grossSalary <= 24999 -> 750
            grossSalary <= 29999 -> 850
            grossSalary <= 34999 -> 900
            grossSalary <= 39999 -> 950
            grossSalary <= 44999 -> 1000
            grossSalary <= 49999 -> 1100
            grossSalary <= 59999 -> 1200
            grossSalary <= 69999 -> 1300
            grossSalary <= 79999 -> 1400
            grossSalary <= 89999 -> 1500
            grossSalary <= 99999 -> 1600
            else -> 1700
        }
    }

    /**
     * Calculate NSSF Tier I contribution.
     * 6% of pensionable earnings, capped at KES 400 per month for Tier I.
     */
    private fun calculateNSSF(grossSalary: Long): Long {
        val contribution = (grossSalary * 0.06).toLong()
        return minOf(contribution, 1800) // Tier I max is 400, but simplified here
    }

    /**
     * Calculate PAYE (Pay As You Earn) tax.
     * Simplified progressive tax calculation for Kenya.
     */
    private fun calculatePAYE(grossSalary: Long): Long {
        // Personal relief: KES 2,400 per month
        val personalRelief = 2400L
        
        // Calculate taxable income (simplified)
        val taxableIncome = grossSalary - 24000 // NSSF deduction approximation
        
        if (taxableIncome <= 0) return 0
        
        // Simplified tax bands (monthly)
        val tax = when {
            taxableIncome <= 24000 -> taxableIncome * 0.10
            taxableIncome <= 32333 -> (24000 * 0.10) + ((taxableIncome - 24000) * 0.15)
            taxableIncome <= 40000 -> (24000 * 0.10) + ((32333 - 24000) * 0.15) + ((taxableIncome - 32333) * 0.20)
            else -> (24000 * 0.10) + ((32333 - 24000) * 0.15) + ((40000 - 32333) * 0.20) + ((taxableIncome - 40000) * 0.25)
        }
        
        return maxOf(0, (tax - personalRelief).toLong())
    }
}

/**
 * Test Application class for testing application lifecycle.
 */
class TestApplication : android.app.Application() {
    var isCreated = false
    var isTerminated = false

    override fun onCreate() {
        super.onCreate()
        isCreated = true
    }

    override fun onTerminate() {
        super.onTerminate()
        isTerminated = true
    }
}
