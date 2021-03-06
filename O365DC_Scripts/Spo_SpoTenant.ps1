#############################################################################
#                    	    Spo_SpoTenant.ps1		 							#
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
$ErrorText = "Spo_SpoTenant " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
Try{$ErrorLog.WriteEntry($ErrorText,"Error", 100)}catch{}
}

set-location -LiteralPath $location
$output_location = $location + "\output\Sharepoint"

if ((Test-Path -LiteralPath $output_location) -eq $false)
    {New-Item -Path $output_location -ItemType directory -Force}

$Spo_SpoTenant_outputfile = $output_location + "\Spo_SpoTenant.txt"

@(Get-SpoTenant) | ForEach-Object `
{
	$output_Spo_SpoTenant = "Tenant" + "`t" + `
	$_.AllowDownloadingNonWebViewableFiles + "`t" + `
	$_.AllowEditing + "`t" + `
	$_.ApplyAppEnforcedRestrictionsToAdHocRecipients + "`t" + `
	$_.BccExternalSharingInvitations + "`t" + `
	$_.BccExternalSharingInvitationsList + "`t" + `
	$_.CommentsOnSitePagesDisabled + "`t" + `
	$_.CompatibilityRange + "`t" + `
	$_.ConditionalAccessPolicy + "`t" + `
	$_.DefaultLinkPermission + "`t" + `
	$_.DefaultSharingLinkType + "`t" + `
	$_.DisabledWebPartIds + "`t" + `
	$_.DisallowInfectedFileDownload + "`t" + `
	$_.DisplayStartASiteOption + "`t" + `
	$_.EmailAttestationReAuthDays + "`t" + `
	$_.EmailAttestationRequired + "`t" + `
	$_.EnableGuestSignInAcceleration + "`t" + `
	$_.EnableMinimumVersionRequirement + "`t" + `
	$_.ExternalServicesEnabled + "`t" + `
	$_.FileAnonymousLinkType + "`t" + `
	$_.FilePickerExternalImageSearchEnabled + "`t" + `
	$_.FolderAnonymousLinkType + "`t" + `
	$_.IPAddressAllowList + "`t" + `
	$_.IPAddressEnforcement + "`t" + `
	$_.IPAddressWACTokenLifetime + "`t" + `
	$_.LegacyAuthProtocolsEnabled + "`t" + `
	$_.LimitedAccessFileType + "`t" + `
	$_.NoAccessRedirectUrl + "`t" + `
	$_.NotificationsInOneDriveForBusinessEnabled + "`t" + `
	$_.NotificationsInSharePointEnabled + "`t" + `
	$_.NotifyOwnersWhenInvitationsAccepted + "`t" + `
	$_.NotifyOwnersWhenItemsReshared + "`t" + `
	$_.ODBAccessRequests + "`t" + `
	$_.ODBMembersCanShare + "`t" + `
	$_.OfficeClientADALDisabled + "`t" + `
	$_.OneDriveForGuestsEnabled + "`t" + `
	$_.OneDriveStorageQuota + "`t" + `
	$_.OrgNewsSiteUrl + "`t" + `
	$_.OrphanedPersonalSitesRetentionPeriod + "`t" + `
	$_.OwnerAnonymousNotification + "`t" + `
	$_.PermissiveBrowserFileHandlingOverride + "`t" + `
	$_.PreventExternalUsersFromResharing + "`t" + `
	$_.ProvisionSharedWithEveryoneFolder + "`t" + `
	$_.PublicCdnAllowedFileTypes + "`t" + `
	$_.PublicCdnEnabled + "`t" + `
	$_.PublicCdnOrigins + "`t" + `
	$_.RequireAcceptingAccountMatchInvitedAccount + "`t" + `
	$_.RequireAnonymousLinksExpireInDays + "`t" + `
	$_.ResourceQuota + "`t" + `
	$_.ResourceQuotaAllocated + "`t" + `
	$_.SearchResolveExactEmailOrUPN + "`t" + `
	$_.SharingAllowedDomainList + "`t" + `
	$_.SharingBlockedDomainList + "`t" + `
	$_.SharingCapability + "`t" + `
	$_.SharingDomainRestrictionMode + "`t" + `
	$_.ShowAllUsersClaim + "`t" + `
	$_.ShowEveryoneClaim + "`t" + `
	$_.ShowEveryoneExceptExternalUsersClaim + "`t" + `
	$_.ShowPeoplePickerSuggestionsForGuestUsers + "`t" + `
	$_.SignInAccelerationDomain + "`t" + `
	$_.SocialBarOnSitePagesDisabled + "`t" + `
	$_.SpecialCharactersStateInFileFolderNames + "`t" + `
	$_.StartASiteFormUrl + "`t" + `
	$_.StorageQuota + "`t" + `
	$_.StorageQuotaAllocated + "`t" + `
	$_.SyncPrivacyProfileProperties + "`t" + `
	$_.UseFindPeopleInPeoplePicker + "`t" + `
	$_.UsePersistentCookiesForExplorerView + "`t" + `
	$_.UserVoiceForFeedbackEnabled
	$output_Spo_SpoTenant | Out-File -FilePath $Spo_SpoTenant_outputfile -append
}

$EventText = "Spo_SpoTenant " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n"

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
