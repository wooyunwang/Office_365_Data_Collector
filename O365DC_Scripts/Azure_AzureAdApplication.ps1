#############################################################################
#                      Azure_AzureAdApplication.ps1		 					#
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
$ErrorText = "Azure_AzureAdApplication " + "`n" + $server + "`n"
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

$Azure_AzureAdApplication_outputfile = $output_location + "\Azure_AzureAdApplication.txt"

@(Get-AzureAdApplication) | ForEach-Object `
{
	$output_Azure_AzureAdApplication = $_.DisplayName + "`t" + `
	$_.AllowGuestsSignIn + "`t" + `
	$_.AllowPassthroughUsers + "`t" + `
	$_.AppId + "`t" + `
	$_.AppLogoUrl + "`t" + `
	#$_.AppRoles.AllowedMemberTypes + "`t" + `
	#$_.AppRoles.Description + "`t" + `
	#$_.AppRoles.DisplayName + "`t" + `
	#$_.AppRoles.Id + "`t" + `
	#$_.AppRoles.IsEnabled + "`t" + `
	#$_.AppRoles.Value + "`t" + `
	$_.AvailableToOtherTenants + "`t" + `
	$_.DeletionTimestamp + "`t" + `
	$_.ErrorUrl + "`t" + `
	$_.GroupMembershipClaims + "`t" + `
	$_.Homepage + "`t" + `
	$_.IdentifierUris + "`t" + `
	$_.IsDeviceOnlyAuthSupported + "`t" + `
	$_.IsDisabled + "`t" + `
	$_.KeyCredentials + "`t" + `
	$_.KnownClientApplications + "`t" + `
	$_.LogoutUrl + "`t" + `
	$_.Oauth2AllowImplicitFlow + "`t" + `
	$_.Oauth2AllowUrlPathMatching + "`t" + `
	$_.Oauth2Permissions.AdminConsentDescription + "`t" + `
	$_.Oauth2Permissions.AdminConsentDisplayName + "`t" + `
	$_.Oauth2Permissions.Id + "`t" + `
	$_.Oauth2Permissions.IsEnabled + "`t" + `
	$_.Oauth2Permissions.Type + "`t" + `
	$_.Oauth2Permissions.UserConsentDescription + "`t" + `
	$_.Oauth2Permissions.UserConsentDisplayName + "`t" + `
	$_.Oauth2Permissions.Value + "`t" + `
	$_.Oauth2RequirePostResponse + "`t" + `
	$_.ObjectId + "`t" + `
	$_.ObjectType + "`t" + `
	$_.OptionalClaims + "`t" + `
	$_.OrgRestrictions + "`t" + `
	$_.ParentalControlSettings.CountriesBlockedForMinors + "`t" + `
	$_.ParentalControlSettings.LegalAgeGroupRule + "`t" + `
	$_.PreAuthorizedApplications + "`t" + `
	$_.PublicClient + "`t" + `
	$_.PublisherDomain + "`t" + `
	$_.RecordConsentConditions + "`t" + `
	$_.ReplyUrls + "`t" + `
	$_.SamlMetadataUrl + "`t" + `
	$_.SignInAudience + "`t" + `
	$_.WwwHomepage
	$output_Azure_AzureAdApplication | Out-File -FilePath $Azure_AzureAdApplication_outputfile -append
}

$EventText = "Azure_AzureAdApplication " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n"

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
