$baseUrl = "http://localhost:3000"

# Test 1: Register User
Write-Host "=== Test 1: Register User ===" -ForegroundColor Cyan
$registerBody = @{
    email = "testuser@paykey.com"
    password = "Test123!"
    name = "Test User"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "✓ User registered successfully" -ForegroundColor Green
    Write-Host $registerResponse | ConvertTo-Json
} catch {
    Write-Host "Note: User may already exist" -ForegroundColor Yellow
}

# Test 2: Login
Write-Host "`n=== Test 2: Login ===" -ForegroundColor Cyan
$loginBody = @{
    email = "testuser@paykey.com"
    password = "Test123!"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginResponse.access_token
Write-Host "✓ Login successful" -ForegroundColor Green
Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Gray

# Test 3: Get Current Tax Table
Write-Host "`n=== Test 3: Get Current Tax Table ===" -ForegroundColor Cyan
$headers = @{
    Authorization = "Bearer $token"
}
$taxTable = Invoke-RestMethod -Uri "$baseUrl/taxes/current" -Method Get -Headers $headers
Write-Host "✓ Tax table retrieved" -ForegroundColor Green
Write-Host "Year: $($taxTable.year), Personal Relief: KES $($taxTable.personalRelief)" -ForegroundColor Gray

# Test 4: Get Tax Submissions (should be empty initially)
Write-Host "`n=== Test 4: Get Tax Submissions ===" -ForegroundColor Cyan
$submissions = Invoke-RestMethod -Uri "$baseUrl/taxes/submissions" -Method Get -Headers $headers
Write-Host "✓ Tax submissions retrieved" -ForegroundColor Green
Write-Host "Count: $($submissions.Count)" -ForegroundColor Gray

if ($submissions.Count -gt 0) {
    Write-Host "`nFound $($submissions.Count) submission(s):" -ForegroundColor Yellow
    foreach ($sub in $submissions) {
        Write-Host "  - ID: $($sub.id)" -ForegroundColor Gray
        Write-Host "    Status: $($sub.status)" -ForegroundColor Gray
        Write-Host "    Total PAYE: KES $($sub.totalPaye)" -ForegroundColor Gray
        Write-Host "    Total NSSF: KES $($sub.totalNssf)" -ForegroundColor Gray
        Write-Host "    Total NHIF: KES $($sub.totalNhif)" -ForegroundColor Gray
        Write-Host "    Total Housing Levy: KES $($sub.totalHousingLevy)" -ForegroundColor Gray
        
        if ($sub.status -eq "PENDING") {
            Write-Host "`n  Testing Mark as Filed..." -ForegroundColor Cyan
            $filed = Invoke-RestMethod -Uri "$baseUrl/taxes/submissions/$($sub.id)/file" -Method Patch -Headers $headers
            Write-Host "  ✓ Marked as FILED" -ForegroundColor Green
            Write-Host "    Filing Date: $($filed.filingDate)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "`nNo tax submissions found yet." -ForegroundColor Yellow
    Write-Host "To create a submission:" -ForegroundColor Yellow
    Write-Host "  1. Add a worker" -ForegroundColor Gray
    Write-Host "  2. Create a pay period" -ForegroundColor Gray
    Write-Host "  3. Process payroll" -ForegroundColor Gray
}

Write-Host "`n=== All Tests Complete ===" -ForegroundColor Green
