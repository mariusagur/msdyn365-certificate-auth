# Define certificate start and end dates
$currentDate = Get-Date
$endDate = $currentDate.AddYears(1)
$notAfter = $endDate.AddYears(1)

# Generate new self-signed certificate from "Run as Administrator" PowerShell session
$certName = Read-Host -Prompt "Enter FQDN Subject Name for certificate"
$certStore = "Cert:\LocalMachine\My"
$certThumbprint = (New-SelfSignedCertificate `
    -DnsName "$certName" `
    -CertStoreLocation $CertStore `
    -KeyExportPolicy Exportable `
    -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
    -NotAfter $notAfter).Thumbprint
Write-Host "New certificate created with name: $($certName)"

# Export password-protected pfx file
$pfxPassword = Read-Host `
    -Prompt "Enter password to protect exported certificate:" -AsSecureString
$pfxFilepath = Read-Host `
    -Prompt "Enter full path to export certificate (ex C:\folder\filename.pfx)"
Export-PfxCertificate `
    -Cert "$($certStore)\$($certThumbprint)" `
    -FilePath $pfxFilepath `
    -Password $pfxPassword
Write-Host "Certificate successfully exported to: $($pfxFilepath)"

# Create Key Credential Object
$cert = New-Object `
    -TypeName System.Security.Cryptography.X509Certificates.X509Certificate `
    -ArgumentList @($pfxFilepath, $pfxPassword)

$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
Write-Host "Key value successfully converted to base64"

# Define Azure AD Application Properties
$adAppName = Read-Host -Prompt "Enter unique Azure AD App name"
$adAppHomePage = Read-Host -Prompt "Enter unique Azure AD App Homepage URI"
$adAppIdentifierUri = Read-Host -Prompt "Enter unique Azure AD App Identifier URI"

# Login to Azure Account
Import-Module AzureRM.Resources
Login-AzureRmAccount
Write-Host "Logged in to Azure account"

# Create new Azure AD Application
$adApp = New-AzureRmADApplication `
    -DisplayName $adAppName `
    -HomePage $adAppHomePage `
    -IdentifierUris $adAppIdentifierUri `
	-ReplyUrls $adAppHomePage

Write-Output "New Azure AD App created with Id: $($adApp.ApplicationId)"

# Create Azure AD Service Principal
New-AzureRmADServicePrincipal `
    -ApplicationId $adApp.ApplicationId `
    -CertValue $keyValue `
    -StartDate $currentDate `
    -EndDate $endDate
Write-Host "Added service principal to AAD app"

# Set Azure AD Tenant ID
$tenantId = (Get-AzureRmContext).Tenant.TenantId

# Test authenticating as Service Principal to Azure
Login-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $tenantId `
    -ApplicationId $adApp.ApplicationId `
    -CertificateThumbprint $certThumbprint
Write-Host "Fuccessfully logged in as AAD app"