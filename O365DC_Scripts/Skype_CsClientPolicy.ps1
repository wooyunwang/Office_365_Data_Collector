#############################################################################
#                       Skype_CsClientPolicy.ps1		 					#
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
$ErrorText = "Skype_CsClientPolicy " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
Try{$ErrorLog.WriteEntry($ErrorText,"Error", 100)}catch{}
}

set-location -LiteralPath $location
$output_location = $location + "\output\Skype"

if ((Test-Path -LiteralPath $output_location) -eq $false)
    {New-Item -Path $output_location -ItemType directory -Force}

$Skype_CsClientPolicy_outputfile = $output_location + "\Skype_CsClientPolicy.txt"

@(Get-CsClientPolicy) | ForEach-Object `
{
	$output_Skype_CsClientPolicy = [string]$_.Identity + "`t" + `
	$_.AddressBookAvailability + "`t" + `
	$_.AttendantSafeTransfer + "`t" + `
	$_.AutoDiscoveryRetryInterval + "`t" + `
	$_.BlockConversationFromFederatedContacts + "`t" + `
	$_.CalendarStatePublicationInterval + "`t" + `
	$_.ConferenceIMIdleTimeout + "`t" + `
	$_.CustomizedHelpUrl + "`t" + `
	$_.CustomLinkInErrorMessages + "`t" + `
	$_.CustomStateUrl + "`t" + `
	$_.Description + "`t" + `
	$_.DGRefreshInterval + "`t" + `
	$_.DisableCalendarPresence + "`t" + `
	$_.DisableContactCardOrganizationTab + "`t" + `
	$_.DisableEmailComparisonCheck + "`t" + `
	$_.DisableEmoticons + "`t" + `
	$_.DisableFederatedPromptDisplayName + "`t" + `
	$_.DisableFeedsTab + "`t" + `
	$_.DisableFreeBusyInfo + "`t" + `
	$_.DisableHandsetOnLockedMachine + "`t" + `
	$_.DisableHtmlIm + "`t" + `
	$_.DisableInkIM + "`t" + `
	$_.DisableMeetingSubjectAndLocation + "`t" + `
	$_.DisableOneNote12Integration + "`t" + `
	$_.DisableOnlineContextualSearch + "`t" + `
	$_.DisablePhonePresence + "`t" + `
	$_.DisablePICPromptDisplayName + "`t" + `
	$_.DisablePoorDeviceWarnings + "`t" + `
	$_.DisablePoorNetworkWarnings + "`t" + `
	$_.DisablePresenceNote + "`t" + `
	$_.DisableRTFIM + "`t" + `
	$_.DisableSavingIM + "`t" + `
	$_.DisplayPhoto + "`t" + `
	$_.EnableAppearOffline + "`t" + `
	$_.EnableCallLogAutoArchiving + "`t" + `
	$_.EnableClientAutoPopulateWithTeam + "`t" + `
	$_.EnableClientMusicOnHold + "`t" + `
	$_.EnableConversationWindowTabs + "`t" + `
	$_.EnableEnterpriseCustomizedHelp + "`t" + `
	$_.EnableEventLogging + "`t" + `
	$_.EnableExchangeContactsFolder + "`t" + `
	$_.EnableExchangeContactSync + "`t" + `
	$_.EnableExchangeDelegateSync + "`t" + `
	$_.EnableFullScreenVideo + "`t" + `
	$_.EnableHighPerformanceConferencingAppSharing + "`t" + `
	$_.EnableHighPerformanceP2PAppSharing + "`t" + `
	$_.EnableHotdesking + "`t" + `
	$_.EnableIMAutoArchiving + "`t" + `
	$_.EnableMediaRedirection + "`t" + `
	$_.EnableMeetingEngagement + "`t" + `
	$_.EnableNotificationForNewSubscribers + "`t" + `
	$_.EnableOnlineFeedback + "`t" + `
	$_.EnableOnlineFeedbackScreenshots + "`t" + `
	$_.EnableServerConversationHistory + "`t" + `
	$_.EnableSkypeUI + "`t" + `
	$_.EnableSQMData + "`t" + `
	$_.EnableTracing + "`t" + `
	$_.EnableUnencryptedFileTransfer + "`t" + `
	$_.EnableURL + "`t" + `
	$_.EnableViewBasedSubscriptionMode + "`t" + `
	$_.EnableVOIPCallDefault + "`t" + `
	$_.ExcludedContactFolders + "`t" + `
	$_.HelpEnvironment + "`t" + `
	$_.HotdeskingTimeout + "`t" + `
	$_.IMLatencyErrorThreshold + "`t" + `
	$_.IMLatencySpinnerDelay + "`t" + `
	$_.IMWarning + "`t" + `
	$_.MAPIPollInterval + "`t" + `
	$_.MaximumDGsAllowedInContactList + "`t" + `
	$_.MaximumNumberOfContacts + "`t" + `
	$_.MaxPhotoSizeKB + "`t" + `
	$_.MusicOnHoldAudioFile + "`t" + `
	$_.P2PAppSharingEncryption + "`t" + `
	$_.PlayAbbreviatedDialTone + "`t" + `
	[string]$_.PolicyEntry + "`t" + `
	$_.PublicationBatchDelay + "`t" + `
	$_.RateMyCallAllowCustomUserFeedback + "`t" + `
	$_.RateMyCallDisplayPercentage + "`t" + `
	$_.RequireContentPin + "`t" + `
	$_.SearchPrefixFlags + "`t" + `
	$_.ShowManagePrivacyRelationships + "`t" + `
	$_.ShowRecentContacts + "`t" + `
	$_.ShowSharepointPhotoEditLink + "`t" + `
	$_.SPSearchCenterExternalURL + "`t" + `
	$_.SPSearchCenterInternalURL + "`t" + `
	$_.SPSearchExternalURL + "`t" + `
	$_.SPSearchInternalURL + "`t" + `
	$_.SupportModernFilePicker + "`t" + `
	$_.TabURL + "`t" + `
	$_.TelemetryTier + "`t" + `
	$_.TracingLevel + "`t" + `
	$_.WebServicePollInterval
	$output_Skype_CsClientPolicy | Out-File -FilePath $Skype_CsClientPolicy_outputfile -append
}

$EventText = "Skype_CsClientPolicy " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n"

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
