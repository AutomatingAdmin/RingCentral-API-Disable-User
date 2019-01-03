Function Disable-RcUser {
	<#
	.Synopsis
	   Sets a user to disabled in RingCentral
	.DESCRIPTION
	   Uses the RingCentral API to disable a user
	.EXAMPLE
	   Disable-RcUser -UserEmail someone@domain.com
	#>

	[CmdletBinding()]
	Param (
		# Email address of the user to disable
		[Parameter(Mandatory)]
		[string]
		$UserEmail,
		
		# This can be run against your sandbox app by using this switch
		[switch]
		$Sandbox
	)
	
	# Runs against your production app if Sandbox isnt specified
	If (-not ($Sandbox)) {
		# Production
		$production = $true
		$KeyPath = "Path to AES key here"
		$PasswordPath = "Path to password encrypted with above key"
		$app_id = "App ID for your production app in RingCentral dev"
		$app_key = "App key for your production app in RingCentral dev"
		$username = "Username for production app"
		$securePassword = Get-Content $PasswordPath | ConvertTo-SecureString -Key (Get-Content $KeyPath)
		$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
		$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		$password = $UnsecurePassword
		# OAuthClientID is always the same, but im leaving the following lines to show how its created
		$bytes = [system.text.encoding]::UTF8.GetBytes($app_id+":"+$app_key)
		$OAuthClientID = [system.convert]::ToBase64string($bytes)
	}
	Else {
		# Sandbox
		# I dont guard the sandbox creds as  carefully as production
		$app_id = "App ID for your sandbox app in RingCentral dev"
		$app_key = "App key for your sandbox app in RingCentral dev"
		$username = "Username for sandbox app"
		$password = "Password for sandbox app"
		# OAuthClientID is always the same, but im leaving the following lines to show how its created
		$bytes = [system.text.encoding]::UTF8.GetBytes($app_id+":"+$app_key)
		$OAuthClientID = [system.convert]::ToBase64string($bytes)
	}
	
	# RC API AUTHORIZATION
	$body = @{
		grant_type = "password"
		username = $username
		password = $password
	}
	$authuri = "https://platform$(If(-not $production){".devtest"}).ringcentral.com/restapi/oauth/token"
	$token = Invoke-RestMethod -Uri $authuri -ContentType "application/x-www-form-urlencoded" -Body $body -Headers @{"Authorization" = "Basic $OAuthClientID"} -Method Post 
	$authorization = $token.token_type + " " + $token.access_token
	$auth_token = $authorization
	# END API AUTHORIZATION
	
	# We are going to see if the user exists in RC first, so get all the active extensions to search them later
	Write-Host "Checking if $UserEmail exists in RingCentral" -fore cyan
	# URI to get all extensions
	$apiuri = "https://platform.ringcentral.com/restapi/v1.0/account/~/extension/"
	$query = Invoke-RestMethod -Uri $apiuri -Headers @{"Authorization" = $auth_token}
	$totalPages = $query.paging.totalPages
	# For loop that runs a query for each of the pages and adds the results to the data object
	$data = For ($i=1; $i -le $totalPages; $i++) {
		$query = Invoke-RestMethod -Uri ($apiuri+"?page=$i") -Headers @{"Authorization" = $auth_token}
		foreach ($e in $query.records) {
			If ($e.status -ne "Disabled") {
				[pscustomobject]@{
					Name = $e.name
					Extension = [int]$e.extensionnumber
					Email = $e.contact.email
					ID = $e.id
					Status = $e.status
				}
			}
		}
	}
	
	# If the user is found in RC, then process changes
	If ($data.email -contains $UserEmail) {
	Write-Host "RingCentral account found - disabling now" -fore green
		$extensionId = ($data | where email -eq $UserEmail).id
		$status = ($data | where email -eq $UserEmail).status
		$apiuri = "https://platform.ringcentral.com/restapi/v1.0/account/~/extension/$extensionId"
		
		# Check if the user ever activated their RC account
		# If not, we cant disable it, so enable it first then disable
		If ($status -eq "NotActivated") {
			$body = @{
				status = "Enabled"
			}
			$body = $body | ConvertTo-Json
			$updateQuery = Invoke-RestMethod -Uri $apiuri -ContentType "application/json" -Body $body -Headers @{"Authorization" = $auth_token} -Method Put
		} 
		# Disable their account
		$body = @{
			status = "Disabled"
		}
		$body = $body | ConvertTo-Json
		$updateQuery = Invoke-RestMethod -Uri $apiuri -ContentType "application/json" -Body $body -Headers @{"Authorization" = $auth_token} -Method Put
	}
	Else {
		# User email specified not found in RingCentral
		Write-Host "$UserEmail not found"
	}
}
