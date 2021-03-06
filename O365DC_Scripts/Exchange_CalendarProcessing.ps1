#############################################################################
#                     Exchange_CalendarProcessing.ps1 						#
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
$ErrorText = "Exchange_CalendarProcessing " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
Try{$ErrorLog.WriteEntry($ErrorText,"Error", 100)}catch{}
}

set-location -LiteralPath $location
$output_location = $location + "\output\Exchange\GetCalendarProcessing"

if ((Test-Path -LiteralPath $output_location) -eq $false)
    {New-Item -Path $output_location -ItemType directory -Force}

@(Get-Content ".\CheckedMailbox.Set$i.txt") | ForEach-Object `
{
	$Exchange_CalendarProcessing_outputfile = $output_location + "\\Set$i~~GetCalendarProcessing.txt"
    $mailbox = $_
	@(Get-CalendarProcessing -identity $mailbox -ErrorAction continue) | ForEach-Object `
	{	
		$output_Exchange_CalendarProcessing = $mailbox + "`t" + `
			$_.identity + "`t" + `
			$_.MailboxOwnerId + "`t" + `
			$_.AutomateProcessing + "`t" + `
			$_.AllowConflicts + "`t" + `
			$_.BookingType + "`t" + `
			$_.BookingWindowInDays + "`t" + `
			$_.MaximumDurationInMinutes + "`t" + `
			$_.AllowRecurringMeetings + "`t" + `
			$_.ConflictPercentageAllowed + "`t" + `
			$_.MaximumConflictInstances + "`t" + `
			$_.ForwardRequestsToDelegates + "`t" + `
			$_.DeleteAttachments + "`t" + `
			$_.DeleteComments + "`t" + `
			$_.RemovePrivateProperty + "`t" + `
			$_.DeleteSubject + "`t" + `
			$_.DeleteNonCalendarItems + "`t" + `
			$_.TentativePendingApproval + "`t" + `
			$_.ResourceDelegates + "`t" + `
			$_.RequestOutOfPolicy + "`t" + `
			$_.AllRequestOutOfPolicy + "`t" + `
			$_.BookInPolicy + "`t" + `
			$_.AllBookInPolicy + "`t" + `
			$_.RequestInPolicy + "`t" + `
			$_.AllRequestInPolicy + "`t" + `
			$_.RemoveOldMeetingMessages + "`t" + `
			$_.AddNewRequestsTentatively + "`t" + `
			$_.ProcessExternalMeetingMessages + "`t" + `
			$_.RemoveForwardedMeetingNotifications + "`t" + `
			$_.IsValid 
		$output_Exchange_CalendarProcessing | out-file $Exchange_CalendarProcessing_outputfile -append 
	}
}

$EventText = "Exchange_CalendarProcessing " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n" 

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
Try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
