# jules-guard.ps1
# Shared guard for every Jules Cloud API call made by the CD scripts.
#
# WHY THIS EXISTS - measured 2026-10-27:
#   check_awaiting_count.ps1 called GET /v1/swebot/tasks with an expired
#   access_token. The API answered 401 Unauthorized. The script had no
#   error handling, so $res stayed $null, $res.tasks stayed $null, and
#   $tasks.Count printed 0. The report said "Total Jules tasks in cloud: 0"
#   about a call that never succeeded.
#   A zero from a measurement that did not measure is not a zero.
#   It is worse than no number: it looks like a fact.
#
# WHAT THIS GUARD DOES:
#   - reads the credential without the noisy test_cred.ps1 banner
#   - on HTTP 401 it refreshes the OAuth token through the official path
#     (jules remote list --repo), which rewrites the stored credential,
#     then retries once
#   - on any other failure it THROWS. A throw is terminating. The calling
#     script stops before it can print a count, and powershell.exe -File
#     returns a non-zero exit code. A caller cannot mistake failure for an
#     empty result.
#   - it never returns $null. An empty task list is an empty array, and an
#     empty array is a real measurement.
#
# TOKEN OVERRIDE (used by probe-false-zero.ps1):
#   set JULES_TOKEN_OVERRIDE to force a token. With an override in place
#   the automatic refresh is disabled, so the probe can prove that a bad
#   token produces a loud failure instead of a silent zero.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

if (-not ('JulesCredManager' -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class JulesCredManager {
    [DllImport("Advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);

    [DllImport("Advapi32.dll", EntryPoint = "CredFree", SetLastError = true)]
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
            byte[] bytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, bytes, 0, cred.CredentialBlobSize);
            CredFree(credPtr);
            return Encoding.UTF8.GetString(bytes);
        }
        return null;
    }
}
"@
}

function Get-JulesAccessToken {
    param([string]$TokenOverride = '')

    if ($TokenOverride) { return $TokenOverride }
    if ($env:JULES_TOKEN_OVERRIDE) { return $env:JULES_TOKEN_OVERRIDE }

    $raw = [JulesCredManager]::GetPassword('jules-cli:default')
    if (-not $raw) {
        throw 'Jules credential not found in Windows Credential Manager (target: jules-cli:default).'
    }
    $obj = $raw | ConvertFrom-Json
    if (-not $obj.access_token) {
        throw 'Jules credential contains no access_token field.'
    }
    return $obj.access_token
}

function Get-JulesAuthHeader {
    param([string]$TokenOverride = '')

    $h = @{}
    $h['Authorization'] = 'Bearer ' + (Get-JulesAccessToken -TokenOverride $TokenOverride)
    $h['Content-Type'] = 'application/json'
    return $h
}

function Update-JulesOAuthToken {
    & jules remote list --repo 2>&1 | Out-Null
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        throw ('Token refresh failed: jules remote list --repo returned exit code ' + $code)
    }
}

function Invoke-JulesApiGet {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [string]$TokenOverride = '',
        [int]$MaxRefresh = 1
    )

    $useOverride = [bool]$TokenOverride -or [bool]$env:JULES_TOKEN_OVERRIDE
    $token = Get-JulesAccessToken -TokenOverride $TokenOverride
    $attempt = 0

    while ($true) {
        $res = $null
        try {
            $headers = @{}
            $headers['Authorization'] = 'Bearer ' + $token
            $headers['Content-Type'] = 'application/json'
            $res = Invoke-RestMethod -Uri $Uri -Method Get -Headers $headers
        } catch {
            $status = 0
            if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }

            if (($status -eq 401) -and ($attempt -lt $MaxRefresh) -and (-not $useOverride)) {
                $attempt++
                Write-Host '[guard] HTTP 401 - refreshing Jules OAuth token (jules remote list --repo), then retrying once.'
                Update-JulesOAuthToken
                $token = Get-JulesAccessToken
                continue
            }

            $msg = 'Jules API GET failed. uri=' + $Uri + ' http_status=' + $status + ' :: ' + $_.Exception.Message
            Write-Error $msg
            throw $msg
        }

        if ($null -eq $res) {
            $msg = 'Jules API returned an empty payload for ' + $Uri + '. Refusing to report a count from a missing measurement.'
            Write-Error $msg
            throw $msg
        }
        return $res
    }
}

function Get-JulesTaskList {
    param([string]$TokenOverride = '')

    $res = Invoke-JulesApiGet -Uri 'https://aida.googleapis.com/v1/swebot/tasks' -TokenOverride $TokenOverride
    if ($null -eq $res) {
        throw 'Jules task list could not be read.'
    }
    return ,@($res.tasks)
}
