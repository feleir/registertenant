[cmdletbinding()]
param (
	[Parameter(Mandatory=$true)]
	[string]$parametersFile,
	[Parameter(Mandatory=$true)]
	[string]$resourceGroupName,
	[Parameter(Mandatory=$true)]
	[string]$tenantId,
	[Parameter(Mandatory=$true)]
	[string]$tenantName,
	[Parameter(Mandatory=$true)]
	[string]$connectionString,
	[Parameter(Mandatory=$true)]
	[string]$storageAccountName
)

$config = Get-Content -Raw -Path $parametersFile | ConvertFrom-Json
$global:params = $config.parameters
$global:resourceGroupName = $resourceGroupName
. "$PSScriptRoot\Common.ps1"

function Create-Tenant($baseUri, $tenantId, $tenantName, $connectionString, $storageAccountName, $resourceGroupName)
{
    $accountKey = (Get-AzureRmStorageAccountKey -Name $storageAccountName -ResourceGroupName $resourceGroupName ).Key1
    # the connection string name is the same as the storage account anem 
    $storageAccountconnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$accountKey"

	echo "Generated connection string:$storageAccountconnectionString"

	$token = Get-AuthenticationToken
	$body = @{
		TenantId = $tenantId
		Name = $tenantName
		ConnectionString = $connectionString
		StorageAccountConnectionString =  $storageAccountconnectionString
	}
	$bodyJson = ConvertTo-Json -InputObject $body
	
	echo "creating new tenant: "
	Invoke-RestMethod -Uri "$baseUri/api/tenants/" -Headers @{"Authorization" = "Bearer $token"} -Method Post -ContentType "application/json" -Body $bodyJson
}

function Show-AllTenants($baseUri)
{
	echo "all tenants in the current environment:"
	$token = Get-AuthenticationToken
	return Invoke-RestMethod -Uri "$baseUri/api/tenants/" -Headers @{"Authorization" = "Bearer $token"}
}

$administrationUri = Get-WebAppUrl "administrationapi"
Create-Tenant $administrationUri $tenantId $tenantName $connectionString $storageAccountName $resourceGroupName
Show-AllTenants $administrationUri