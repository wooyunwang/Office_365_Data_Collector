#############################################################################
#                          Exchange_Mbx.ps1 								#
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
$ErrorText = "Exchange_Mbx " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
Try{$ErrorLog.WriteEntry($ErrorText,"Error", 100)}catch{}
}

set-location -LiteralPath $location
$output_location = $location + "\output\Exchange\GetMbx"

if ((Test-Path -LiteralPath $output_location) -eq $false)
    {New-Item -Path $output_location -ItemType directory -Force}

@(Get-Content -Path ".\CheckedMailbox.Set$i.txt") | ForEach-Object `
{
	$Exchange_Mbx_outputfile = $output_location + "\\Set$i~~GetMbx.txt"
    $mailbox = $_
	@(Get-Mailbox -identity $mailbox) | ForEach-Object `
	{
		$output_Exchange_Mbx = $mailbox + "`t" + `
			$_.identity + "`t" + `
			$_.Database + "`t" + `
			$_.UseDatabaseRetentionDefaults + "`t" + `
			$_.RetainDeletedItemsUntilBackup + "`t" + `
			$_.DeliverToMailboxAndForward + "`t" + `
			$_.LitigationHoldEnabled + "`t" + `
			$_.SingleItemRecoveryEnabled + "`t" + `
			$_.RetentionHoldEnabled + "`t" + `
			$_.EndDateForRetentionHold + "`t" + `
			$_.StartDateForRetentionHold + "`t" + `
			$_.RetentionComment + "`t" + `
			$_.RetentionUrl + "`t" + `
			$_.LitigationHoldDate + "`t" + `
			$_.LitigationHoldOwner + "`t" + `
			$_.ElcProcessingDisabled + "`t" + `
			$_.ComplianceTagHoldApplied + "`t" + `
			$_.LitigationHoldDuration + "`t" + `
			$_.ManagedFolderMailboxPolicy + "`t" + `
			$_.RetentionPolicy + "`t" + `
			$_.AddressBookPolicy + "`t" + `
			$_.CalendarRepairDisabled + "`t" + `
			$_.ForwardingAddress + "`t" + `
			$_.ForwardingSmtpAddress + "`t" + `
			$_.RetainDeletedItemsFor + "`t" + `
			$_.IsMailboxEnabled + "`t" + `
			$_.ProhibitSendQuota + "`t" + `
			$_.ProhibitSendReceiveQuota + "`t" + `
			$_.RecoverableItemsQuota + "`t" + `
			$_.RecoverableItemsWarningQuota + "`t" + `
			$_.CalendarLoggingQuota + "`t" + `
			$_.IsResource + "`t" + `
			$_.IsLinked + "`t" + `
			$_.IsShared + "`t" + `
			$_.IsRootPublicFolderMailbox + "`t" + `
			$_.RoomMailboxAccountEnabled + "`t" + `
			$_.SCLDeleteThreshold + "`t" + `
			$_.SCLDeleteEnabled + "`t" + `
			$_.SCLRejectThreshold + "`t" + `
			$_.SCLRejectEnabled + "`t" + `
			$_.SCLQuarantineThreshold + "`t" + `
			$_.SCLQuarantineEnabled + "`t" + `
			$_.SCLJunkThreshold + "`t" + `
			$_.SCLJunkEnabled + "`t" + `
			$_.AntispamBypassEnabled + "`t" + `
			$_.ServerName + "`t" + `
			$_.UseDatabaseQuotaDefaults + "`t" + `
			$_.IssueWarningQuota + "`t" + `
			$_.RulesQuota + "`t" + `
			$_.Office + "`t" + `
			$_.UserPrincipalName + "`t" + `
			$_.UMEnabled + "`t" + `
			$_.WindowsLiveID + "`t" + `
			$_.MicrosoftOnlineServicesID + "`t" + `
			$_.RoleAssignmentPolicy + "`t" + `
			$_.DefaultPublicFolderMailbox + "`t" + `
			$_.EffectivePublicFolderMailbox + "`t" + `
			$_.SharingPolicy + "`t" + `
			$_.RemoteAccountPolicy + "`t" + `
			$_.MailboxPlan + "`t" + `
			$_.ArchiveDatabase + "`t" + `
			$_.ArchiveName + "`t" + `
			$_.ArchiveQuota + "`t" + `
			$_.ArchiveWarningQuota + "`t" + `
			$_.ArchiveDomain + "`t" + `
			$_.ArchiveStatus + "`t" + `
			$_.ArchiveState + "`t" + `
			$_.AutoExpandingArchiveEnabled + "`t" + `
			$_.DisabledMailboxLocations + "`t" + `
			$_.RemoteRecipientType + "`t" + `
			$_.UserSMimeCertificate + "`t" + `
			$_.UserCertificate + "`t" + `
			$_.CalendarVersionStoreDisabled + "`t" + `
			$_.SKUAssigned + "`t" + `
			$_.AuditEnabled + "`t" + `
			$_.AuditLogAgeLimit + "`t" + `
			$_.UsageLocation + "`t" + `
			$_.AccountDisabled + "`t" + `
			$_.NonCompliantDevices + "`t" + `
			$_.DataEncryptionPolicy + "`t" + `
			$_.HasPicture + "`t" + `
			$_.HasSpokenName + "`t" + `
			$_.IsDirSynced + "`t" + `
			$_.AcceptMessagesOnlyFrom + "`t" + `
			$_.AcceptMessagesOnlyFromDLMembers + "`t" + `
			$_.AcceptMessagesOnlyFromSendersOrMembers + "`t" + `
			$_.Alias + "`t" + `
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
			$_.ExtensionCustomAttribute1 + "`t" + `
			$_.ExtensionCustomAttribute2 + "`t" + `
			$_.ExtensionCustomAttribute3 + "`t" + `
			$_.ExtensionCustomAttribute4 + "`t" + `
			$_.ExtensionCustomAttribute5 + "`t" + `
			$_.DisplayName + "`t" + `
			$_.EmailAddresses + "`t" + `
			$_.GrantSendOnBehalfTo + "`t" + `
			$_.HiddenFromAddressListsEnabled + "`t" + `
			$_.MaxSendSize + "`t" + `
			$_.MaxReceiveSize + "`t" + `
			$_.ModeratedBy + "`t" + `
			$_.ModerationEnabled + "`t" + `
			$_.EmailAddressPolicyEnabled + "`t" + `
			$_.PrimarySmtpAddress + "`t" + `
			$_.RecipientType + "`t" + `
			$_.RecipientTypeDetails + "`t" + `
			$_.RejectMessagesFrom + "`t" + `
			$_.RejectMessagesFromDLMembers + "`t" + `
			$_.RejectMessagesFromSendersOrMembers + "`t" + `
			$_.RequireSenderAuthenticationEnabled
		$output_Exchange_Mbx | Out-File -FilePath $Exchange_Mbx_outputfile -append 
	}
}

$EventText = "Exchange_Mbx " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n" 

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
