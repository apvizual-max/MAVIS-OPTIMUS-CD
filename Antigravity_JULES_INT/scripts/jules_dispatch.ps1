# jules_dispatch.ps1 — Sovereign Antigravity Jules Task Dispatcher (REST API Edition)
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Repo,
    
    [Parameter(Mandatory=$true)]
    [string]$Task,
    
    [ValidateSet("Custom", "Palette", "Sentinel", "Bolt", "QA")]
    [string]$Persona = "Custom"
)

$Owner = "apvizual-max"
$cleanRepo = if ($Repo -match "^$Owner/") { $Repo -replace "^$Owner/", "" } else { $Repo }
$sourceId = "github/$Owner/$cleanRepo"

Write-Host "=== Antigravity Jules Sovereign Task Dispatcher ===" -ForegroundColor Cyan
Write-Host "Target Repository: $sourceId" -ForegroundColor Yellow
Write-Host "Selected Persona:  $Persona" -ForegroundColor Yellow

# Build persona prompt wrapper
$finalPrompt = ""
switch ($Persona) {
    "Palette" {
        $finalPrompt = @"
You are "Palette" 🎨 - a UX-focused agent who adds small, delightful polish, enhances accessibility (ARIA, contrast, keyboard nav), and refines UI presentation.
Task Directive:
$Task

Requirements:
- Scope all edits strictly to user experience and accessibility.
- Maintain existing architecture and clean code conventions.
"@
    }
    "Sentinel" {
        $finalPrompt = @"
You are "Sentinel" 🛡️ - a security-focused agent who protects our systems from vulnerabilities.
Task Directive:
$Task

Requirements:
- Mitigate potential security risks (injection, path traversal, SSRF, unvalidated inputs).
- Ensure zero secrets or sensitive keys are committed.
"@
    }
    "Bolt" {
        $finalPrompt = @"
You are "Bolt" ⚡ - a performance-obsessed agent who makes our execution fast and lean.
Task Directive:
$Task

Requirements:
- Eliminate redundant I/O, parallelize async loops, and reduce memory footprints.
- Ensure regression-free performance improvements.
"@
    }
    "QA" {
        $finalPrompt = @"
# 🧪 Testing & Code Health Task
You are a testing-focused agent dedicated to ensuring rock-solid stability.
Task Directive:
$Task

Requirements:
- Add comprehensive test coverage for normal, error, and edge cases.
- Fix broken assertions or outdated test mocks.
"@
    }
    Default {
        $finalPrompt = $Task
    }
}

# Load token from Windows Credential Manager
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class NativeCredReader {
    [DllImport("Advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);

    [DllImport("Advapi32.dll", SetLastError = true)]
    public static extern void CredFree(IntPtr cred);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static string GetPassword(string target) {
        IntPtr credPtr;
        if (CredRead(target, 1, 0, out credPtr)) {
            CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            byte[] passwordBytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, passwordBytes, 0, cred.CredentialBlobSize);
            CredFree(credPtr);
            return Encoding.UTF8.GetString(passwordBytes);
        }
        return null;
    }
}
"@ -ErrorAction SilentlyContinue

$tokenJson = [NativeCredReader]::GetPassword("jules-cli:default")
if (-not $tokenJson) {
    Write-Host "[ERROR] Jules OAuth credentials not found in Credential Manager. Run 'jules login'." -ForegroundColor Red
    exit 1
}

$parsed = ConvertFrom-Json $tokenJson
$token = $parsed.access_token

# Refresh check if expired
if ($parsed.expiry) {
    $expDate = [DateTime]::Parse($parsed.expiry)
    if ((Get-Date) -ge $expDate) {
        Write-Host "Token expired. Triggering automated refresh via jules.cmd..." -ForegroundColor Gray
        & "$env:APPDATA\npm\jules.cmd" remote list --repo | Out-Null
        $tokenJson = [NativeCredReader]::GetPassword("jules-cli:default")
        $parsed = ConvertFrom-Json $tokenJson
        $token = $parsed.access_token
    }
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$body = @{
    "description" = $finalPrompt
    "sourceId" = $sourceId
} | ConvertTo-Json -Depth 5

Write-Host "Dispatching task directly via Jules Cloud REST API..." -ForegroundColor Gray
$url = "https://aida.googleapis.com/v1/swebot/tasks"

try {
    $res = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    Write-Host "[SUCCESS] Cloud task dispatched successfully!" -ForegroundColor Green
    Write-Host "Task ID: $($res.taskId)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to dispatch task: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Details: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}
