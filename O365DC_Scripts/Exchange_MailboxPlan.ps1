#############################################################################
#                    Exchange_MailboxPlan.ps1		 						#
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
$ErrorText = "Exchange_MailboxPlan " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
Try{$ErrorLog.WriteEntry($ErrorText,"Error", 100)}catch{}
}

set-location -LiteralPath $location
$output_location = $location + "\output\Exchange"

if ((Test-Path -LiteralPath $output_location) -eq $false)
    {New-Item -Path $output_location -ItemType directory -Force}

$Exchange_MailboxPlan_outputfile = $output_location + "\Exchange_MailboxPlan.txt"

@(Get-MailboxPlan) | ForEach-Object `
{
	$output_Exchange_MailboxPlan = $_.DisplayName + "`t" + `
	$_.AccountDisabled + "`t" + `
	$_.AddressBookPolicy + "`t" + `
	$_.AddressListMembership + "`t" + `
	$_.AdministrativeUnits + "`t" + `
	$_.AggregatedMailboxGuids + "`t" + `
	$_.Alias + "`t" + `
	$_.AntispamBypassEnabled + "`t" + `
	$_.ArchiveDatabase + "`t" + `
	$_.ArchiveDomain + "`t" + `
	$_.ArchiveGuid + "`t" + `
	$_.ArchiveName + "`t" + `
	$_.ArchiveQuota + "`t" + `
	$_.ArchiveRelease + "`t" + `
	$_.ArchiveState + "`t" + `
	$_.ArchiveStatus + "`t" + `
	$_.ArchiveWarningQuota + "`t" + `
	$_.AuditEnabled + "`t" + `
	$_.AuditLogAgeLimit + "`t" + `
	$_.AutoExpandingArchiveEnabled + "`t" + `
	$_.CalendarLoggingQuota + "`t" + `
	$_.CalendarRepairDisabled + "`t" + `
	$_.CalendarVersionStoreDisabled + "`t" + `
	$_.ComplianceTagHoldApplied + "`t" + `
	$_.CustomAttribute1 + "`t" + `
	$_.Database + "`t" + `
	$_.DataEncryptionPolicy + "`t" + `
	$_.DefaultPublicFolderMailbox + "`t" + `
	$_.DelayHoldApplied + "`t" + `
	$_.DeliverToMailboxAndForward + "`t" + `
	$_.DisabledArchiveDatabase + "`t" + `
	$_.DisabledArchiveGuid + "`t" + `
	$_.DisabledMailboxLocations + "`t" + `
	$_.DowngradeHighPriorityMessagesEnabled + "`t" + `
	$_.EffectivePublicFolderMailbox + "`t" + `
	$_.ElcProcessingDisabled + "`t" + `
	$_.EmailAddressPolicyEnabled + "`t" + `
	$_.EndDateForRetentionHold + "`t" + `
	$_.ExchangeGuid + "`t" + `
	$_.ExchangeUserAccountControl + "`t" + `
	$_.ExchangeVersion + "`t" + `
	$_.Extensions + "`t" + `
	$_.ExternalOofOptions + "`t" + `
	$_.GeneratedOfflineAddressBooks + "`t" + `
	$_.Guid + "`t" + `
	$_.HasPicture + "`t" + `
	$_.HasSnackyAppData + "`t" + `
	$_.HasSpokenName + "`t" + `
	$_.HiddenFromAddressListsEnabled + "`t" + `
	$_.Identity + "`t" + `
	$_.ImListMigrationCompleted + "`t" + `
	$_.InactiveMailboxRetireTime + "`t" + `
	$_.IncludeInGarbageCollection + "`t" + `
	$_.InPlaceHolds + "`t" + `
	$_.IsDefault + "`t" + `
	$_.IsDefaultForPreviousVersion + "`t" + `
	$_.IsDirSynced + "`t" + `
	$_.IsExcludedFromServingHierarchy + "`t" + `
	$_.IsHierarchyReady + "`t" + `
	$_.IsHierarchySyncEnabled + "`t" + `
	$_.IsMachineToPersonTextMessagingEnabled + "`t" + `
	$_.IsPersonToPersonTextMessagingEnabled + "`t" + `
	$_.IsPilotMailboxPlan + "`t" + `
	$_.IsSoftDeletedByDisable + "`t" + `
	$_.IsSoftDeletedByRemove + "`t" + `
	$_.IssueWarningQuota + "`t" + `
	$_.IsValid + "`t" + `
	$_.JournalArchiveAddress + "`t" + `
	$_.LitigationHoldDate + "`t" + `
	$_.LitigationHoldDuration + "`t" + `
	$_.LitigationHoldEnabled + "`t" + `
	$_.LitigationHoldOwner + "`t" + `
	$_.MailboxContainerGuid + "`t" + `
	$_.MailboxLocations + "`t" + `
	$_.MailboxMoveBatchName + "`t" + `
	$_.MailboxMoveFlags + "`t" + `
	$_.MailboxMoveRemoteHostName + "`t" + `
	$_.MailboxMoveSourceMDB + "`t" + `
	$_.MailboxMoveStatus + "`t" + `
	$_.MailboxMoveTargetMDB + "`t" + `
	$_.MailboxPlan + "`t" + `
	$_.MailboxPlanRelease + "`t" + `
	$_.MailboxProvisioningConstraint + "`t" + `
	$_.MailboxProvisioningPreferences + "`t" + `
	$_.MailboxRegion + "`t" + `
	$_.MailboxRegionLastUpdateTime + "`t" + `
	$_.MailboxRelease + "`t" + `
	$_.ManagedFolderMailboxPolicy + "`t" + `
	$_.MaxBlockedSenders + "`t" + `
	$_.MaxReceiveSize + "`t" + `
	$_.MaxSafeSenders + "`t" + `
	$_.MaxSendSize + "`t" + `
	$_.MessageCopyForSendOnBehalfEnabled + "`t" + `
	$_.MessageCopyForSentAsEnabled + "`t" + `
	$_.MessageRecallProcessingEnabled + "`t" + `
	$_.MessageTrackingReadStatusEnabled + "`t" + `
	$_.ModeratedBy + "`t" + `
	$_.Name + "`t" + `
	$_.NetID + "`t" + `
	$_.NonCompliantDevices + "`t" + `
	$_.ObjectState + "`t" + `
	$_.OfflineAddressBook + "`t" + `
	$_.OrganizationId + "`t" + `
	$_.OriginatingServer + "`t" + `
	$_.OrphanSoftDeleteTrackingTime + "`t" + `
	$_.PersistedCapabilities + "`t" + `
	$_.PoliciesExcluded + "`t" + `
	$_.PoliciesIncluded + "`t" + `
	$_.ProhibitSendQuota + "`t" + `
	$_.ProhibitSendReceiveQuota + "`t" + `
	$_.ProtocolSettings + "`t" + `
	$_.QueryBaseDN + "`t" + `
	$_.QueryBaseDNRestrictionEnabled + "`t" + `
	$_.RecipientLimits + "`t" + `
	$_.RecipientType + "`t" + `
	$_.RecipientTypeDetails + "`t" + `
	$_.ReconciliationId + "`t" + `
	$_.RecoverableItemsQuota + "`t" + `
	$_.RecoverableItemsWarningQuota + "`t" + `
	$_.RemoteAccountPolicy + "`t" + `
	$_.RemoteRecipientType + "`t" + `
	$_.RequireSenderAuthenticationEnabled + "`t" + `
	$_.ResetPasswordOnNextLogon + "`t" + `
	$_.ResourceType + "`t" + `
	$_.RetainDeletedItemsFor + "`t" + `
	$_.RetainDeletedItemsUntilBackup + "`t" + `
	$_.RetentionComment + "`t" + `
	$_.RetentionHoldEnabled + "`t" + `
	$_.RetentionPolicy + "`t" + `
	$_.RetentionUrl + "`t" + `
	$_.RoleAssignmentPolicy + "`t" + `
	$_.RoomMailboxAccountEnabled + "`t" + `
	$_.RulesQuota + "`t" + `
	$_.SCLDeleteEnabled + "`t" + `
	$_.SCLDeleteThreshold + "`t" + `
	$_.SCLJunkEnabled + "`t" + `
	$_.SCLJunkThreshold + "`t" + `
	$_.SCLQuarantineEnabled + "`t" + `
	$_.SCLQuarantineThreshold + "`t" + `
	$_.SCLRejectEnabled + "`t" + `
	$_.SCLRejectThreshold + "`t" + `
	$_.SharingPolicy + "`t" + `
	$_.SiloName + "`t" + `
	$_.SingleItemRecoveryEnabled + "`t" + `
	$_.StartDateForRetentionHold + "`t" + `
	$_.StsRefreshTokensValidFrom + "`t" + `
	$_.ThrottlingPolicy + "`t" + `
	$_.UMEnabled + "`t" + `
	$_.UnifiedMailbox + "`t" + `
	$_.UseDatabaseQuotaDefaults + "`t" + `
	$_.UseDatabaseRetentionDefaults + "`t" + `
	$_.UserCertificate + "`t" + `
	$_.UserPrincipalName + "`t" + `
	$_.UserSMimeCertificate + "`t" + `
	$_.WhenChangedUTC + "`t" + `
	$_.WhenCreatedUTC

	$output_Exchange_MailboxPlan | Out-File -FilePath $Exchange_MailboxPlan_outputfile -append 
}


$EventText = "Exchange_MailboxPlan " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n" 

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}