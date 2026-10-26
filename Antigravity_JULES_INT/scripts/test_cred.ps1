Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class CredManager {
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
            byte[] passwordBytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, passwordBytes, 0, cred.CredentialBlobSize);
            CredFree(credPtr);
            return Encoding.UTF8.GetString(passwordBytes);
        }
        return null;
    }
}
"@

$tokenJson = [CredManager]::GetPassword("jules-cli:default")
if ($tokenJson) {
    Write-Host "Successfully read jules-cli:default credential length: $($tokenJson.Length)"
    $parsed = ConvertFrom-Json $tokenJson
    Write-Host "Keys in token JSON: $($parsed | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)"
    if ($parsed.token_type) { Write-Host "Token type: $($parsed.token_type)" }
    if ($parsed.expiry) { Write-Host "Expiry: $($parsed.expiry)" }
} else {
    Write-Host "Could not read credential."
}
