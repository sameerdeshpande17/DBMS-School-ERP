$ErrorActionPreference = "Stop"
$BaseUrl = "http://localhost:3000"

function Get-StatusCode {
    param([string]$Path,[string]$Method="GET",[Microsoft.PowerShell.Commands.WebRequestSession]$Session,[object]$Body=$null)
    try {
        $params = @{ Uri = "$BaseUrl$Path"; Method = $Method; WebSession = $Session; UseBasicParsing = $true }
        if ($null -ne $Body) { $params.ContentType = "application/json"; $params.Body = ($Body | ConvertTo-Json -Depth 8 -Compress) }
        $response = Invoke-WebRequest @params
        return [int]$response.StatusCode
    } catch {
        if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        throw
    }
}

function Invoke-RoleTests {
    param([string]$Role,[string]$Username,[securestring]$SecurePassword)
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    try { $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }

    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $loginBody = @{ username = $Username; password = $plainPassword; expectedRole = $Role }
    try {
        $login = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method Post -ContentType "application/json" -Body ($loginBody | ConvertTo-Json -Compress) -WebSession $session
    } catch {
        throw "[$Role] Login failed. Check the username, password and account role."
    } finally {
        $plainPassword = $null
        $loginBody = $null
    }

    Write-Host "`n=== $Role API authorization tests ===" -ForegroundColor Cyan
    $tests = @(
        @{ Path="/api/auth/me"; Method="GET"; Expected=200; Name="Session identity" },
        @{ Path="/api/dashboard"; Method="GET"; Expected=200; Name="Role-aware dashboard" },
        @{ Path="/api/students"; Method="GET"; Expected=200; Name="Student directory scope" },
        @{ Path="/api/teachers"; Method="GET"; Expected=$(if($Role -eq "STUDENT"){403}else{200}); Name="Teacher directory access" },
        @{ Path="/api/classes"; Method="GET"; Expected=200; Name="Class scope" },
        @{ Path="/api/subjects"; Method="GET"; Expected=200; Name="Subject catalogue" },
        @{ Path="/api/class-subjects"; Method="GET"; Expected=200; Name="Subject assignment scope" },
        @{ Path="/api/attendance"; Method="GET"; Expected=200; Name="Attendance scope" },
        @{ Path="/api/exams"; Method="GET"; Expected=200; Name="Examination scope" },
        @{ Path="/api/fees"; Method="GET"; Expected=$(if($Role -eq "TEACHER"){403}else{200}); Name="Fee privacy" },
        @{ Path="/api/notices"; Method="GET"; Expected=200; Name="Notice audience filtering" },
        @{ Path="/api/students"; Method="POST"; Expected=$(if($Role -eq "ADMIN"){400}else{403}); Body=@{}; Name="Student creation permission" },
        @{ Path="/api/attendance"; Method="POST"; Expected=$(if($Role -eq "STUDENT"){403}else{400}); Body=@{}; Name="Attendance write permission" },
        @{ Path="/api/exams"; Method="POST"; Expected=$(if($Role -eq "ADMIN"){400}else{403}); Body=@{}; Name="Exam creation permission" },
        @{ Path="/api/fees"; Method="POST"; Expected=$(if($Role -eq "ADMIN"){400}else{403}); Body=@{}; Name="Fee write permission" },
        @{ Path="/api/notices"; Method="POST"; Expected=$(if($Role -eq "ADMIN"){400}else{403}); Body=@{}; Name="Notice write permission" }
    )
    $failed = 0
    foreach ($test in $tests) {
        $actual = Get-StatusCode -Path $test.Path -Method $test.Method -Session $session -Body $test.Body
        $ok = $actual -eq $test.Expected
        if (-not $ok) { $failed++ }
        $color = if ($ok) { "Green" } else { "Red" }
        $result = if ($ok) { "PASS" } else { "FAIL" }
        Write-Host ("{0,-5} {1,-38} expected {2}, received {3}" -f $result,$test.Name,$test.Expected,$actual) -ForegroundColor $color
    }
    $logout = Get-StatusCode -Path "/api/auth/logout" -Method "POST" -Session $session
    $meAfterLogout = Get-StatusCode -Path "/api/auth/me" -Method "GET" -Session $session
    $logoutOk = ($logout -eq 200 -and $meAfterLogout -eq 401)
    if (-not $logoutOk) { $failed++ }
    Write-Host ("{0,-5} {1}" -f $(if($logoutOk){"PASS"}else{"FAIL"}),"Logout invalidates session") -ForegroundColor $(if($logoutOk){"Green"}else{"Red"})
    Write-Host "$Role: $($tests.Count + 1 - $failed)/$($tests.Count + 1) passed" -ForegroundColor $(if($failed -eq 0){"Green"}else{"Red"})
    return $failed
}

Write-Host "School ERP role-based API smoke test" -ForegroundColor Cyan
try { $health = Invoke-RestMethod "$BaseUrl/api/health"; if ($health.status -ne "ok") { throw "MySQL health check failed." } }
catch { throw "Cannot reach the app or MySQL at $BaseUrl. Start MySQL and npm run dev first." }

$totalFailed = 0
foreach ($role in @("ADMIN","TEACHER","STUDENT")) {
    Write-Host "`nEnter $role test credentials" -ForegroundColor Yellow
    $username = Read-Host "Username"
    $password = Read-Host "Password" -AsSecureString
    $totalFailed += Invoke-RoleTests -Role $role -Username $username -SecurePassword $password
    $password = $null
}
Write-Host "`n=== FINAL RESULT ===" -ForegroundColor Cyan
if ($totalFailed -eq 0) { Write-Host "All role/API smoke tests passed." -ForegroundColor Green }
else { Write-Host "$totalFailed test(s) failed. Review the failures above." -ForegroundColor Red; exit 1 }
