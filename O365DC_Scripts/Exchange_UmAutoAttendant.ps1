#############################################################################
#                     Exchange_UmAutoAttendant.ps1		 					#
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
$ErrorText = "Exchange_UmAutoAttendant " + "`n" + $server + "`n"
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

$Exchange_UmAutoAttendant_outputfile = $output_location + "\Exchange_UmAutoAttendant.txt"

@(Get-UmAutoAttendant) | ForEach-Object `
{
	$output_Exchange_UmAutoAttendant = $_.name + "`t" + `
		$_.identity + "`t" + `
		$_.SpeechEnabled + "`t" + `
		$_.AllowDialPlanSubscribers + "`t" + `
		$_.AllowExtensions + "`t" + `
		$_.AllowedInCountryOrRegionGroups + "`t" + `
		$_.AllowedInternationalGroups + "`t" + `
		$_.CallSomeoneEnabled + "`t" + `
		$_.ContactScope + "`t" + `
		$_.ContactAddressList + "`t" + `
		$_.SendVoiceMsgEnabled + "`t" + `
		$_.BusinessHourSchedule + "`t" + `
		$_.PilotIdentifierList + "`t" + `
		$_.UmDialPlan + "`t" + `
		$_.DtmfFallbackAutoAttendant + "`t" + `
		$_.HolidaySchedule + "`t" + `
		$_.TimeZone + "`t" + `
		$_.TimeZoneName + "`t" + `
		$_.MatchedNameSelectionMethod + "`t" + `
		$_.BusinessLocation + "`t" + `
		$_.WeekStartDay + "`t" + `
		$_.status + "`t" + `
		$_.Language + "`t" + `
		$_.OperatorExtension + "`t" + `
		$_.InfoAnnouncementFilename + "`t" + `
		$_.InfoAnnouncementEnabled + "`t" + `
		$_.NameLookupEnabled + "`t" + `
		$_.StarOutToDialPlanEnabled + "`t" + `
		$_.ForwardCallsToDefaultMailbox + "`t" + `
		$_.DefaultMailbox + "`t" + `
		$_.BusinessName + "`t" + `
		$_.BusinessHoursWelcomeGreetingFilename + "`t" + `
		$_.BusinessHoursWelcomeGreetingEnabled + "`t" + `
		$_.BusinessHoursMainMenuCustomPromptFilename + "`t" + `
		$_.BusinessHoursMainMenuCustomPromptEnabled + "`t" + `
		$_.BusinessHoursTransferToOperatorEnabled + "`t" + `
		$_.BusinessHoursKeyMapping + "`t" + `
		$_.BusinessHoursKeyMappingEnabled + "`t" + `
		$_.AfterHoursWelcomeGreetingFilename + "`t" + `
		$_.AfterHoursWelcomeGreetingEnabled + "`t" + `
		$_.AfterHoursMainMenuCustomPromptFilename + "`t" + `
		$_.AfterHoursMainMenuCustomPromptEnabled + "`t" + `
		$_.AfterHoursTransferToOperatorEnabled + "`t" + `
		$_.AfterHoursKeyMapping + "`t" + `
		$_.AfterHoursKeyMappingEnabled
	$output_Exchange_UmAutoAttendant | Out-File -FilePath $Exchange_UmAutoAttendant_outputfile -append 
}


$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n" 

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
