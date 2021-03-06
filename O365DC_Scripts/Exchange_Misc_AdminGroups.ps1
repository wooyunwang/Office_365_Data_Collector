 ############################################################################
#                     Exchange_Misc_AdminGroups.ps1							#
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
$ErrorText = "Exchange_Misc_AdminGroups " + "`n" + $server + "`n"
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

$Exchange_Misc_AdminGroups_outputfile = $output_location + "\Exchange_Misc_AdminGroups.txt"

$DefaultAdminGroups = @()
$O365SecurityGroups = @(`
	"O365 Support View Only",`
	"Security Administrator",`
	"Security Reader",`
	"TenantAdmins_*"`
	)
$Exchange2013SecurityGroups = @(`
	"Compliance Management"`
	)
$Exchange2010SecurityGroups = @(`
	"Discovery Management",`
	"Help Desk",`
	"Hygiene Management",`
	"Organization Management",`
	"Recipient Management",`
	"Records Management",`
	"UM Management",`
	"View-Only Organization Management"`
	)

$OtherSecurityGroups  = @()

$Groups = $DefaultAdminGroups + `
	$O365SecurityGroups + `
	$Exchange2013SecurityGroups + `
	$Exchange2010SecurityGroups + `
	$OtherSecurityGroups

$Groups = $Groups | Sort-Object -Unique

foreach ($group in $Groups)
{
	try
	{
		$Get_Group = Get-Group $Group
		$Get_Group_Count = $Get_Group.Members.count
		foreach ($member in $Get_group.members)
		{
			$Get_Group.Name + "`t" + $Get_Group_Count + "`t" + $member.tostring() | Out-File -FilePath $Exchange_Misc_AdminGroups_outputfile -append 
		}
		if ($Get_Group_Count -eq 0)
		{
			$Get_Group.Name + "`t" + $Get_Group_Count + "`t"  | Out-File -FilePath $Exchange_Misc_AdminGroups_outputfile -append 
		}
	}
	Catch{}
}

$EventText = "Exchange_Misc_AdminGroups " + "`n" + $server + "`n"
$RunTimeInSec = [int](((get-date) - $a).totalseconds)
$EventText += "Process run time`t`t" + $RunTimeInSec + " sec `n" 

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
try{$EventLog.WriteEntry($EventText,"Information", 35)}catch{}
