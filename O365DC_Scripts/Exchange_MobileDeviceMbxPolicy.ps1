#############################################################################
#                  Exchange_ActiveSyncMbxPolicy.ps1							#
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
$ErrorText = "Exchange_ActiveSyncMbxPolicy " + "`n" + $server + "`n"
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

$Exchange_ASMbxPol_outputfile = $output_location + "\Exchange_MobileDeviceMbxPolicy.txt"

@(Get-MobileDeviceMailboxPolicy) | ForEach-Object `
{
	# Some property names changed in Get-MobileDeviceMailboxPolicy
	$output_Exchange_ASMbxPol = $_.Name + "`t" + `
		$_.AllowNonProvisionableDevices + "`t" + `
		$_.AlphanumericPasswordRequired + "`t" + `
		$_.AttachmentsEnabled + "`t" + `
		$_.DeviceEncryptionEnabled + "`t" + `
		$_.RequireStorageCardEncryption + "`t" + `
		$_.PasswordEnabled + "`t" + `
		$_.PasswordRecoveryEnabled + "`t" + `
		$_.DevicePolicyRefreshInterval + "`t" + `
		$_.AllowSimplePassword + "`t" + `
		$_.MaxAttachmentSize + "`t" + `
		$_.WSSAccessEnabled + "`t" + `
		$_.UNCAccessEnabled + "`t" + `
		$_.MinPasswordLength + "`t" + `
		$_.MaxInactivityTimeLock + "`t" + `
		$_.MaxPasswordFailedAttempts + "`t" + `
		$_.PasswordExpiration + "`t" + `
		$_.PasswordHistory + "`t" + `
		$_.IsDefault + "`t" + `
		$_.AllowApplePushNotifications + "`t" + `
		$_.AllowMicrosoftPushNotifications + "`t" + `
		$_.AllowGooglePushNotifications + "`t" + `
		$_.AllowStorageCard + "`t" + `
		$_.AllowCamera + "`t" + `
		$_.RequireDeviceEncryption + "`t" + `
		$_.AllowUnsignedApplications + "`t" + `
		$_.AllowUnsignedInstallationPackages + "`t" + `
		$_.AllowWiFi + "`t" + `
		$_.AllowTextMessaging + "`t" + `
		$_.AllowPOPIMAPEmail + "`t" + `
		$_.AllowIrDA + "`t" + `
		$_.RequireManualSyncWhenRoaming + "`t" + `
		$_.AllowDesktopSync + "`t" + `
		$_.AllowHTMLEmail + "`t" + `
		$_.RequireSignedSMIMEMessages + "`t" + `
		$_.RequireEncryptedSMIMEMessages + "`t" + `
		$_.AllowSMIMESoftCerts + "`t" + `
		$_.AllowBrowser + "`t" + `
		$_.AllowConsumerEmail + "`t" + `
		$_.AllowRemoteDesktop + "`t" + `
		$_.AllowInternetSharing + "`t" + `
		$_.AllowBluetooth + "`t" + `
		$_.MaxCalendarAgeFilter + "`t" + `
		$_.MaxEmailAgeFilter + "`t" + `
		$_.RequireSignedSMIMEAlgorithm + "`t" + `
		$_.RequireEncryptionSMIMEAlgorithm + "`t" + `
		$_.AllowSMIMEEncryptionAlgorithmNegotiation + "`t" + `
		$_.MinPasswordComplexCharacters + "`t" + `
		$_.MaxEmailBodyTruncationSize + "`t" + `
		$_.MaxEmailHTMLBodyTruncationSize + "`t" + `
		$_.UnapprovedInROMApplicationList + "`t" + `
		$_.ApprovedApplicationList + "`t" + `
		$_.AllowExternalDeviceManagement + "`t" + `
		$_.MobileOTAUpdateMode + "`t" + `
		$_.AllowMobileOTAUpdate + "`t" + `
		$_.IrmEnabled 
	$output_Exchange_ASMbxPol | Out-File -FilePath $Exchange_ASMbxPol_outputfile -append 
}

$EventText = "Exchange_ActiveSyncMbxPolicy " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n" 

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
