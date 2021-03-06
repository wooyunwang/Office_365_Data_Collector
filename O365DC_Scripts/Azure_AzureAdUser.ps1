#############################################################################
#                        Azure_AzureAdUser.ps1		 						#
#                                     			 							#
#                               4.0.2    		 							#
#                                     			 							#
#   This Sample Code is provided for the purpose of illustration only       #
#   and is not intended to be used in a production environment.  THIS       #
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #
#   right to use and modify the Sample Code and to reproduce and distribute #
#   the object code form of the Sample Code, provided that You agree:       #
#   (i) to not use Our name, logo, or trademarks to market Your software    #
#   product in which the Sample Code is embedded; (ii) to include a valid   #
#   copyright notice on Your software product in which the Sample Code is   #
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #
#   Our suppliers from and against any claims or lawsuits, including        #
#   attorneys' fees, that arise or result from the use or distribution      #
#   of the Sample Code.                                                     #
#                                     			 							#
#############################################################################
Param($location,$server,$i,$PSSession)

$a = get-date

$ErrorActionPreference = "Stop"
Trap {
$ErrorText = "Azure_AzureAdUser " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
Try{$ErrorLog.WriteEntry($ErrorText,"Error", 100)}catch{}
}

set-location -LiteralPath $location
$output_location = $location + "\output\Azure"

if ((Test-Path -LiteralPath $output_location) -eq $false)
    {New-Item -Path $output_location -ItemType directory -Force}

$Azure_AzureAdUser_outputfile = $output_location + "\Azure_AzureAdUser.txt"

@(Get-AzureADUser) | ForEach-Object `
{
	If ($_.AssignedLicenses -ne $null){$AssignedLicenses = "True"}
		else{$AssignedLicenses = "False"}
	If ($_.AssignedPlans -ne $null){$AssignedPlans = "True"}
		else{$AssignedPlans = "False"}
	If ($_.ProvisionedPlans -ne $null){$ProvisionedPlans = "True"}
		else{$ProvisionedPlans = "False"}
	$output_Azure_AzureAdUser = $_.UserPrincipalName + "`t" + `
	$_.AccountEnabled + "`t" + `
	$_.AgeGroup + "`t" + `
	$AssignedLicenses + "`t" + `
	$AssignedPlans + "`t" + `
	$_.City + "`t" + `
	$_.CompanyName + "`t" + `
	$_.ConsentProvidedForMinor + "`t" + `
	$_.Country + "`t" + `
	$_.CreationType + "`t" + `
	$_.CreationType + "`t" + `
	$_.DeletionTimestamp + "`t" + `
	$_.DirSyncEnabled + "`t" + `
	$_.DisplayName + "`t" + `
	$_.ExtensionProperty.createdDateTime + "`t" + `
	$_.ExtensionProperty.employeeId + "`t" + `
	$_.ExtensionProperty.odata.type + "`t" + `
	$_.ExtensionProperty.onPremisesDistinguishedName + "`t" + `
	$_.ExtensionProperty.userIdentities + "`t" + `
	$_.FacsimileTelephoneNumber + "`t" + `
	$_.GivenName + "`t" + `
	$_.ImmutableId + "`t" + `
	$_.IsCompromised + "`t" + `
	$_.JobTitle + "`t" + `
	$_.LastDirSyncTime + "`t" + `
	$_.LegalAgeGroupClassification + "`t" + `
	$_.Mail + "`t" + `
	$_.MailNickName + "`t" + `
	$_.Mobile + "`t" + `
	$_.ObjectType + "`t" + `
	$_.OnPremisesSecurityIdentifier + "`t" + `
	$_.OtherMails + "`t" + `
	$_.PasswordPolicies + "`t" + `
	$_.PasswordProfile.ForceChangePasswordNextLogin + "`t" + `
	$_.PasswordProfile.EnforceChangePasswordPolicy + "`t" + `
	$_.PhysicalDeliveryOfficeName + "`t" + `
	$_.PostalCode + "`t" + `
	$_.PreferredLanguage + "`t" + `
	$ProvisionedPlans + "`t" + `
	$_.ProvisioningErrors + "`t" + `
	$_.ProxyAddresses + "`t" + `
	$_.RefreshTokensValidFromDateTime + "`t" + `
	$_.ShowInAddressList + "`t" + `
	$_.SignInNames + "`t" + `
	$_.SipProxyAddress + "`t" + `
	$_.State + "`t" + `
	$_.StreetAddress + "`t" + `
	$_.Surname + "`t" + `
	$_.TelephoneNumber + "`t" + `
	$_.UsageLocation + "`t" + `
	$_.UserState + "`t" + `
	$_.UserStateChangedOn + "`t" + `
	$_.UserType
	$output_Azure_AzureAdUser | Out-File -FilePath $Azure_AzureAdUser_outputfile -append
}

$EventText = "Azure_AzureAdUser " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n"

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
