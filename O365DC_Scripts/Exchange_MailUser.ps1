#############################################################################
#                        Exchange_MailUser.ps1	 							#
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
$ErrorText = "Exchange_MailUser " + "`n" + $server + "`n"
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

$Exchange_MailUser_outputfile = $output_location + "\Exchange_MailUser.txt"

@(Get-MailUser) | ForEach-Object `
{
	$output_Exchange_MailUser = $_.DisplayName + "`t" + `
	$_.AcceptMessagesOnlyFrom + "`t" + `
	$_.AcceptMessagesOnlyFromDLMembers + "`t" + `
	$_.AcceptMessagesOnlyFromSendersOrMembers + "`t" + `
	$_.AccountDisabled + "`t" + `
	$_.AddressListMembership + "`t" + `
	$_.AdministrativeUnits + "`t" + `
	$_.AggregatedMailboxGuids + "`t" + `
	$_.Alias + "`t" + `
	$_.ArbitrationMailbox + "`t" + `
	$_.ArchiveDatabase + "`t" + `
	$_.ArchiveGuid + "`t" + `
	$_.ArchiveName + "`t" + `
	$_.ArchiveQuota + "`t" + `
	$_.ArchiveRelease + "`t" + `
	$_.ArchiveStatus + "`t" + `
	$_.ArchiveWarningQuota + "`t" + `
	$_.BypassModerationFromSendersOrMembers + "`t" + `
	$_.CalendarVersionStoreDisabled + "`t" + `
	$_.ComplianceTagHoldApplied + "`t" + `
	$_.CustomAttribute1 + "`t" + `
	$_.CustomAttribute10 + "`t" + `
	$_.CustomAttribute11 + "`t" + `
	$_.CustomAttribute12 + "`t" + `
	$_.CustomAttribute13 + "`t" + `
	$_.CustomAttribute14 + "`t" + `
	$_.CustomAttribute15 + "`t" + `
	$_.CustomAttribute2 + "`t" + `
	$_.CustomAttribute3 + "`t" + `
	$_.CustomAttribute4 + "`t" + `
	$_.CustomAttribute5 + "`t" + `
	$_.CustomAttribute6 + "`t" + `
	$_.CustomAttribute7 + "`t" + `
	$_.CustomAttribute8 + "`t" + `
	$_.CustomAttribute9 + "`t" + `
	$_.DataEncryptionPolicy + "`t" + `
	$_.DelayHoldApplied + "`t" + `
	$_.DeliverToMailboxAndForward + "`t" + `
	$_.DisabledArchiveDatabase + "`t" + `
	$_.DisabledArchiveGuid + "`t" + `
	$_.EmailAddresses + "`t" + `
	$_.EmailAddressPolicyEnabled + "`t" + `
	$_.EndDateForRetentionHold + "`t" + `
	$_.ExchangeGuid + "`t" + `
	$_.ExchangeUserAccountControl + "`t" + `
	$_.ExchangeVersion + "`t" + `
	$_.ExtensionCustomAttribute1 + "`t" + `
	$_.ExtensionCustomAttribute2 + "`t" + `
	$_.ExtensionCustomAttribute3 + "`t" + `
	$_.ExtensionCustomAttribute4 + "`t" + `
	$_.ExtensionCustomAttribute5 + "`t" + `
	$_.Extensions + "`t" + `
	$_.ExternalDirectoryObjectId + "`t" + `
	$_.ExternalEmailAddress + "`t" + `
	$_.ForwardingAddress + "`t" + `
	$_.GrantSendOnBehalfTo + "`t" + `
	$_.GuestInfo + "`t" + `
	$_.Guid + "`t" + `
	$_.HasPicture + "`t" + `
	$_.HasSpokenName + "`t" + `
	$_.HiddenFromAddressListsEnabled + "`t" + `
	$_.Identity + "`t" + `
	$_.ImmutableId + "`t" + `
	$_.InPlaceHolds + "`t" + `
	$_.IsDirSynced + "`t" + `
	$_.IsSoftDeletedByDisable + "`t" + `
	$_.IsSoftDeletedByRemove + "`t" + `
	$_.IssueWarningQuota + "`t" + `
	$_.IsValid + "`t" + `
	$_.JournalArchiveAddress + "`t" + `
	$_.LastExchangeChangedTime + "`t" + `
	$_.LegacyExchangeDN + "`t" + `
	$_.LitigationHoldDate + "`t" + `
	$_.LitigationHoldEnabled + "`t" + `
	$_.LitigationHoldOwner + "`t" + `
	$_.MacAttachmentFormat + "`t" + `
	$_.MailboxContainerGuid + "`t" + `
	$_.MailboxLocations + "`t" + `
	$_.MailboxMoveBatchName + "`t" + `
	$_.MailboxMoveFlags + "`t" + `
	$_.MailboxMoveRemoteHostName + "`t" + `
	$_.MailboxMoveSourceMDB + "`t" + `
	$_.MailboxMoveStatus + "`t" + `
	$_.MailboxMoveTargetMDB + "`t" + `
	$_.MailboxProvisioningConstraint + "`t" + `
	$_.MailboxProvisioningPreferences + "`t" + `
	$_.MailboxRegion + "`t" + `
	$_.MailboxRegionLastUpdateTime + "`t" + `
	$_.MailboxRelease + "`t" + `
	$_.MailTip + "`t" + `
	$_.MailTipTranslations + "`t" + `
	$_.MaxReceiveSize + "`t" + `
	$_.MaxSendSize + "`t" + `
	$_.MessageBodyFormat + "`t" + `
	$_.MessageFormat + "`t" + `
	$_.MicrosoftOnlineServicesID + "`t" + `
	$_.ModeratedBy + "`t" + `
	$_.ModerationEnabled + "`t" + `
	$_.Name + "`t" + `
	$_.OrganizationId + "`t" + `
	$_.OtherMail + "`t" + `
	$_.PersistedCapabilities + "`t" + `
	$_.PoliciesExcluded + "`t" + `
	$_.PoliciesIncluded + "`t" + `
	$_.PrimarySmtpAddress + "`t" + `
	$_.ProhibitSendQuota + "`t" + `
	$_.ProhibitSendReceiveQuota + "`t" + `
	$_.ProtocolSettings + "`t" + `
	$_.RecipientLimits + "`t" + `
	$_.RecipientType + "`t" + `
	$_.RecipientTypeDetails + "`t" + `
	$_.RecoverableItemsQuota + "`t" + `
	$_.RecoverableItemsWarningQuota + "`t" + `
	$_.RejectMessagesFrom + "`t" + `
	$_.RejectMessagesFromDLMembers + "`t" + `
	$_.RejectMessagesFromSendersOrMembers + "`t" + `
	$_.RequireSenderAuthenticationEnabled + "`t" + `
	$_.ResetPasswordOnNextLogon + "`t" + `
	$_.RetainDeletedItemsFor + "`t" + `
	$_.RetentionComment + "`t" + `
	$_.RetentionHoldEnabled + "`t" + `
	$_.RetentionUrl + "`t" + `
	$_.SamAccountName + "`t" + `
	$_.SendModerationNotifications + "`t" + `
	$_.SimpleDisplayName + "`t" + `
	$_.SingleItemRecoveryEnabled + "`t" + `
	$_.SKUAssigned + "`t" + `
	$_.StartDateForRetentionHold + "`t" + `
	$_.StsRefreshTokensValidFrom + "`t" + `
	$_.UMDtmfMap + "`t" + `
	$_.UsageLocation + "`t" + `
	$_.UseMapiRichTextFormat + "`t" + `
	$_.UsePreferMessageFormat + "`t" + `
	$_.UserCertificate + "`t" + `
	$_.UserPrincipalName + "`t" + `
	$_.UserSMimeCertificate + "`t" + `
	$_.WhenChangedUTC + "`t" + `
	$_.WhenCreatedUTC + "`t" + `
	$_.WhenMailboxCreated + "`t" + `
	$_.WhenSoftDeleted + "`t" + `
	$_.WindowsEmailAddress + "`t" + `
	$_.WindowsLiveID
	$output_Exchange_MailUser | Out-File -FilePath $Exchange_MailUser_outputfile -append 
}

$EventText = "Exchange_MailUser " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n" 

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}