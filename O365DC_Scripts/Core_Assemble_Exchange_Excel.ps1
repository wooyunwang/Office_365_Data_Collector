#############################################################################
#                    Core_Assemble_Exchange_Excel.ps1		 				#
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
Param($RunLocation)

$ErrorActionPreference = "Stop"
Trap {
$ErrorText = "Core_Assemble_Exchange_Excel " + "`n" + $server + "`n"
$ErrorText += $_

$ErrorLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$ErrorLog.MachineName = "."
$ErrorLog.Source = "O365DC"
#$ErrorLog.WriteEntry($ErrorText,"Error", 100)
}

# Increase this value if adding new sheets
$SheetsInNewWorkbook = 48
function Convert-Datafile{
    param ([int]$NumberOfColumns, `
			[array]$DataFromFile, `
			$Wsheet, `
			[int]$ExcelVersion)
		$RowCount = $DataFromFile.Count
        $ArrayRow = 0
        $BadArrayValue = @()
        $DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$NumberOfColumns
		Foreach ($DataRow in $DataFromFile)
        {
            $DataField = $DataRow.Split("`t")
            for ($ArrayColumn = 0 ; $ArrayColumn -lt $NumberOfColumns ; $ArrayColumn++)
            {
                # Excel chokes if field starts with = so we'll try to prepend the ' to the string if it does
                Try{If ($DataField[$ArrayColumn].substring(0,1) -eq "=") {$DataField[$ArrayColumn] = "'"+$DataField[$ArrayColumn]}}
				Catch{}
                # Excel 2003 limit of 1823 characters
                if ($DataField[$ArrayColumn].length -lt 1823)
                    {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
                # Excel 2007 limit of 8203 characters
                elseif (($ExcelVersion -ge 12) -and ($DataField[$ArrayColumn].length -lt 8203))
                    {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
                # No known Excel 2010 limit
                elseif ($ExcelVersion -ge 14)
                    {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
                else
                {
                    Write-Host -Object "Number of characters in array member exceeds the version of limitations of this version of Excel" -ForegroundColor Yellow
                    Write-Host -Object "-- Writing value to temp variable" -ForegroundColor Yellow
                    $DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]
                    $BadArrayValue += "$ArrayRow,$ArrayColumn"
                }
            }
            $ArrayRow++
        }

        # Replace big values in $DataArray
        $BadArrayValue_count = $BadArrayValue.count
        $BadArrayValue_Temp = @()
        for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
        {
            $BadArray_Split = $badarrayvalue[$i].Split(",")
            $BadArrayValue_Temp += $DataArray[$BadArray_Split[0],$BadArray_Split[1]]
            $DataArray[$BadArray_Split[0],$BadArray_Split[1]] = "**TEMP**"
            Write-Host -Object "-- Replacing long value with **TEMP**" -ForegroundColor Yellow
        }

        $EndCellRow = ($RowCount+1)
        $Data_range = $Wsheet.Range("a2","$EndCellColumn$EndCellRow")
        $Data_range.Value2 = $DataArray

        # Paste big values back into the spreadsheet
        for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
        {
            $BadArray_Split = $badarrayvalue[$i].Split(",")
            # Adjust for header and $i=0
            $CellRow = [int]$BadArray_Split[0] + 2
            # Adjust for $i=0
            $CellColumn = [int]$BadArray_Split[1] + 1

            $Range = $Wsheet.cells.item($CellRow,$CellColumn)
            $Range.Value2 = $BadArrayValue_Temp[$i]
            Write-Host -Object "-- Pasting long value back in spreadsheet" -ForegroundColor Yellow
        }
    }

function Get-ColumnLetter{
	param([int]$HeaderCount)

	If ($headercount -ge 27)
	{
		$i = [int][math]::Floor($Headercount/26)
		$j = [int]($Headercount -($i*26))
		# This doesn't work on factors of 26
		# 52 become "b@" instead of "az"
		if ($j -eq 0)
		{
			$i--
			$j=26
		}
		$i_char = [char]($i+64)
		$j_char = [char]($j+64)
	}
	else
	{
		$j_char = [char]($headercount+64)
	}
	return [string]$i_char+[string]$j_char
}

set-location -LiteralPath $RunLocation

$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
$EventLog.MachineName = "."
$EventLog.Source = "O365DC"
#$EventLog.WriteEntry("Starting Core_Assemble_Exchange_Excel","Information", 42)

Write-Host -Object "---- Starting to create com object for Excel"
$Excel_Exchange = New-Object -ComObject excel.application
Write-Host -Object "---- Hiding Excel"
$Excel_Exchange.visible = $false
Write-Host -Object "---- Setting ShowStartupDialog to false"
$Excel_Exchange.ShowStartupDialog = $false
Write-Host -Object "---- Setting DefaultFilePath"
$Excel_Exchange.DefaultFilePath = $RunLocation + "\output"
Write-Host -Object "---- Setting SheetsInNewWorkbook"
$Excel_Exchange.SheetsInNewWorkbook = $SheetsInNewWorkbook
Write-Host -Object "---- Checking Excel version"
$Excel_Version = $Excel_Exchange.version
if ($Excel_version -ge 12)
{
	$Excel_Exchange.DefaultSaveFormat = 51
	$excel_Extension = ".xlsx"
}
else
{
	$Excel_Exchange.DefaultSaveFormat = 56
	$excel_Extension = ".xls"
}
Write-Host -Object "---- Excel version $Excel_version and DefaultSaveFormat $Excel_extension"

# Create new Excel workbook
Write-Host -Object "---- Adding workbook"
$Excel_Exchange_workbook = $Excel_Exchange.workbooks.add()
Write-Host -Object "---- Setting output file"
$O365DC_Exchange_XLS = $RunLocation + "\output\O365DC_Exchange" + $excel_Extension

Write-Host -Object "---- Setting workbook properties"
$Excel_Exchange_workbook.author = "Office 365 Data Collector v4 (O365DC v4)"
$Excel_Exchange_workbook.title = "O365DC v4 - Exchange Organization"
$Excel_Exchange_workbook.comments = "O365DC v4.0.2"

$intSheetCount = 1
$intColorIndex_ClientAccess = 45
$intColorIndex_Global = 11
$intColorIndex_Recipient = 45
$intColorIndex_Transport = 11
$intColorIndex_Um = 45
$intColorIndex_Misc = 11
$intColorIndex = 0

# Client Access
$intColorIndex = $intColorIndex_ClientAccess
#Region Get-ActiveSyncOrgSettings sheet
Write-Host -Object "---- Starting Get-ActiveSyncOrgSettings"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "ActiveSyncOrgSettings"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header += "Name"
	$header += "AdminDisplayName"
	$header += "AdminMailRecipients"
	$header += "AllowAccessForUnSupportedPlatform"
	$header += "AllowRMSSupportForUnenlightenedApps"
	$header += "DefaultAccessLevel"
	$header += "DeviceFiltering"
	$header += "DistinguishedName"
	$header += "EnableMobileMailboxPolicyWhenCAInplace"
	$header += "ExchangeVersion"
	$header += "Guid"
	$header += "HasAzurePremiumSubscription"
	$header += "Identity"
	$header += "IsIntuneManaged"
	$header += "IsValid"
	$header += "OrganizationId"
	$header += "OtaNotificationMailInsert"
	$header += "OtherWellKnownObjects"
	$header += "TenantAdminPreference"
	$header += "UserMailInsert"
	$header += "WhenChangedUTC"
	$header += "WhenCreatedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_ActiveSyncOrgSettings.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_ActiveSyncOrgSettings.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

	#EndRegion Get-ActiveSyncOrgSettings sheet

#Region Get-AvailabilityAddressSpace sheet
Write-Host -Object "---- Starting Get-AvailabilityAddressSpace"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AvailabilityAddressSpace"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "ForestName"
	$header +=  "UserName"
	$header +=  "UseServiceAccount"
	$header +=  "AccessMethod"
	$header +=  "ProxyUrl"
	$header +=  "TargetAutodiscoverEpr"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AvailabilityAddressSpace.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AvailabilityAddressSpace.txt")

	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-AvailabilityAddressSpace sheet

#Region Get-MobileDevice sheet
Write-Host -Object "---- Starting Get-MobileDevice"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MobileDevice"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "FriendlyName"
	$header +=  "DeviceMobileOperator"
	$header +=  "DeviceOS"
	$header +=  "DeviceTelephoneNumber"
	$header +=  "DeviceType"
	$header +=  "DeviceUserAgent"
	$header +=  "DeviceModel"
	$header +=  "FirstSyncTime"		# Column H
	$header +=  "UserDisplayName"
	$header +=  "DeviceAccessState"
	$header +=  "DeviceAccessStateReason"
	$header +=  "ClientVersion"
	$header +=  "Name"
	$header +=  "Identity"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_MobileDevice.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_MobileDevice.txt")

	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# FirstSyncTime
$Column_Range = $Worksheet.Range("H1","H$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"

	#EndRegion Get-MobileDevice sheet

#Region Get-MobileDeviceMailboxPolicy sheet
Write-Host -Object "---- Starting Get-MobileDeviceMailboxPolicy"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MobileDeviceMailboxPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "AllowNonProvisionableDevices"
	$header +=  "AlphanumericPasswordRequired"
	$header +=  "AttachmentsEnabled"
	$header +=  "DeviceEncryptionEnabled"
	$header +=  "RequireStorageCardEncryption"
	$header +=  "DevicePasswordEnabled"
	$header +=  "PasswordRecoveryEnabled"
	$header +=  "DevicePolicyRefreshInterval"
	$header +=  "AllowSimpleDevicePassword"
	$header +=  "MaxAttachmentSize"
	$header +=  "WSSAccessEnabled"
	$header +=  "UNCAccessEnabled"
	$header +=  "MinPasswordLength"
	$header +=  "MaxInactivityTimeLock"			# Column O
	$header +=  "MaxPasswordFailedAttempts"
	$header +=  "PasswordExpiration"
	$header +=  "PasswordHistory"
	$header +=  "IsDefault"
	$header +=  "AllowApplePushNotifications"
	$header +=  "AllowMicrosoftPushNotifications"
	$header +=  "AllowGooglePushNotifications"
	$header +=  "AllowStorageCard"
	$header +=  "AllowCamera"
	$header +=  "RequireDeviceEncryption"
	$header +=  "AllowUnsignedApplications"
	$header +=  "AllowUnsignedInstallationPackages"
	$header +=  "AllowWiFi"
	$header +=  "AllowTextMessaging"
	$header +=  "AllowPOPIMAPEmail"
	$header +=  "AllowIrDA"
	$header +=  "RequireManualSyncWhenRoaming"
	$header +=  "AllowDesktopSync"
	$header +=  "AllowHTMLEmail"
	$header +=  "RequireSignedSMIMEMessages"
	$header +=  "RequireEncryptedSMIMEMessages"
	$header +=  "AllowSMIMESoftCerts"
	$header +=  "AllowBrowser"
	$header +=  "AllowConsumerEmail"
	$header +=  "AllowRemoteDesktop"
	$header +=  "AllowInternetSharing"
	$header +=  "AllowBluetooth"
	$header +=  "MaxCalendarAgeFilter"
	$header +=  "MaxEmailAgeFilter"
	$header +=  "RequireSignedSMIMEAlgorithm"
	$header +=  "RequireEncryptionSMIMEAlgorithm"
	$header +=  "AllowSMIMEEncryptionAlgorithmNegotiation"
	$header +=  "MinPasswordComplexCharacters"
	$header +=  "MaxEmailBodyTruncationSize"
	$header +=  "MaxEmailHTMLBodyTruncationSize"
	$header +=  "UnapprovedInROMApplicationList"
	$header +=  "ApprovedApplicationList"
	$header +=  "AllowExternalDeviceManagement"
	$header +=  "MobileOTAUpdateMode"
	$header +=  "AllowMobileOTAUpdate"
	$header +=  "IrmEnabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_MobileDeviceMbxPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_MobileDeviceMbxPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# MaxinActivityTimeDeviceLock
$Column_Range = $Worksheet.Range("O1","O$EndRow")
$Column_Range.cells.NumberFormat = "hh:mm:ss"

	#EndRegion Get-MobileDeviceMailboxPolicy sheet

#Region Get-OwaMailboxPolicy sheet
Write-Host -Object "---- Starting Get-OwaMailboxPolicy"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "OwaMailboxPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "OneDriveAttachmentsEnabled"
	$header +=  "ThirdPartyFileProvidersEnabled"
	$header +=  "ClassicAttachmentsEnabled"
	$header +=  "ReferenceAttachmentsEnabled"
	$header +=  "SaveAttachmentsToCloudEnabled"
	$header +=  "InternalSPMySiteHostURL"
	$header +=  "ExternalSPMySiteHostURL"
	$header +=  "DirectFileAccessOnPublicComputersEnabled"
	$header +=  "DirectFileAccessOnPrivateComputersEnabled"
	$header +=  "WebReadyDocumentViewingOnPublicComputersEnabled"
	$header +=  "WebReadyDocumentViewingOnPrivateComputersEnabled"
	$header +=  "ForceWebReadyDocumentViewingFirstOnPublicComputers"
	$header +=  "ForceWebReadyDocumentViewingFirstOnPrivateComputers"
	$header +=  "WacViewingOnPublicComputersEnabled"
	$header +=  "WacViewingOnPrivateComputersEnabled"
	$header +=  "ForceWacViewingFirstOnPublicComputers"
	$header +=  "ForceWacViewingFirstOnPrivateComputers"
	$header +=  "ActionForUnknownFileAndMIMETypes"
	$header +=  "WebReadyDocumentViewingForAllSupportedTypes"
	$header +=  "PhoneticSupportEnabled"
	$header +=  "DefaultTheme"
	$header +=  "IsDefault"
	$header +=  "DefaultClientLanguage"
	$header +=  "LogonAndErrorLanguage"
	$header +=  "UseGB18030"
	$header +=  "UseISO885915"
	$header +=  "OutboundCharset"
	$header +=  "GlobalAddressListEnabled"
	$header +=  "OrganizationEnabled"
	$header +=  "ExplicitLogonEnabled"
	$header +=  "OWALightEnabled"
	$header +=  "DelegateAccessEnabled"
	$header +=  "IRMEnabled"
	$header +=  "CalendarEnabled"
	$header +=  "ContactsEnabled"
	$header +=  "TasksEnabled"
	$header +=  "JournalEnabled"
	$header +=  "NotesEnabled"
	$header +=  "OnSendAddinsEnabled"
	$header +=  "RemindersAndNotificationsEnabled"
	$header +=  "PremiumClientEnabled"
	$header +=  "SpellCheckerEnabled"
	$header +=  "SearchFoldersEnabled"
	$header +=  "SignaturesEnabled"
	$header +=  "ThemeSelectionEnabled"
	$header +=  "JunkEmailEnabled"
	$header +=  "UMIntegrationEnabled"
	$header +=  "WSSAccessOnPublicComputersEnabled"
	$header +=  "WSSAccessOnPrivateComputersEnabled"
	$header +=  "ChangePasswordEnabled"
	$header +=  "UNCAccessOnPublicComputersEnabled"
	$header +=  "UNCAccessOnPrivateComputersEnabled"
	$header +=  "ActiveSyncIntegrationEnabled"
	$header +=  "AllAddressListsEnabled"
	$header +=  "RulesEnabled"
	$header +=  "PublicFoldersEnabled"
	$header +=  "SMimeEnabled"
	$header +=  "RecoverDeletedItemsEnabled"
	$header +=  "InstantMessagingEnabled"
	$header +=  "TextMessagingEnabled"
	$header +=  "ForceSaveAttachmentFilteringEnabled"
	$header +=  "SilverlightEnabled"
	$header +=  "InstantMessagingType"
	$header +=  "DisplayPhotosEnabled"
	$header +=  "AllowOfflineOn"
	$header +=  "SetPhotoURL"
	$header +=  "PlacesEnabled"
	$header +=  "WeatherEnabled"
	$header +=  "LocalEventsEnabled"
	$header +=  "InterestingCalendarsEnabled"
	$header +=  "AllowCopyContactsToDeviceAddressBook"
	$header +=  "PredictedActionsEnabled"
	$header +=  "UserDiagnosticEnabled"
	$header +=  "FacebookEnabled"
	$header +=  "LinkedInEnabled"
	$header +=  "WacExternalServicesEnabled"
	$header +=  "WacOMEXEnabled"
	$header +=  "ReportJunkEmailEnabled"
	$header +=  "GroupCreationEnabled"
	$header +=  "SkipCreateUnifiedGroupCustomSharepointClassification"
	$header +=  "WebPartsFrameOptionsType"
	$header +=  "UserVoiceEnabled"
	$header +=  "SatisfactionEnabled"
	$header +=  "FreCardsEnabled"
	$header +=  "ConditionalAccessPolicy"
	$header +=  "OutlookBetaToggleEnabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1
if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_OwaMailboxPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_OwaMailboxPolicy.txt")

	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-ActiveSyncMailboxPolicy sheet

# Global
$intColorIndex = $intColorIndex_Global
#Region Get-AntiPhishPolicy sheet
Write-Host -Object "---- Starting Get-AntiPhishPolicy"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AntiPhishPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header += "Name"
	$header += "AntiSpoofEnforcementType"
	$header += "AuthenticationFailAction"
	$header += "EnableAntiSpoofEnforcement"
	$header += "EnableAuthenticationSafetyTip"
	$header += "EnableAuthenticationSoftPassSafetyTip"
	$header += "Guid"
	$header += "Identity"
	$header += "ImpersonationProtectionState"
	$header += "IsDefault"
	$header += "IsValid"
	$header += "OrganizationId"
	$header += "TreatSoftPassAsAuthenticated"
	$header += "WhenChangedUTC"
	$header += "WhenCreatedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AntiPhishPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AntiPhishPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

	#EndRegion Get-AntiPhishPolicy sheet

#Region Get-AntiSpoofingPolicy sheet
Write-Host -Object "---- Starting Get-AntiSpoofingPolicy"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AntiSpoofingPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header += "Name"
	$header += "Domain"
	$header += "Guid"
	$header += "Identity"
	$header += "IsValid"
	$header += "OrganizationId"
	$header += "ProtectMyDomain"
	$header += "WhenChangedUTC"
	$header += "WhenCreatedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AntiSpoofingPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AntiSpoofingPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

	#EndRegion Get-AntiSpoofingPolicy sheet

#Region Get-AddressBookPolicy sheet
Write-Host -Object "---- Starting Get-AddressBookPolicy"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AddressBookPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "AddressLists"
	$header +=  "GlobalAddressList"
	$header +=  "RoomList"
	$header +=  "OfflineAddressBook"
	$header +=  "IsDefault"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AddressBookPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AddressBookPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-AddressBookPolicy sheet

#Region Get-AddressList sheet
Write-Host -Object "---- Starting Get-AddressList"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AddressList"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "DisplayName"
	$header +=  "Path"
	$header +=  "RecipientFilter"
	$header +=  "WhenCreatedUTC"	# Column D
	$header +=  "WhenChangedUTC"	# Column E
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AddressList.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AddressList.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("D1","D$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("E1","E$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"

	#EndRegion Get-AddressList sheet

#Region Get-AtpPolicyForO365 sheet
Write-Host -Object "---- Starting Get-AtpPolicyForO365"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AtpPolicyForO365"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Recipient
	$row = 1
	$header = @()
	$header += "Name"
	$header += "AdminDisplayName"
	$header += "AllowClickThrough"
	$header += "BlockUrls"
	$header += "EnableATPForSPOTeamsODB"
	$header += "EnableSafeLinksForClients"
	$header += "EnableSafeLinksForO365Clients"
	$header += "EnableSafeLinksForWebAccessCompanion"
	$header += "ExchangeVersion"
	$header += "Guid"
	$header += "Identity"
	$header += "IsValid"
	$header += "OrganizationId"
	$header += "TrackClicks"
	$header += "WhenChangedUTC"
	$header += "WhenCreatedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AtpPolicyForO365.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AtpPolicyForO365.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

	#EndRegion Get-AtpPolicyForO365 sheet

#Region Get-EmailAddressPolicy sheet
Write-Host -Object "---- Starting Get-EmailAddressPolicy"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "EmailAddressPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "IsValid"
	$header +=  "RecipientFilter"
	$header +=  "LdapRecipientFilter"
	$header +=  "LastUpdatedRecipientFilter"
	$header +=  "RecipientFilterApplied"
	$header +=  "IncludedRecipients"
	$header +=  "ConditionalDepartment"
	$header +=  "ConditionalCompany"
	$header +=  "ConditionalStateOrProvince"
	$header +=  "ConditionalCustomAttribute1"
	$header +=  "ConditionalCustomAttribute2"
	$header +=  "ConditionalCustomAttribute3"
	$header +=  "ConditionalCustomAttribute4"
	$header +=  "ConditionalCustomAttribute5"
	$header +=  "ConditionalCustomAttribute6"
	$header +=  "ConditionalCustomAttribute7"
	$header +=  "ConditionalCustomAttribute8"
	$header +=  "ConditionalCustomAttribute9"
	$header +=  "ConditionalCustomAttribute10"
	$header +=  "ConditionalCustomAttribute11"
	$header +=  "ConditionalCustomAttribute12"
	$header +=  "ConditionalCustomAttribute13"
	$header +=  "ConditionalCustomAttribute14"
	$header +=  "ConditionalCustomAttribute15"
	$header +=  "RecipientContainer"
	$header +=  "RecipientFilterType"
	$header +=  "Priority"
	$header +=  "EnabledPrimarySMTPAddressTemplate"
	$header +=  "EnabledEmailAddressTemplates"
	$header +=  "DisabledEmailAddressTemplates"
	$header +=  "HasEmailAddressSetting"
	$header +=  "HasMailboxManagerSetting"
	$header +=  "NonAuthoritativeDomains"
	$header +=  "ExchangeVersion"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_EmailAddressPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_EmailAddressPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-EmailAddressPolicy sheet

#Region Get-GlobalAddressList sheet
Write-Host -Object "---- Starting Get-GlobalAddressList"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "GlobalAddressList"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "IsDefaultGlobalAddressList"
	$header +=  "RecipientFilter"
	$header +=  "LdapRecipientFilter"
	$header +=  "RecipientFilterApplied"
	$header +=  "IncludedRecipients"
	$header +=  "ConditionalDepartment"
	$header +=  "ConditionalCompany"
	$header +=  "ConditionalStateOrProvince"
	$header +=  "ConditionalCustomAttribute1"
	$header +=  "ConditionalCustomAttribute10"
	$header +=  "ConditionalCustomAttribute11"
	$header +=  "ConditionalCustomAttribute12"
	$header +=  "ConditionalCustomAttribute13"
	$header +=  "ConditionalCustomAttribute14"
	$header +=  "ConditionalCustomAttribute15"
	$header +=  "ConditionalCustomAttribute2"
	$header +=  "ConditionalCustomAttribute3"
	$header +=  "ConditionalCustomAttribute4"
	$header +=  "ConditionalCustomAttribute5"
	$header +=  "ConditionalCustomAttribute6"
	$header +=  "ConditionalCustomAttribute7"
	$header +=  "ConditionalCustomAttribute8"
	$header +=  "ConditionalCustomAttribute9"
	$header +=  "RecipientContainer"
	$header +=  "RecipientFilterType"
	$header +=  "Identity"
	$header +=  "WhenCreatedUTC"				# Column AB
	$header +=  "WhenChangedUTC"				# Column AC
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount

	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_GlobalAddressList.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_GlobalAddressList.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("AB1","AB$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("AC1","AC$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-GlobalAddressList sheet

#Region Get-OfflineAddressBook sheet
Write-Host -Object "---- Starting Get-OfflineAddressBook"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "OfflineAddressBook"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "Server"
	$header +=  "AddressLists"
	$header +=  "Versions"
	$header +=  "IsDefault"
	$header +=  "PublicFolderDatabase"
	$header +=  "PublicFolderDistributionEnabled"
	$header +=  "WebDistributionEnabled"
	$header +=  "VirtualDirectories"
	$header +=  "Schedule"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_OfflineAddressBook.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_OfflineAddressBook.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-OfflineAddressBook sheet

#Region Get-OnPremisesOrganization sheet
Write-Host -Object "---- Starting Get-OnPremisesOrganization"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "OnPremisesOrganization"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header += "AdminDisplayName"
	$header += "Comment"
	$header += "DistinguishedName"
	$header += "ExchangeVersion"
	$header += "Guid"
	$header += "HybridDomains"
	$header += "Identity"
	$header += "InboundConnector"
	$header += "IsValid"
	$header += "OrganizationGuid"
	$header += "OrganizationId"
	$header += "OrganizationName"
	$header += "OrganizationRelationship"
	$header += "OutboundConnector"
	$header += "WhenChangedUTC"
	$header += "WhenCreatedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_OnPremisesOrganization.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_OnPremisesOrganization.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-OnPremisesOrganization sheet

#Region Get-OrgConfig sheet
Write-Host -Object "---- Starting Get-OrgConfig"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "OrganizationConfig"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "DefaultPublicFolderAgeLimit"
	$header +=  "DefaultPublicFolderIssueWarningQuota"
	$header +=  "DefaultPublicFolderProhibitPostQuota"
	$header +=  "DefaultPublicFolderMaxItemSize"
	$header +=  "DefaultPublicFolderDeletedItemRetention"
	$header +=  "DefaultPublicFolderMovedItemRetention"
	$header +=  "PublicFoldersLockedForMigration"
	$header +=  "PublicFolderMigrationComplete"
	$header +=  "PublicFolderMailboxesLockedForNewConnections"
	$header +=  "PublicFolderMailboxesMigrationComplete"
	$header +=  "PublicFolderShowClientControl"
	$header +=  "PublicFoldersEnabled"
	$header +=  "ActivityBasedAuthenticationTimeoutInterval"
	$header +=  "ActivityBasedAuthenticationTimeoutEnabled"
	$header +=  "ActivityBasedAuthenticationTimeoutWithSingleSignOnEnabled"
	$header +=  "AppsForOfficeEnabled"
	$header +=  "AppsForOfficeCorpCatalogAppsCount"
	$header +=  "PrivateCatalogAppsCount"
	$header +=  "AVAuthenticationService"
	$header +=  "CustomerFeedbackEnabled"
	$header +=  "DistributionGroupDefaultOU"
	$header +=  "DistributionGroupNameBlockedWordsList"
	$header +=  "DistributionGroupNamingPolicy"
	$header +=  "EwsAllowEntourage"
	$header +=  "EwsAllowList"
	$header +=  "EwsAllowMacOutlook"
	$header +=  "EwsAllowOutlook"
	$header +=  "EwsApplicationAccessPolicy"
	$header +=  "EwsBlockList"
	$header +=  "EwsEnabled"
	$header +=  "IPListBlocked"
	$header +=  "ElcProcessingDisabled"
	$header +=  "AutoExpandingArchiveEnabled"
	$header +=  "ExchangeNotificationEnabled"
	$header +=  "ExchangeNotificationRecipients"
	$header +=  "HierarchicalAddressBookRoot"
	$header +=  "Industry"
	$header +=  "MailTipsAllTipsEnabled"
	$header +=  "MailTipsExternalRecipientsTipsEnabled"
	$header +=  "MailTipsGroupMetricsEnabled"
	$header +=  "MailTipsLargeAudienceThreshold"
	$header +=  "MailTipsMailboxSourcedTipsEnabled"
	$header +=  "ReadTrackingEnabled"
	$header +=  "SCLJunkThreshold"
	$header +=  "MaxConcurrentMigrations"
	$header +=  "IntuneManagedStatus"
	$header +=  "AzurePremiumSubscriptionStatus"
	$header +=  "HybridConfigurationStatus"
	$header +=  "ReleaseTrack"
	$header +=  "CompassEnabled"
	$header +=  "SharePointUrl"
	$header +=  "MapiHttpEnabled"
	$header +=  "RealTimeLogServiceEnabled"
	$header +=  "CustomerLockboxEnabled"
	$header +=  "UnblockUnsafeSenderPromptEnabled"
	$header +=  "IsMixedMode"
	$header +=  "ServicePlan"
	$header +=  "DefaultDataEncryptionPolicy"
	$header +=  "MailboxDataEncryptionEnabled"
	$header +=  "GuestsEnabled"
	$header +=  "GroupsCreationEnabled"
	$header +=  "GroupsNamingPolicy"
	$header +=  "OrganizationSummary"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_OrgConfig.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_OrgConfig.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-OrgConfig sheet

#Region Get-Rbac sheet
Write-Host -Object "---- Starting Get-Rbac"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "Rbac"
	$Worksheet.Tab.ColorIndex = $intColorIndex_Transport
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Members"
	$header +=  "Roles"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_Rbac.xml") -eq $true)
{
	$DataFile = Import-Clixml "$RunLocation\output\Exchange\Exchange_Rbac.xml"
	$RowCount = $DataFile.Count
	$ArrayRow = 0
	$BadArrayValue = @()
	$DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$ColumnCount

	Foreach ($DataRow in $DataFile)
	{
		for ($ArrayColumn = 0 ; $ArrayColumn -lt $ColumnCount ; $ArrayColumn++)
        {
            $DataField = $([string]$DataRow.($header[($ArrayColumn)]))

			# Excel 2003 limit of 1823 characters
            if ($DataField.length -lt 1823)
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
			# Excel 2007 limit of 8203 characters
            elseif (($Excel_Exchange.version -ge 12) -and ($DataField.length -lt 8203))
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
			# No known Excel 2010 limit
            elseif ($Excel_Exchange.version -ge 14)
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
            else
            {
                Write-Host -Object "Number of characters in array member exceeds the version of limitations of this version of Excel" -ForegroundColor Yellow
				Write-Host -Object "-- Writing value to temp variable" -ForegroundColor Yellow
                $DataArray[$ArrayRow,$ArrayColumn] = $DataField
                $BadArrayValue += "$ArrayRow,$ArrayColumn"
            }
        }
		$ArrayRow++
	}

    # Replace big values in $DataArray
    $BadArrayValue_count = $BadArrayValue.count
    $BadArrayValue_Temp = @()
    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
    {
        $BadArray_Split = $badarrayvalue[$i].Split(",")
        $BadArrayValue_Temp += $DataArray[$BadArray_Split[0],$BadArray_Split[1]]
        $DataArray[$BadArray_Split[0],$BadArray_Split[1]] = "**TEMP**"
		Write-Host -Object "-- Replacing long value with **TEMP**" -ForegroundColor Yellow
    }

	$EndCellRow = ($RowCount+1)
	$Data_range = $Worksheet.Range("a2","$EndCellColumn$EndCellRow")
	$Data_range.Value2 = $DataArray

    # Paste big values back into the spreadsheet
    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
    {
        $BadArray_Split = $badarrayvalue[$i].Split(",")
        # Adjust for header and $i=0
        $CellRow = [int]$BadArray_Split[0] + 2
        # Adjust for $i=0
        $CellColumn = [int]$BadArray_Split[1] + 1

        $Range = $Worksheet.cells.item($CellRow,$CellColumn)
        $Range.Value2 = $BadArrayValue_Temp[$i]
		Write-Host -Object "-- Pasting long value back in spreadsheet" -ForegroundColor Yellow
    }
}

	#EndRegion Get-Rbac sheet

#Region Get-RetentionPolicy sheet
Write-Host -Object "---- Starting Get-RetentionPolicy"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "RetentionPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "RetentionPolicyTagLinks"
	$header +=  "IsDefault"
	$header +=  "IsDefaultArbitrationMailbox"
	$header +=  "WhenCreatedUTC"
	$header +=  "WhenChangedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_RetentionPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_RetentionPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("C1","C$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("D1","D$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-RetentionPolicy sheet

#Region Get-RetentionPolicyTag sheet
Write-Host -Object "---- Starting Get-RetentionPolicyTag"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "RetentionPolicyTag"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "MessageClassDisplayName"
	$header +=  "MessageClass"
	$header +=  "Description"
	$header +=  "RetentionEnabled"
	$header +=  "RetentionAction"
	$header +=  "AgeLimitForRetention"
	$header +=  "MoveToDestinationFolder"
	$header +=  "TriggerForRetention"
	$header +=  "MessageFormatForJournaling"
	$header +=  "JournalingEnabled"
	$header +=  "AddressForJournaling"
	$header +=  "LabelForJournaling"
	$header +=  "Type"
	$header +=  "IsDefaultAutoGroupPolicyTag"
	$header +=  "IsDefaultModeratedRecipientsPolicyTag"
	$header +=  "SystemTag"
	$header +=  "Comment"
	$header +=  "WhenCreatedUTC"
	$header +=  "WhenChangedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_RetentionPolicyTag.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_RetentionPolicyTag.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# AgeLimitForRetention
$Column_Range = $Worksheet.Range("F1","F$EndRow")
$Column_Range.cells.NumberFormat = "dd:hh:mm:ss"
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("J1","J$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("K1","K$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-RetentionPolicyTag sheet

#Region Get-SmimeConfig sheet
Write-Host -Object "---- Starting Get-SmimeConfig"
$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
$Worksheet.name = "SmimeConfig"
$Worksheet.Tab.ColorIndex = $intColorIndex
$row = 1
$header = @()
$header += "Identity"
$header += "AdminDisplayName"
$header += "DistinguishedName"
$header += "ExchangeVersion"
$header += "Guid"
$header += "Id"
$header += "Name"
$header += "OrganizationId"
$header += "OWAAllowUserChoiceOfSigningCertificate"
$header += "OWAAlwaysEncrypt"
$header += "OWAAlwaysSign"
$header += "OWABCCEncryptedEmailForking"
$header += "OWACheckCRLOnSend"
$header += "OWAClearSign"
$header += "OWACopyRecipientHeaders"
$header += "OWACRLConnectionTimeout"
$header += "OWACRLRetrievalTimeout"
$header += "OWADisableCRLCheck"
$header += "OWADLExpansionTimeout"
$header += "OWAEncryptionAlgorithms"
$header += "OWAEncryptTemporaryBuffers"
$header += "OWAForceSMIMEClientUpgrade"
$header += "OWAIncludeCertificateChainAndRootCertificate"
$header += "OWAIncludeCertificateChainWithoutRootCertificate"
$header += "OWAIncludeSMIMECapabilitiesInMessage"
$header += "OWAOnlyUseSmartCard"
$header += "OWASenderCertificateAttributesToDisplay"
$header += "OWASignedEmailCertificateInclusion"
$header += "OWASigningAlgorithms"
$header += "OWATripleWrapSignedEncryptedMail"
$header += "OWAUseKeyIdentifier"
$header += "OWAUseSecondaryProxiesWhenFindingCertificates"
$header += "SMIMECertificateIssuingCA"
$header += "SMIMECertificatesExpiryDate"
$header += "SMIMEExpiredCertificateThumbprint"
$header += "WhenChangedUTC"
$header += "WhenCreatedUTC"
$HeaderCount = $header.count
$EndCellColumn = Get-ColumnLetter $HeaderCount
$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
$Header_range.value2 = $header
$Header_range.cells.interior.colorindex = 45
$Header_range.cells.font.colorindex = 0
$Header_range.cells.font.bold = $true
$row++
$intSheetCount++
$ColumnCount = $header.Count
$DataFile = @()
$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_SmimeConfig.txt") -eq $true)
{
$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_SmimeConfig.txt")
# Send the data to the function to process and add to the Excel worksheet
Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
#EndRegion Get-SmimeConfig sheet

# Receipient
$intColorIndex = $intColorIndex_Recipient
#Region Get-CalendarProcessing sheet
Write-Host -Object "---- Starting Get-CalendarProcessing"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "CalendarProcessing"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Mailbox"
	$header +=  "Identity"
	$header +=  "MailboxOwnerId"
	$header +=  "AutomateProcessing"
	$header +=  "AllowConflicts"
	$header +=  "BookingType"
	$header +=  "BookingWindowInDays"
	$header +=  "MaximumDurationInMinutes"
	$header +=  "AllowRecurringMeetings"
	$header +=  "ConflictPercentageAllowed"
	$header +=  "MaximumConflictInstances"
	$header +=  "ForwardRequestsToDelegates"
	$header +=  "DeleteAttachments"
	$header +=  "DeleteComments"
	$header +=  "RemovePrivateProperty"
	$header +=  "DeleteSubject"
	$header +=  "DeleteNonCalendarItems"
	$header +=  "TentativePendingApproval"
	$header +=  "ResourceDelegates"
	$header +=  "RequestOutOfPolicy"
	$header +=  "AllRequestOutOfPolicy"
	$header +=  "BookInPolicy"
	$header +=  "AllBookInPolicy"
	$header +=  "RequestInPolicy"
	$header +=  "AllRequestInPolicy"
	$header +=  "RemoveOldMeetingMessages"
	$header +=  "AddNewRequestsTentatively"
	$header +=  "ProcessExternalMeetingMessages"
	$header +=  "RemoveForwardedMeetingNotifications"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetCalendarProcessing") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetCalendarProcessing" | Where-Object {$_.name -match "~~GetCalendarProcessing"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetCalendarProcessing\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-CalendarProcessing sheet

#Region Get-CASMailbox sheet
Write-Host -Object "---- Starting Get-CASMailbox"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "CASMailbox"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "ServerName"
	$header +=  "ActiveSyncMailboxPolicy"
	$header +=  "ActiveSyncEnabled"
	$header +=  "HasActiveSyncDevicePartnership"
	$header +=  "OwaMailboxPolicy"
	$header +=  "OWAEnabled"
	$header +=  "ECPEnabled"
	$header +=  "PopEnabled"
	$header +=  "ImapEnabled"
	$header +=  "MAPIEnabled"
	$header +=  "MAPIBlockOutlookNonCachedMode"
	$header +=  "MAPIBlockOutlookVersions"
	$header +=  "MAPIBlockOutlookRpcHttp"
	$header +=  "EwsEnabled"
	$header +=  "EwsAllowOutlook"
	$header +=  "EwsAllowMacOutlook"
	$header +=  "EwsAllowEntourage"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetCASMailbox") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetCASMailbox" | Where-Object {$_.name -match "~~GetCASMailbox"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetCASMailbox\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-CASMailbox sheet

#Region Get-CasMailboxPlan sheet
Write-Host -Object "---- Starting Get-CasMailboxPlan"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "CasMailboxPlan"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "DisplayName"
	$header += "ActiveSyncDebugLogging"
	$header += "ActiveSyncEnabled"
	$header += "ActiveSyncMailboxPolicy"
	$header += "ActiveSyncSuppressReadReceipt"
	$header += "ECPEnabled"
	$header += "EwsAllowEntourage"
	$header += "EwsAllowList"
	$header += "EwsAllowMacOutlook"
	$header += "EwsAllowOutlook"
	$header += "EwsApplicationAccessPolicy"
	$header += "EwsBlockList"
	$header += "EwsEnabled"
	$header += "Guid"
	$header += "Identity"
	$header += "ImapEnabled"
	$header += "ImapEnableExactRFC822Size"
	$header += "ImapForceICalForCalendarRetrievalOption"
	$header += "ImapMessagesRetrievalMimeFormat"
	$header += "ImapProtocolLoggingEnabled"
	$header += "ImapSuppressReadReceipt"
	$header += "ImapUseProtocolDefaults"
	$header += "IsValid"
	$header += "MAPIBlockOutlookExternalConnectivity"
	$header += "MAPIBlockOutlookNonCachedMode"
	$header += "MAPIBlockOutlookRpcHttp"
	$header += "MAPIBlockOutlookVersions"
	$header += "MAPIEnabled"
	$header += "MapiHttpEnabled"
	$header += "Name"
	$header += "OrganizationId"
	$header += "OWAEnabled"
	$header += "OWAforDevicesEnabled"
	$header += "OwaMailboxPolicy"
	$header += "PopEnabled"
	$header += "PopEnableExactRFC822Size"
	$header += "PopForceICalForCalendarRetrievalOption"
	$header += "PopMessageDeleteEnabled"
	$header += "PopMessagesRetrievalMimeFormat"
	$header += "PopProtocolLoggingEnabled"
	$header += "PopSuppressReadReceipt"
	$header += "PopUseProtocolDefaults"
	$header += "PublicFolderClientAccess"
	$header += "RemotePowerShellEnabled"
	$header += "WhenChangedUTC"
	$header += "WhenCreatedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_CasMailboxPlan.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_CasMailboxPlan.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

	#EndRegion Get-CasMailboxPlan sheet

#Region Get-Contact sheet
Write-Host -Object "---- Starting Get-Contact"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "Contact"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header += "DisplayName"
	$header += "AdministrativeUnits"
	$header += "AllowUMCallsFromNonUsers"
	$header += "AssistantName"
	$header += "City"
	$header += "Company"
	$header += "CountryOrRegion"
	$header += "Department"
	$header += "DirectReports"
	$header += "Fax"
	$header += "FirstName"
	$header += "GeoCoordinates"
	$header += "Guid"
	$header += "HomePhone"
	$header += "Identity"
	$header += "Initials"
	$header += "IsDirSynced"
	$header += "IsValid"
	$header += "LastName"
	$header += "Manager"
	$header += "MobilePhone"
	$header += "Name"
	$header += "Notes"
	$header += "Office"
	$header += "OrganizationId"
	$header += "OtherFax"
	$header += "OtherHomePhone"
	$header += "OtherTelephone"
	$header += "Pager"
	$header += "Phone"
	$header += "PhoneticDisplayName"
	$header += "PostalCode"
	$header += "PostOfficeBox"
	$header += "RecipientType"
	$header += "RecipientTypeDetails"
	$header += "SeniorityIndex"
	$header += "SimpleDisplayName"
	$header += "StateOrProvince"
	$header += "StreetAddress"
	$header += "TelephoneAssistant"
	$header += "Title"
	$header += "UMCallingLineIds"
	$header += "UMDialPlan"
	$header += "UMDtmfMap"
	$header += "VoiceMailSettings"
	$header += "WebPage"
	$header += "WhenChangedUTC"
	$header += "WhenCreatedUTC"
	$header += "WindowsEmailAddress"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_Contact.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_Contact.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

	#EndRegion Get-Contact sheet

#Region Get-DistributionGroup sheet
Write-Host -Object "---- Starting Get-DistributionGroup"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "DistributionGroup"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Member Count"
	$header +=  "GroupType"
	$header +=  "IsDirSynced"
	$header +=  "ManagedBy"
	$header +=  "MemberJoinRestriction"
	$header +=  "MemberDepartRestriction"
	$header +=  "MigrationToUnifiedGroupInProgress"
	$header +=  "ExpansionServer"
	$header +=  "ReportToManagerEnabled"
	$header +=  "ReportToOriginatorEnabled"
	$header +=  "SendOofMessageToOriginatorEnabled"
	$header +=  "AcceptMessagesOnlyFrom"
	$header +=  "AcceptMessagesOnlyFromDLMembers"
	$header +=  "AcceptMessagesOnlyFromSendersOrMembers"
	$header +=  "Alias"
	$header +=  "OrganizationalUnit"
	$header +=  "CustomAttribute1"
	$header +=  "CustomAttribute10"
	$header +=  "CustomAttribute11"
	$header +=  "CustomAttribute12"
	$header +=  "CustomAttribute13"
	$header +=  "CustomAttribute14"
	$header +=  "CustomAttribute15"
	$header +=  "CustomAttribute2"
	$header +=  "CustomAttribute3"
	$header +=  "CustomAttribute4"
	$header +=  "CustomAttribute5"
	$header +=  "CustomAttribute6"
	$header +=  "CustomAttribute7"
	$header +=  "CustomAttribute8"
	$header +=  "CustomAttribute9"
	$header +=  "ExtensionCustomAttribute1"
	$header +=  "ExtensionCustomAttribute2"
	$header +=  "ExtensionCustomAttribute3"
	$header +=  "ExtensionCustomAttribute4"
	$header +=  "ExtensionCustomAttribute5"
	$header +=  "DisplayName"
	$header +=  "GrantSendOnBehalfTo"
	$header +=  "HiddenFromAddressListsEnabled"
	$header +=  "MaxSendSize"
	$header +=  "MaxReceiveSize"
	$header +=  "ModeratedBy"
	$header +=  "ModerationEnabled"
	$header +=  "RejectMessagesFrom"
	$header +=  "RejectMessagesFromDLMembers"
	$header +=  "RejectMessagesFromSendersOrMembers"
	$header +=  "RequireSenderAuthenticationEnabled"
	$header +=  "PrimarySmtpAddress"
	$header +=  "RecipientType"
	$header +=  "RecipientTypeDetails"
	$header +=  "WhenCreatedUTC"
	$header +=  "WhenChangedUTC"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_DistributionGroup.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_DistributionGroup.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("AC1","AC$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("AD1","AD$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-DistributionGroup sheet

#Region Get-DynamicDistributionGroup sheet
Write-Host -Object "---- Starting Get-DynamicDistributionGroup"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "DynamicDistributionGroup"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "RecipientContainer"
	$header +=  "RecipientFilter"
	$header +=  "LdapRecipientFilter"
	$header +=  "IncludedRecipients"
	$header +=  "ManagedBy"
	$header +=  "ExpansionServer"
	$header +=  "ReportToManagerEnabled"
	$header +=  "ReportToOriginatorEnabled"
	$header +=  "SendOofMessageToOriginatorEnabled"
	$header +=  "AcceptMessagesOnlyFrom"
	$header +=  "AcceptMessagesOnlyFromDLMembers"
	$header +=  "AcceptMessagesOnlyFromSendersOrMembers"
	$header +=  "Alias"
	$header +=  "OrganizationalUnit"
	$header +=  "CustomAttribute1"
	$header +=  "CustomAttribute10"
	$header +=  "CustomAttribute11"
	$header +=  "CustomAttribute12"
	$header +=  "CustomAttribute13"
	$header +=  "CustomAttribute14"
	$header +=  "CustomAttribute15"
	$header +=  "CustomAttribute2"
	$header +=  "CustomAttribute3"
	$header +=  "CustomAttribute4"
	$header +=  "CustomAttribute5"
	$header +=  "CustomAttribute6"
	$header +=  "CustomAttribute7"
	$header +=  "CustomAttribute8"
	$header +=  "CustomAttribute9"
	$header +=  "ExtensionCustomAttribute1"
	$header +=  "ExtensionCustomAttribute2"
	$header +=  "ExtensionCustomAttribute3"
	$header +=  "ExtensionCustomAttribute4"
	$header +=  "ExtensionCustomAttribute5"
	$header +=  "DisplayName"
	$header +=  "GrantSendOnBehalfTo"
	$header +=  "HiddenFromAddressListsEnabled"
	$header +=  "MaxSendSize"
	$header +=  "MaxReceiveSize"
	$header +=  "ModeratedBy"
	$header +=  "ModerationEnabled"
	$header +=  "PrimarySmtpAddress"
	$header +=  "RecipientType"
	$header +=  "RecipientTypeDetails"
	$header +=  "RejectMessagesFrom"
	$header +=  "RejectMessagesFromDLMembers"
	$header +=  "RejectMessagesFromSendersOrMembers"
	$header +=  "RequireSenderAuthenticationEnabled"
	$header +=  "WhenCreatedUTC"
	$header +=  "WhenChangedUTC"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_DynamicDistributionGroup.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_DynamicDistributionGroup.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-DynamicDistributionGroup sheet

#Region Get-Mailbox sheet
Write-Host -Object "---- Starting Get-Mailbox"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "Mailbox"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Mailbox"
	$header +=  "Identity"
	$header +=  "Database"
	$header +=  "UseDatabaseRetentionDefaults"
	$header +=  "RetainDeletedItemsUntilBackup"
	$header +=  "DeliverToMailboxAndForward"
	$header +=  "LitigationHoldEnabled"
	$header +=  "SingleItemRecoveryEnabled"
	$header +=  "RetentionHoldEnabled"
	$header +=  "EndDateForRetentionHold"
	$header +=  "StartDateForRetentionHold"
	$header +=  "RetentionComment"
	$header +=  "RetentionUrl"
	$header +=  "LitigationHoldDate"
	$header +=  "LitigationHoldOwner"
	$header +=  "ElcProcessingDisabled"
	$header +=  "ComplianceTagHoldApplied"
	$header +=  "LitigationHoldDuration"
	$header +=  "ManagedFolderMailboxPolicy"
	$header +=  "RetentionPolicy"
	$header +=  "AddressBookPolicy"
	$header +=  "CalendarRepairDisabled"
	$header +=  "ForwardingAddress"
	$header +=  "ForwardingSmtpAddress"
	$header +=  "RetainDeletedItemsFor"
	$header +=  "IsMailboxEnabled"
	$header +=  "ProhibitSendQuota"
	$header +=  "ProhibitSendReceiveQuota"
	$header +=  "RecoverableItemsQuota"
	$header +=  "RecoverableItemsWarningQuota"
	$header +=  "CalendarLoggingQuota"
	$header +=  "IsResource"
	$header +=  "IsLinked"
	$header +=  "IsShared"
	$header +=  "IsRootPublicFolderMailbox"
	$header +=  "RoomMailboxAccountEnabled"
	$header +=  "SCLDeleteThreshold"
	$header +=  "SCLDeleteEnabled"
	$header +=  "SCLRejectThreshold"
	$header +=  "SCLRejectEnabled"
	$header +=  "SCLQuarantineThreshold"
	$header +=  "SCLQuarantineEnabled"
	$header +=  "SCLJunkThreshold"
	$header +=  "SCLJunkEnabled"
	$header +=  "AntispamBypassEnabled"
	$header +=  "ServerName"
	$header +=  "UseDatabaseQuotaDefaults"
	$header +=  "IssueWarningQuota"
	$header +=  "RulesQuota"
	$header +=  "Office"
	$header +=  "UserPrincipalName"
	$header +=  "UMEnabled"
	$header +=  "WindowsLiveID"
	$header +=  "MicrosoftOnlineServicesID"
	$header +=  "RoleAssignmentPolicy"
	$header +=  "DefaultPublicFolderMailbox"
	$header +=  "EffectivePublicFolderMailbox"
	$header +=  "SharingPolicy"
	$header +=  "RemoteAccountPolicy"
	$header +=  "MailboxPlan"
	$header +=  "ArchiveDatabase"
	$header +=  "ArchiveName"
	$header +=  "ArchiveQuota"
	$header +=  "ArchiveWarningQuota"
	$header +=  "ArchiveDomain"
	$header +=  "ArchiveStatus"
	$header +=  "ArchiveState"
	$header +=  "AutoExpandingArchiveEnabled"
	$header +=  "DisabledMailboxLocations"
	$header +=  "RemoteRecipientType"
	$header +=  "UserSMimeCertificate"
	$header +=  "UserCertificate"
	$header +=  "CalendarVersionStoreDisabled"
	$header +=  "SKUAssigned"
	$header +=  "AuditEnabled"
	$header +=  "AuditLogAgeLimit"
	$header +=  "UsageLocation"
	$header +=  "AccountDisabled"
	$header +=  "NonCompliantDevices"
	$header +=  "DataEncryptionPolicy"
	$header +=  "HasPicture"
	$header +=  "HasSpokenName"
	$header +=  "IsDirSynced"
	$header +=  "AcceptMessagesOnlyFrom"
	$header +=  "AcceptMessagesOnlyFromDLMembers"
	$header +=  "AcceptMessagesOnlyFromSendersOrMembers"
	$header +=  "Alias"
	$header +=  "CustomAttribute1"
	$header +=  "CustomAttribute10"
	$header +=  "CustomAttribute11"
	$header +=  "CustomAttribute12"
	$header +=  "CustomAttribute13"
	$header +=  "CustomAttribute14"
	$header +=  "CustomAttribute15"
	$header +=  "CustomAttribute2"
	$header +=  "CustomAttribute3"
	$header +=  "CustomAttribute4"
	$header +=  "CustomAttribute5"
	$header +=  "CustomAttribute6"
	$header +=  "CustomAttribute7"
	$header +=  "CustomAttribute8"
	$header +=  "CustomAttribute9"
	$header +=  "ExtensionCustomAttribute1"
	$header +=  "ExtensionCustomAttribute2"
	$header +=  "ExtensionCustomAttribute3"
	$header +=  "ExtensionCustomAttribute4"
	$header +=  "ExtensionCustomAttribute5"
	$header +=  "DisplayName"
	$header +=  "EmailAddresses"
	$header +=  "GrantSendOnBehalfTo"
	$header +=  "HiddenFromAddressListsEnabled"
	$header +=  "MaxSendSize"
	$header +=  "MaxReceiveSize"
	$header +=  "ModeratedBy"
	$header +=  "ModerationEnabled"
	$header +=  "EmailAddressPolicyEnabled"
	$header +=  "PrimarySmtpAddress"
	$header +=  "RecipientType"
	$header +=  "RecipientTypeDetails"
	$header +=  "RejectMessagesFrom"
	$header +=  "RejectMessagesFromDLMembers"
	$header +=  "RejectMessagesFromSendersOrMembers"
	$header +=  "RequireSenderAuthenticationEnabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetMbx") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetMbx" | Where-Object {$_.name -match "~~GetMbx"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetMbx\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-Mailbox sheet

#Region Get-MailboxFolderStatistics sheet
Write-Host -Object "---- Starting Get-MailboxFolderStatistics"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MailboxFolderStatistics"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Mailbox"
	$header +=  "Name"
	$header +=  "FolderType"
	$header +=  "Identity"
	$header +=  "ItemsInFolder"
	$header +=  "FolderSize"
	$header +=  "FolderSize (MB)"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = [int]$header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetMbxFolderStatistics") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetMbxFolderStatistics" | Where-Object {$_.name -match "~~GetMbxFolderStatistics"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetMbxFolderStatistics\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-MailboxFolderStatistics sheet

#Region Get-MailboxPermission sheet
Write-Host -Object "---- Starting Get-MailboxPermission"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MailboxPermission"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Mailbox"
	$header +=  "Identity"
	$header +=  "RecipientTypeDetails"
	$header +=  "User (ACL'ed on Mbx)"
	$header +=  "AccessRights"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetMbxPermission") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetMbxPermission" | Where-Object {$_.name -match "~~GetMbxPerm"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetMbxPermission\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-MailboxPermission sheet

#Region Get-MailboxPlan sheet
Write-Host -Object "---- Starting Get-MailboxPlan"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MailboxPlan"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "DisplayName"
	$header += "AccountDisabled"
	$header += "AddressBookPolicy"
	$header += "AddressListMembership"
	$header += "AdministrativeUnits"
	$header += "AggregatedMailboxGuids"
	$header += "Alias"
	$header += "AntispamBypassEnabled"
	$header += "ArchiveDatabase"
	$header += "ArchiveDomain"
	$header += "ArchiveGuid"
	$header += "ArchiveName"
	$header += "ArchiveQuota"
	$header += "ArchiveRelease"
	$header += "ArchiveState"
	$header += "ArchiveStatus"
	$header += "ArchiveWarningQuota"
	$header += "AuditEnabled"
	$header += "AuditLogAgeLimit"
	$header += "AutoExpandingArchiveEnabled"
	$header += "CalendarLoggingQuota"
	$header += "CalendarRepairDisabled"
	$header += "CalendarVersionStoreDisabled"
	$header += "ComplianceTagHoldApplied"
	$header += "CustomAttribute1"
	$header += "Database"
	$header += "DataEncryptionPolicy"
	$header += "DefaultPublicFolderMailbox"
	$header += "DelayHoldApplied"
	$header += "DeliverToMailboxAndForward"
	$header += "DisabledArchiveDatabase"
	$header += "DisabledArchiveGuid"
	$header += "DisabledMailboxLocations"
	$header += "DowngradeHighPriorityMessagesEnabled"
	$header += "EffectivePublicFolderMailbox"
	$header += "ElcProcessingDisabled"
	$header += "EmailAddressPolicyEnabled"
	$header += "EndDateForRetentionHold"
	$header += "ExchangeGuid"
	$header += "ExchangeUserAccountControl"
	$header += "ExchangeVersion"
	$header += "Extensions"
	$header += "ExternalOofOptions"
	$header += "GeneratedOfflineAddressBooks"
	$header += "Guid"
	$header += "HasPicture"
	$header += "HasSnackyAppData"
	$header += "HasSpokenName"
	$header += "HiddenFromAddressListsEnabled"
	$header += "Identity"
	$header += "ImListMigrationCompleted"
	$header += "InactiveMailboxRetireTime"
	$header += "IncludeInGarbageCollection"
	$header += "InPlaceHolds"
	$header += "IsDefault"
	$header += "IsDefaultForPreviousVersion"
	$header += "IsDirSynced"
	$header += "IsExcludedFromServingHierarchy"
	$header += "IsHierarchyReady"
	$header += "IsHierarchySyncEnabled"
	$header += "IsMachineToPersonTextMessagingEnabled"
	$header += "IsPersonToPersonTextMessagingEnabled"
	$header += "IsPilotMailboxPlan"
	$header += "IsSoftDeletedByDisable"
	$header += "IsSoftDeletedByRemove"
	$header += "IssueWarningQuota"
	$header += "IsValid"
	$header += "JournalArchiveAddress"
	$header += "LitigationHoldDate"
	$header += "LitigationHoldDuration"
	$header += "LitigationHoldEnabled"
	$header += "LitigationHoldOwner"
	$header += "MailboxContainerGuid"
	$header += "MailboxLocations"
	$header += "MailboxMoveBatchName"
	$header += "MailboxMoveFlags"
	$header += "MailboxMoveRemoteHostName"
	$header += "MailboxMoveSourceMDB"
	$header += "MailboxMoveStatus"
	$header += "MailboxMoveTargetMDB"
	$header += "MailboxPlan"
	$header += "MailboxPlanRelease"
	$header += "MailboxProvisioningConstraint"
	$header += "MailboxProvisioningPreferences"
	$header += "MailboxRegion"
	$header += "MailboxRegionLastUpdateTime"
	$header += "MailboxRelease"
	$header += "ManagedFolderMailboxPolicy"
	$header += "MaxBlockedSenders"
	$header += "MaxReceiveSize"
	$header += "MaxSafeSenders"
	$header += "MaxSendSize"
	$header += "MessageCopyForSendOnBehalfEnabled"
	$header += "MessageCopyForSentAsEnabled"
	$header += "MessageRecallProcessingEnabled"
	$header += "MessageTrackingReadStatusEnabled"
	$header += "ModeratedBy"
	$header += "Name"
	$header += "NetID"
	$header += "NonCompliantDevices"
	$header += "ObjectState"
	$header += "OfflineAddressBook"
	$header += "OrganizationId"
	$header += "OriginatingServer"
	$header += "OrphanSoftDeleteTrackingTime"
	$header += "PersistedCapabilities"
	$header += "PoliciesExcluded"
	$header += "PoliciesIncluded"
	$header += "ProhibitSendQuota"
	$header += "ProhibitSendReceiveQuota"
	$header += "ProtocolSettings"
	$header += "QueryBaseDN"
	$header += "QueryBaseDNRestrictionEnabled"
	$header += "RecipientLimits"
	$header += "RecipientType"
	$header += "RecipientTypeDetails"
	$header += "ReconciliationId"
	$header += "RecoverableItemsQuota"
	$header += "RecoverableItemsWarningQuota"
	$header += "RemoteAccountPolicy"
	$header += "RemoteRecipientType"
	$header += "RequireSenderAuthenticationEnabled"
	$header += "ResetPasswordOnNextLogon"
	$header += "ResourceType"
	$header += "RetainDeletedItemsFor"
	$header += "RetainDeletedItemsUntilBackup"
	$header += "RetentionComment"
	$header += "RetentionHoldEnabled"
	$header += "RetentionPolicy"
	$header += "RetentionUrl"
	$header += "RoleAssignmentPolicy"
	$header += "RoomMailboxAccountEnabled"
	$header += "RulesQuota"
	$header += "SCLDeleteEnabled"
	$header += "SCLDeleteThreshold"
	$header += "SCLJunkEnabled"
	$header += "SCLJunkThreshold"
	$header += "SCLQuarantineEnabled"
	$header += "SCLQuarantineThreshold"
	$header += "SCLRejectEnabled"
	$header += "SCLRejectThreshold"
	$header += "SharingPolicy"
	$header += "SiloName"
	$header += "SingleItemRecoveryEnabled"
	$header += "StartDateForRetentionHold"
	$header += "StsRefreshTokensValidFrom"
	$header += "ThrottlingPolicy"
	$header += "UMEnabled"
	$header += "UnifiedMailbox"
	$header += "UseDatabaseQuotaDefaults"
	$header += "UseDatabaseRetentionDefaults"
	$header += "UserCertificate"
	$header += "UserPrincipalName"
	$header += "UserSMimeCertificate"
	$header += "WhenChangedUTC"
	$header += "WhenCreatedUTC"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_MailboxPlan.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_MailboxPlan.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

	#EndRegion Get-MailboxPlan sheet

#Region Get-MailboxStatistics sheet
Write-Host -Object "---- Starting Get-MailboxStatistics"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MailboxStatistics"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Mailbox"
	$header +=  "DisplayName"
	$header +=  "ServerName"
	$header +=  "Database"
	$header +=  "ItemCount"
	$header +=  "TotalItemSize"
	$header +=  "TotalItemSize (MB)"
	$header +=  "TotalDeletedItemSize"
	$header +=  "TotalDeletedItemSize (MB)"
	$header +=  "IsEncrypted"
	$header +=  "MailboxType"
	$header +=  "MailboxTypeDetail"
	$header +=  "IsArchiveMailbox"
	$header +=  "FastIsEnabled"
	$header +=  "BigFunnelIsEnabled"
	$header +=  "DatabaseIssueWarningQuota"
	$header +=  "DatabaseProhibitSendQuota"
	$header +=  "DatabaseProhibitSendReceiveQuota"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetMbxStatistics") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetMbxStatistics" | Where-Object {$_.name -match "~~GetMbxStatistics"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetMbxStatistics\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-MailboxStatistics sheet

#Region Get-MailUser sheet
Write-Host -Object "---- Starting Get-MailUser"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "MailUser"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header += "DisplayName"
	$header += "AcceptMessagesOnlyFrom"
	$header += "AcceptMessagesOnlyFromDLMembers"
	$header += "AcceptMessagesOnlyFromSendersOrMembers"
	$header += "AccountDisabled"
	$header += "AddressListMembership"
	$header += "AdministrativeUnits"
	$header += "AggregatedMailboxGuids"
	$header += "Alias"
	$header += "ArbitrationMailbox"
	$header += "ArchiveDatabase"
	$header += "ArchiveGuid"
	$header += "ArchiveName"
	$header += "ArchiveQuota"
	$header += "ArchiveRelease"
	$header += "ArchiveStatus"
	$header += "ArchiveWarningQuota"
	$header += "BypassModerationFromSendersOrMembers"
	$header += "CalendarVersionStoreDisabled"
	$header += "ComplianceTagHoldApplied"
	$header += "CustomAttribute1"
	$header += "CustomAttribute10"
	$header += "CustomAttribute11"
	$header += "CustomAttribute12"
	$header += "CustomAttribute13"
	$header += "CustomAttribute14"
	$header += "CustomAttribute15"
	$header += "CustomAttribute2"
	$header += "CustomAttribute3"
	$header += "CustomAttribute4"
	$header += "CustomAttribute5"
	$header += "CustomAttribute6"
	$header += "CustomAttribute7"
	$header += "CustomAttribute8"
	$header += "CustomAttribute9"
	$header += "DataEncryptionPolicy"
	$header += "DelayHoldApplied"
	$header += "DeliverToMailboxAndForward"
	$header += "DisabledArchiveDatabase"
	$header += "DisabledArchiveGuid"
	$header += "EmailAddresses"
	$header += "EmailAddressPolicyEnabled"
	$header += "EndDateForRetentionHold"
	$header += "ExchangeGuid"
	$header += "ExchangeUserAccountControl"
	$header += "ExchangeVersion"
	$header += "ExtensionCustomAttribute1"
	$header += "ExtensionCustomAttribute2"
	$header += "ExtensionCustomAttribute3"
	$header += "ExtensionCustomAttribute4"
	$header += "ExtensionCustomAttribute5"
	$header += "Extensions"
	$header += "ExternalDirectoryObjectId"
	$header += "ExternalEmailAddress"
	$header += "ForwardingAddress"
	$header += "GrantSendOnBehalfTo"
	$header += "GuestInfo"
	$header += "Guid"
	$header += "HasPicture"
	$header += "HasSpokenName"
	$header += "HiddenFromAddressListsEnabled"
	$header += "Identity"
	$header += "ImmutableId"
	$header += "InPlaceHolds"
	$header += "IsDirSynced"
	$header += "IsSoftDeletedByDisable"
	$header += "IsSoftDeletedByRemove"
	$header += "IssueWarningQuota"
	$header += "IsValid"
	$header += "JournalArchiveAddress"
	$header += "LastExchangeChangedTime"
	$header += "LegacyExchangeDN"
	$header += "LitigationHoldDate"
	$header += "LitigationHoldEnabled"
	$header += "LitigationHoldOwner"
	$header += "MacAttachmentFormat"
	$header += "MailboxContainerGuid"
	$header += "MailboxLocations"
	$header += "MailboxMoveBatchName"
	$header += "MailboxMoveFlags"
	$header += "MailboxMoveRemoteHostName"
	$header += "MailboxMoveSourceMDB"
	$header += "MailboxMoveStatus"
	$header += "MailboxMoveTargetMDB"
	$header += "MailboxProvisioningConstraint"
	$header += "MailboxProvisioningPreferences"
	$header += "MailboxRegion"
	$header += "MailboxRegionLastUpdateTime"
	$header += "MailboxRelease"
	$header += "MailTip"
	$header += "MailTipTranslations"
	$header += "MaxReceiveSize"
	$header += "MaxSendSize"
	$header += "MessageBodyFormat"
	$header += "MessageFormat"
	$header += "MicrosoftOnlineServicesID"
	$header += "ModeratedBy"
	$header += "ModerationEnabled"
	$header += "Name"
	$header += "OrganizationId"
	$header += "OtherMail"
	$header += "PersistedCapabilities"
	$header += "PoliciesExcluded"
	$header += "PoliciesIncluded"
	$header += "PrimarySmtpAddress"
	$header += "ProhibitSendQuota"
	$header += "ProhibitSendReceiveQuota"
	$header += "ProtocolSettings"
	$header += "RecipientLimits"
	$header += "RecipientType"
	$header += "RecipientTypeDetails"
	$header += "RecoverableItemsQuota"
	$header += "RecoverableItemsWarningQuota"
	$header += "RejectMessagesFrom"
	$header += "RejectMessagesFromDLMembers"
	$header += "RejectMessagesFromSendersOrMembers"
	$header += "RequireSenderAuthenticationEnabled"
	$header += "ResetPasswordOnNextLogon"
	$header += "RetainDeletedItemsFor"
	$header += "RetentionComment"
	$header += "RetentionHoldEnabled"
	$header += "RetentionUrl"
	$header += "SamAccountName"
	$header += "SendModerationNotifications"
	$header += "SimpleDisplayName"
	$header += "SingleItemRecoveryEnabled"
	$header += "SKUAssigned"
	$header += "StartDateForRetentionHold"
	$header += "StsRefreshTokensValidFrom"
	$header += "UMDtmfMap"
	$header += "UsageLocation"
	$header += "UseMapiRichTextFormat"
	$header += "UsePreferMessageFormat"
	$header += "UserCertificate"
	$header += "UserPrincipalName"
	$header += "UserSMimeCertificate"
	$header += "WhenChangedUTC"
	$header += "WhenCreatedUTC"
	$header += "WhenMailboxCreated"
	$header += "WhenSoftDeleted"
	$header += "WindowsEmailAddress"
	$header += "WindowsLiveID"	
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_MailUser.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_MailUser.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

	#EndRegion Get-MailUser sheet

#Region Get-PublicFolder sheet
Write-Host -Object "---- Starting Get-PublicFolder"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "PublicFolder"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "ParentPath"
	$header +=  "AgeLimit"
	$header +=  "HasSubFolders"
	$header +=  "MailEnabled"
	$header +=  "MaxItemSize"
	$header +=  "ContentMailboxName"
	$header +=  "ContentMailboxGuid"
	$header +=  "PerUserReadStateEnabled"
	$header +=  "RetainDeletedItemsFor"
	$header +=  "ProhibitPostQuota"
	$header +=  "IssueWarningQuota"
	$header +=  "FolderSize"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_PublicFolder.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_PublicFolder.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-PublicFolder sheet

#Region Get-PublicFolderStatistics sheet
Write-Host -Object "---- Starting Get-PublicFolderStatistics"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "PublicFolderStatistics"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "FolderPath"
	$header +=  "ItemCount"
	$header +=  "TotalItemSize"
	$header +=  "TotalItemSize (MB)"
	$header +=  "CreationTime"				# Column G
	$header +=  "LastModificationTime"		# Column H
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

	if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_PublicFolderStats.txt") -eq $true)
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_PublicFolderStats.txt")
		# Send the data to the function to process and add to the Excel worksheet
		Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
	}

# Format time/date columns
$EndRow = $DataFile.count + 1
# CreationTime
$Column_Range = $Worksheet.Range("G1","G$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# LastModificationTime
$Column_Range = $Worksheet.Range("H1","H$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-PublicFolderStatistics sheet

#Region Get-UnifiedGroup sheet
Write-Host -Object "---- Starting Get-UnifiedGroup"
$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
$Worksheet.name = "UnifiedGroup"
$Worksheet.Tab.ColorIndex = $intColorIndex
$row = 1
$header = @()
$header += "DisplayName"
$header += "AcceptMessagesOnlyFrom"
$header += "AcceptMessagesOnlyFromDLMembers"
$header += "AcceptMessagesOnlyFromSendersOrMembers"
$header += "AccessType"
$header += "AddressListMembership"
$header += "AdministrativeUnits"
$header += "Alias"
$header += "AllowAddGuests"
$header += "AlwaysSubscribeMembersToCalendarEvents"
$header += "AutoSubscribeNewMembers"
$header += "BypassModerationFromSendersOrMembers"
$header += "CalendarMemberReadOnly"
$header += "CalendarUrl"
$header += "Classification"
$header += "ConnectorsEnabled"
$header += "CustomAttribute1"
$header += "CustomAttribute10"
$header += "CustomAttribute11"
$header += "CustomAttribute12"
$header += "CustomAttribute13"
$header += "CustomAttribute14"
$header += "CustomAttribute15"
$header += "CustomAttribute2"
$header += "CustomAttribute3"
$header += "CustomAttribute4"
$header += "CustomAttribute5"
$header += "CustomAttribute6"
$header += "CustomAttribute7"
$header += "CustomAttribute8"
$header += "CustomAttribute9"
$header += "DataEncryptionPolicy"
$header += "EmailAddresses"
$header += "EmailAddressPolicyEnabled"
$header += "ExchangeGuid"
$header += "ExchangeVersion"
$header += "ExpansionServer"
$header += "ExpirationTime"
$header += "ExtensionCustomAttribute1"
$header += "ExtensionCustomAttribute2"
$header += "ExtensionCustomAttribute3"
$header += "ExtensionCustomAttribute4"
$header += "ExtensionCustomAttribute5"
$header += "ExternalDirectoryObjectId"
$header += "FileNotificationsSettings"
$header += "GrantSendOnBehalfTo"
$header += "GroupExternalMemberCount"
$header += "GroupMemberCount"
$header += "GroupPersonification"
$header += "GroupSKU"
$header += "GroupType"
$header += "Guid"
$header += "HiddenFromAddressListsEnabled"
$header += "HiddenFromExchangeClientsEnabled"
$header += "HiddenGroupMembershipEnabled"
$header += "Identity"
$header += "InboxUrl"
$header += "IsDirSynced"
$header += "IsExternalResourcesPublished"
$header += "IsMailboxConfigured"
$header += "IsMembershipDynamic"
$header += "IsValid"
$header += "Language"
$header += "LastExchangeChangedTime"
$header += "MailboxProvisioningConstraint"
$header += "MailboxRegion"
$header += "MailTip"
$header += "MailTipTranslations"
$header += "ManagedBy"
$header += "ManagedByDetails"
$header += "MaxReceiveSize"
$header += "MaxSendSize"
$header += "MigrationToUnifiedGroupInProgress"
$header += "ModeratedBy"
$header += "ModerationEnabled"
$header += "Name"
$header += "Notes"
$header += "OrganizationId"
$header += "PeopleUrl"
$header += "PhotoUrl"
$header += "PoliciesExcluded"
$header += "PoliciesIncluded"
$header += "PrimarySmtpAddress"
$header += "ProvisioningOption"
$header += "RecipientType"
$header += "RecipientTypeDetails"
$header += "RejectMessagesFrom"
$header += "RejectMessagesFromDLMembers"
$header += "RejectMessagesFromSendersOrMembers"
$header += "ReportToManagerEnabled"
$header += "ReportToOriginatorEnabled"
$header += "RequireSenderAuthenticationEnabled"
$header += "SendModerationNotifications"
$header += "SendOofMessageToOriginatorEnabled"
$header += "SharePointDocumentsUrl"
$header += "SharePointNotebookUrl"
$header += "SharePointSiteUrl"
$header += "SubscriptionEnabled"
$header += "WelcomeMessageEnabled"
$header += "WhenChangedUTC"
$header += "WhenCreatedUTC"
$header += "WhenSoftDeleted"
$header += "YammerEmailAddress"
$HeaderCount = $header.count
$EndCellColumn = Get-ColumnLetter $HeaderCount
$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
$Header_range.value2 = $header
$Header_range.cells.interior.colorindex = 45
$Header_range.cells.font.colorindex = 0
$Header_range.cells.font.bold = $true
$row++
$intSheetCount++
$ColumnCount = $header.Count
$DataFile = @()
$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_UnifiedGroup.txt") -eq $true)
{
$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_UnifiedGroup.txt")
# Send the data to the function to process and add to the Excel worksheet
Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
#EndRegion Get-UnifiedGroup sheet

#Region Quota sheet
Write-Host -Object "---- Starting Quota"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "Quota"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "ServerName"
	$header +=  "Alias"
	$header +=  "UseDatabaseQuotaDefaults"
	$header +=  "IssueWarningQuota"
	$header +=  "ProhibitSendQuota"
	$header +=  "ProhibitSendReceiveQuota"
	$header +=  "RecoverableItemsQuota"
	$header +=  "RecoverableItemsWarningQuota"
	$header +=  "LitigationHoldEnabled"
	$header +=  "RetentionHoldEnabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Quota") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\Quota" | Where-Object {$_.name -match "~~Quota"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Quota\" + $file)
	}
	$RowCount = $DataFile.Count
	# Not using the Convert-Datafile function because Quota needs special data handling for formatting
	$ArrayRow = 0
	$DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$ColumnCount
	Foreach ($DataRow in $DataFile)
	{
		$DataField = $DataRow.Split("`t")
		for ($ArrayColumn=0;$ArrayColumn -le 2;$ArrayColumn++)
		{
            # Excel chokes if field starts with = so we'll prepend the ' to the string if it does
            If ($DataField[$ArrayColumn].substring(0,1) -eq "=") {$DataField[$ArrayColumn] = "'"+$DataField[$ArrayColumn]}

			$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]
		}
		if ($DataField[2] -eq "TRUE")
		{
			$DataArray[$ArrayRow,3] =  "- - -"
			$DataArray[$ArrayRow,4] =  "- - -"
			$DataArray[$ArrayRow,5] =  "- - -"
		}
		else
		{
			$DataArray[$ArrayRow,3] =  $DataField[3]
			$DataArray[$ArrayRow,4] =  $DataField[4]
			$DataArray[$ArrayRow,5] =  $DataField[5]
		}
		for ($ArrayColumn=6;$ArrayColumn -le $ColumnCount-1;$ArrayColumn++)
		{
			$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]
		}
		#write-host $ArrayRow " of " $RowCount

		$ArrayRow++
	}

	$EndCellRow = ($RowCount+1)
	$Data_range = $Worksheet.Range("a2","$EndCellColumn$EndCellRow")
	$Data_range.Value2 = $DataArray
}
	#EndRegion Quota sheet

# Transport
$intColorIndex = $intColorIndex_Transport
#Region Get-AcceptedDomain sheet
Write-Host -Object "---- Starting Get-AcceptedDomain"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "AcceptedDomain"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "DomainName"
	$header +=  "CatchAllRecipientID"
	$header +=  "DomainType"
	$header +=  "MatchSubDomains"
	$header +=  "AddressBookEnabled"
	$header +=  "Default"
	$header +=  "EmailOnly"
	$header +=  "ExternallyManaged"
	$header +=  "AuthenticationType"
	$header +=  "LiveIdInstanceType"
	$header +=  "PendingRemoval"
	$header +=  "PendingCompletion"
	$header +=  "FederatedOrganizationLink"
	$header +=  "MailFlowPartner"
	$header +=  "OutboundOnly"
	$header +=  "PendingFederatedAccountNamespace"
	$header +=  "PendingFederatedDomain"
	$header +=  "IsCoexistenceDomain"
	$header +=  "PerimeterDuplicateDetected"
	$header +=  "IsDefaultFederatedDomain"
	$header +=  "EnableNego2Authentication"
	$header +=  "InitialDomain"
	$header +=  "Name"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_AcceptedDomain.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_AcceptedDomain.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#endRegion Get-AcceptedDomain sheet

#Region Get-DkimSigningConfig sheet
Write-Host -Object "---- Starting Get-DkimSigningConfig"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "DkimSigningConfig"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header += "Name"
	$header += "AdminDisplayName"
	$header += "Algorithm"
	$header += "BodyCanonicalization"
	$header += "Domain"
	$header += "Enabled"
	$header += "Guid"
	$header += "HeaderCanonicalization"
	$header += "Identity"
	$header += "IncludeKeyExpiration"
	$header += "IncludeSignatureCreationTime"
	$header += "IsDefault"
	$header += "IsValid"
	$header += "KeyCreationTime"
	$header += "LastChecked"
	$header += "NumberOfBytesToSign"
	$header += "OrganizationId"
	$header += "RotateOnDate"
	$header += "Selector1CNAME"
	$header += "Selector1KeySize"
	$header += "Selector1PublicKey"
	$header += "Selector2CNAME"
	$header += "Selector2KeySize"
	$header += "Selector2PublicKey"
	$header += "SelectorAfterRotateOnDate"
	$header += "SelectorBeforeRotateOnDate"
	$header += "Status"
	$header += "WhenChangedUTC"
	$header += "WhenCreatedUTC"
	
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_DkimSigningConfig.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_DkimSigningConfig.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-DkimSigningConfig sheet

#Region Get-InboundConnector sheet
Write-Host -Object "---- Starting Get-InboundConnector"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "InboundConnector"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Enabled"
	$header +=  "ConnectorType"
	$header +=  "ConnectorSource"
	$header +=  "Comment"
	$header +=  "SenderIPAddresses"
	$header +=  "SenderDomains"
	$header +=  "AssociatedAcceptedDomains"
	$header +=  "RequireTls"
	$header +=  "RemoteIPRanges"
	$header +=  "RestrictDomainsToIPAddresses"
	$header +=  "RestrictDomainsToCertificate"
	$header +=  "CloudServicesMailEnabled"
	$header +=  "TreatMessagesAsInternal"
	$header +=  "TlsSenderCertificateName"
	$header +=  "DetectSenderIPBySkippingLastIP"
	$header +=  "DetectSenderIPBySkippingTheseIPs"
	$header +=  "DetectSenderIPRecipientList"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_InboundConnector.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_InboundConnector.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-InboundConnector sheet

#Region Get-OutboundConnector sheet
Write-Host -Object "---- Starting Get-OutboundConnector"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "OutboundConnector"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Enabled"
	$header +=  "UseMXRecord"
	$header +=  "Comment"
	$header +=  "ConnectorType"
	$header +=  "ConnectorSource"
	$header +=  "RecipientDomains"
	$header +=  "SmartHosts"
	$header +=  "TlsDomain"
	$header +=  "TlsSettings"
	$header +=  "IsTransportRuleScoped"
	$header +=  "RouteAllMessagesViaOnPremises"
	$header +=  "CloudServicesMailEnabled"
	$header +=  "AllAcceptedDomains"
	$header +=  "IsValidated"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_OutboundConnector.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_OutboundConnector.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

#EndRegion Get-OutboundConnector sheet

#Region Get-RemoteDomain sheet
Write-Host -Object "---- Starting Get-RemoteDomain"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "RemoteDomain"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Identity"
	$header +=  "DomainName"
	$header +=  "IsInternal"
	$header +=  "TargetDeliveryDomain"
	$header +=  "CharacterSet"
	$header +=  "NonMimeCharacterSet"
	$header +=  "AllowedOOFType"
	$header +=  "AutoReplyEnabled"
	$header +=  "AutoForwardEnabled"
	$header +=  "DeliveryReportEnabled"
	$header +=  "NDREnabled"
	$header +=  "MeetingForwardNotificationEnabled"
	$header +=  "ContentType"
	$header +=  "DisplaySenderName"
	$header +=  "TNEFEnabled"
	$header +=  "LineWrapSize"
	$header +=  "TrustedMailOutboundEnabled"
	$header +=  "TrustedMailInboundEnabled"
	$header +=  "UseSimpleDisplayName"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_RemoteDomain.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_RemoteDomain.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-RemoteDomain sheet

#Region Get-TransportConfig sheet
Write-Host -Object "---- Starting Get-TransportConfig"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "TransportConfig"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header += "Transport Config"
	$header += "AddressBookPolicyRoutingEnabled"
	$header += "AnonymousSenderToRecipientRatePerHour"
	$header += "ClearCategories"
	$header += "ConvertDisclaimerWrapperToEml"
	$header += "DSNConversionMode"
	$header += "ExternalDelayDsnEnabled"
	$header += "ExternalDsnDefaultLanguage"
	$header += "ExternalDsnLanguageDetectionEnabled"
	$header += "ExternalDsnMaxMessageAttachSize"
	$header += "ExternalDsnReportingAuthority"
	$header += "ExternalDsnSendHtml"
	$header += "ExternalPostmasterAddress"
	$header += "GenerateCopyOfDSNFor"
	$header += "HeaderPromotionModeSetting"
	$header += "HygieneSuite"
	$header += "InternalDelayDsnEnabled"
	$header += "InternalDsnDefaultLanguage"
	$header += "InternalDsnLanguageDetectionEnabled"
	$header += "InternalDsnMaxMessageAttachSize"
	$header += "InternalDsnReportingAuthority"
	$header += "InternalDsnSendHtml"
	$header += "InternalSMTPServers"
	$header += "JournalArchivingEnabled"
	$header += "JournalingReportNdrTo"
	$header += "LegacyArchiveJournalingEnabled"
	$header += "LegacyArchiveLiveJournalingEnabled"
	$header += "LegacyJournalingMigrationEnabled"
	$header += "MaxDumpsterSizePerDatabase"
	$header += "MaxDumpsterTime"
	$header += "MaxReceiveSize"
	$header += "MaxRecipientEnvelopeLimit"
	$header += "MaxRetriesForLocalSiteShadow"
	$header += "MaxRetriesForRemoteSiteShadow"
	$header += "MaxSendSize"
	$header += "MigrationEnabled"
	$header += "OpenDomainRoutingEnabled"
	$header += "RedirectDLMessagesForLegacyArchiveJournaling"
	$header += "RedirectUnprovisionedUserMessagesForLegacyArchiveJournaling"
	$header += "RejectMessageOnShadowFailure"
	$header += "Rfc2231EncodingEnabled"
	$header += "SafetyNetHoldTime"
	$header += "ShadowHeartbeatFrequency"
	$header += "ShadowMessageAutoDiscardInterval"
	$header += "ShadowMessagePreferenceSetting"
	$header += "ShadowRedundancyEnabled"
	$header += "ShadowResubmitTimeSpan"
	$header += "SmtpClientAuthenticationDisabled"
	$header += "SupervisionTags"
	$header += "TLSReceiveDomainSecureList"
	$header += "TLSSendDomainSecureList"
	$header += "VerifySecureSubmitEnabled"
	$header += "VoicemailJournalingEnabled"
	$header += "Xexch50Enabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_TransportConfig.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_TransportConfig.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# ShadowHeartbeatTimeoutInterval
$Column_Range = $Worksheet.Range("AO1","AO$EndRow")
$Column_Range.cells.NumberFormat = "hh:mm:ss"
# ShadowMessageAutoDiscardInterval
$Column_Range = $Worksheet.Range("AP1","AP$EndRow")
$Column_Range.cells.NumberFormat = "dd:hh:mm:ss"
# WhenCreatedUTC
$Column_Range = $Worksheet.Range("AW1","AW$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
# WhenChangedUTC
$Column_Range = $Worksheet.Range("AX1","AX$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"
	#EndRegion Get-TransportConfig sheet

#Region Get-TransportRule sheet
Write-Host -Object "---- Starting Get-TransportRule"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "TransportRule"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Identity"
	$header +=  "Priority"
	$header +=  "Comments"
	$header +=  "Description"
	$header +=  "RuleVersion"
	$header +=  "State"
	$header +=  "WhenChanged"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_TransportRule.xml") -eq $true)
{
	$DataFile = Import-Clixml "$RunLocation\output\Exchange\Exchange_TransportRule.xml"
	$RowCount = $DataFile.Count
	$ArrayRow = 0
	$BadArrayValue = @()
	$DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$ColumnCount

	Foreach ($DataRow in $DataFile)
	{
		for ($ArrayColumn = 0 ; $ArrayColumn -lt $ColumnCount ; $ArrayColumn++)
        {
            $DataField = $([string]$DataRow.($header[($ArrayColumn)]))

			# Excel 2003 limit of 1823 characters
            if ($DataField.length -lt 1823)
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
			# Excel 2007 limit of 8203 characters
            elseif (($Excel_Exchange.version -ge 12) -and ($DataField.length -lt 8203))
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
			# No known Excel 2010 limit
            elseif ($Excel_Exchange.version -ge 14)
                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField}
            else
            {
                Write-Host -Object "Number of characters in array member exceeds the version of limitations of this version of Excel" -ForegroundColor Yellow
				Write-Host -Object "-- Writing value to temp variable" -ForegroundColor Yellow
                $DataArray[$ArrayRow,$ArrayColumn] = $DataField
                $BadArrayValue += "$ArrayRow,$ArrayColumn"
            }
        }
		$ArrayRow++
	}

    # Replace big values in $DataArray
    $BadArrayValue_count = $BadArrayValue.count
    $BadArrayValue_Temp = @()
    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
    {
        $BadArray_Split = $badarrayvalue[$i].Split(",")
        $BadArrayValue_Temp += $DataArray[$BadArray_Split[0],$BadArray_Split[1]]
        $DataArray[$BadArray_Split[0],$BadArray_Split[1]] = "**TEMP**"
		Write-Host -Object "-- Replacing long value with **TEMP**" -ForegroundColor Yellow
    }

	$EndCellRow = ($RowCount+1)
	$Data_range = $Worksheet.Range("a2","$EndCellColumn$EndCellRow")
	$Data_range.Value2 = $DataArray

    # Paste big values back into the spreadsheet
    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
    {
        $BadArray_Split = $badarrayvalue[$i].Split(",")
        # Adjust for header and $i=0
        $CellRow = [int]$BadArray_Split[0] + 2
        # Adjust for $i=0
        $CellColumn = [int]$BadArray_Split[1] + 1

        $Range = $Worksheet.cells.item($CellRow,$CellColumn)
        $Range.Value2 = $BadArrayValue_Temp[$i]
		Write-Host -Object "-- Pasting long value back in spreadsheet" -ForegroundColor Yellow
    }
}

# Format time/date columns
$EndRow = $DataFile.count + 1
# WhenChangedUTC
$Column_Range = $Worksheet.Range("G1","G$EndRow")
$Column_Range.cells.NumberFormat = "mm/dd/yy hh:mm:ss"

	#EndRegion Get-TransportRule sheet

# Um
$intColorIndex = $intColorIndex_Um
#Region Get-UmAutoAttendant sheet
Write-Host -Object "---- Starting Get-UmAutoAttendant"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "UmAutoAttendant"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "SpeechEnabled"
	$header +=  "AllowDialPlanSubscribers"
	$header +=  "AllowExtensions"
	$header +=  "AllowedInCountryOrRegionGroups"
	$header +=  "AllowedInternationalGroups"
	$header +=  "CallSomeoneEnabled"
	$header +=  "ContactScope"
	$header +=  "ContactAddressList"
	$header +=  "SendVoiceMsgEnabled"
	$header +=  "BusinessHourSchedule"
	$header +=  "PilotIdentifierList"
	$header +=  "UmDialPlan"
	$header +=  "DtmfFallbackAutoAttendant"
	$header +=  "HolidaySchedule"
	$header +=  "TimeZone"
	$header +=  "TimeZoneName"
	$header +=  "MatchedNameSelectionMethod"
	$header +=  "BusinessLocation"
	$header +=  "WeekStartDay"
	$header +=  "Status"
	$header +=  "Language"
	$header +=  "OperatorExtension"
	$header +=  "InfoAnnouncementFilename"
	$header +=  "InfoAnnouncementEnabled"
	$header +=  "NameLookupEnabled"
	$header +=  "StarOutToDialPlanEnabled"
	$header +=  "ForwardCallsToDefaultMailbox"
	$header +=  "DefaultMailbox"
	$header +=  "BusinessName"
	$header +=  "BusinessHoursWelcomeGreetingFilename"
	$header +=  "BusinessHoursWelcomeGreetingEnabled"
	$header +=  "BusinessHoursMainMenuCustomPromptFilename"
	$header +=  "BusinessHoursMainMenuCustomPromptEnabled"
	$header +=  "BusinessHoursTransferToOperatorEnabled"
	$header +=  "BusinessHoursKeyMapping"
	$header +=  "BusinessHoursKeyMappingEnabled"
	$header +=  "AfterHoursWelcomeGreetingFilename"
	$header +=  "AfterHoursWelcomeGreetingEnabled"
	$header +=  "AfterHoursMainMenuCustomPromptFilename"
	$header +=  "AfterHoursMainMenuCustomPromptEnabled"
	$header +=  "AfterHoursTransferToOperatorEnabled"
	$header +=  "AfterHoursKeyMapping"
	$header +=  "AfterHoursKeyMappingEnabled"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_UmAutoAttendant.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_UmAutoAttendant.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-UmAutoAttendant sheet

#Region Get-UmDialPlan sheet
Write-Host -Object "---- Starting Get-UmDialPlan"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "UmDialPlan"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "NumberOfDigitsInExtension"
	$header +=  "LogonFailuresBeforeDisconnect"
	$header +=  "AccessTelephoneNumbers"
	$header +=  "FaxEnabled"
	$header +=  "InputFailuresBeforeDisconnect"
	$header +=  "OutsideLineAccessCode"
	$header +=  "DialByNamePrimary"
	$header +=  "DialByNameSecondary"
	$header +=  "AudioCodec"
	$header +=  "AvailableLanguages"
	$header +=  "DefaultLanguage"
	$header +=  "VoIPSecurity"
	$header +=  "MaxCallDuration"
	$header +=  "MaxRecordingDuration"
	$header +=  "RecordingIdleTimeout"
	$header +=  "PilotIdentifierList"
	$header +=  "UMServers"
	$header +=  "UMMailboxPolicies"
	$header +=  "UMAutoAttendants"
	$header +=  "WelcomeGreetingEnabled"
	$header +=  "AutomaticSpeechRecognitionEnabled"
	$header +=  "PhoneContext"
	$header +=  "WelcomeGreetingFilename"
	$header +=  "InfoAnnouncementFilename"
	$header +=  "OperatorExtension"
	$header +=  "DefaultOutboundCallingLineId"
	$header +=  "Extension"
	$header +=  "MatchedNameSelectionMethod"
	$header +=  "InfoAnnouncementEnabled"
	$header +=  "InternationalAccessCode"
	$header +=  "NationalNumberPrefix"
	$header +=  "InCountryOrRegionNumberFormat"
	$header +=  "InternationalNumberFormat"
	$header +=  "CallSomeoneEnabled"
	$header +=  "ContactScope"
	$header +=  "ContactAddressList"
	$header +=  "SendVoiceMsgEnabled"
	$header +=  "UMAutoAttendant"
	$header +=  "AllowDialPlanSubscribers"
	$header +=  "AllowExtensions"
	$header +=  "AllowedInCountryOrRegionGroups"
	$header +=  "AllowedInternationalGroups"
	$header +=  "ConfiguredInCountryOrRegionGroups"
	$header +=  "LegacyPromptPublishingPoint"
	$header +=  "ConfiguredInternationalGroups"
	$header +=  "UMIPGateway"
	$header +=  "URIType"
	$header +=  "SubscriberType"
	$header +=  "GlobalCallRoutingScheme"
	$header +=  "TUIPromptEditingEnabled"
	$header +=  "CallAnsweringRulesEnabled"
	$header +=  "SipResourceIdentifierRequired"
	$header +=  "FDSPollingInterval"
	$header +=  "EquivalentDialPlanPhoneContexts"
	$header +=  "NumberingPlanFormats"
	$header +=  "AllowHeuristicADCallingLineIdResolution"
	$header +=  "CountryOrRegionCode"
	$header +=  "ExchangeVersion"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_UmDialPlan.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_UmDialPlan.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-UmDialPlan sheet

#Region Get-UmIpGateway sheet
Write-Host -Object "---- Starting Get-UmIpGateway"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "UmIpGateway"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "Address"
	$header +=  "OutcallsAllowed"
	$header +=  "Status"
	$header +=  "Port"
	$header +=  "Simulator"
	$header +=  "DelayedSourcePartyInfoEnabled"
	$header +=  "MessageWaitingIndicatorAllowed"
	$header +=  "HuntGroups"
	$header +=  "GlobalCallRoutingScheme"
	$header +=  "ForwardingAddress"
	$header +=  "NumberOfDigitsInExtension"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_UmIpGateway.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_UmIpGateway.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-UmIpGateway sheet

#Region Get-UmMailbox sheet
Write-Host -Object "---- Starting Get-UmMailbox"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "UmMailbox"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "EmailAddresses"
	$header +=  "UMAddresses"
	$header +=  "LegacyExchangeDN"
	$header +=  "LinkedMasterAccount"
	$header +=  "PrimarySmtpAddress"
	$header +=  "SamAccountName"
	$header +=  "ServerLegacyDN"
	$header +=  "ServerName"
	$header +=  "UMDtmfMap"
	$header +=  "UMEnabled"
	$header +=  "TUIAccessToCalendarEnabled"
	$header +=  "FaxEnabled"
	$header +=  "TUIAccessToEmailEnabled"
	$header +=  "SubscriberAccessEnabled"
	$header +=  "MissedCallNotificationEnabled"
	$header +=  "UMSMSNotificationOption"
	$header +=  "PinlessAccessToVoiceMailEnabled"
	$header +=  "AnonymousCallersCanLeaveMessages"
	$header +=  "AutomaticSpeechRecognitionEnabled"
	$header +=  "PlayOnPhoneEnabled"
	$header +=  "CallAnsweringRulesEnabled"
	$header +=  "AllowUMCallsFromNonUsers"
	$header +=  "OperatorNumber"
	$header +=  "PhoneProviderId"
	$header +=  "UMDialPlan"
	$header +=  "UMMailboxPolicy"
	$header +=  "Extensions"
	$header +=  "CallAnsweringAudioCodec"
	$header +=  "SIPResourceIdentifier"
	$header +=  "PhoneNumber"
	$header +=  "AirSyncNumbers"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetUmMailbox") -eq $true)
{
	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetUmMailbox" | Where-Object {$_.name -match "~~GetUmMailbox"}))
	{
		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetUmMailbox\" + $file)
	}
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-UmMailbox sheet

##Region Get-UmMailboxConfiguration sheet
#Write-Host -Object "---- Starting Get-UmMailboxConfiguration"
#	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
#	$Worksheet.name = "UmMailboxConfiguration"
#	$Worksheet.Tab.ColorIndex = $intColorIndex
#	$row = 1
#	$header = @()
#	$header +=  "Identity"
#	$header +=  "Greeting"
#	$header +=  "HasCustomVoicemailGreeting"
#	$header +=  "HasCustomAwayGreeting"
#	$header +=  "IsValid"
#	$a = [int][char]'a' -1
#	if ($header.GetLength(0) -gt 26)
#	{$EndCellColumn = [char]([int][math]::Floor($header.GetLength(0)/26) + $a) + [char](($header.GetLength(0)%26) + $a)}
#	else
#	{$EndCellColumn = [char]($header.GetLength(0) + $a)}
#	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
#	$Header_range.value2 = $header
#	$Header_range.cells.interior.colorindex = 45
#	$Header_range.cells.font.colorindex = 0
#	$Header_range.cells.font.bold = $true
#	$row++
#	$intSheetCount++
#	$ColumnCount = $header.Count
#	$DataFile = @()
#	$EndCellRow = 1
#
#if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetUmMailboxConfiguration") -eq $true)
#{
#	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetUmMailboxConfiguration" | Where-Object {$_.name -match "~~GetUmMailboxConfiguration"}))
#	{
#		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetUmMailboxConfiguration\" + $file)
#	}
#	$RowCount = $DataFile.Count
#	$ArrayRow = 0
#	$BadArrayValue = @()
#	$DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$ColumnCount
#	Foreach ($DataRow in $DataFile)
#	{
#		$DataField = $DataRow.Split("`t")
#		for ($ArrayColumn = 0 ; $ArrayColumn -lt $ColumnCount ; $ArrayColumn++)
#		{
#			# Excel 2003 limit of 1823 characters
#            if ($DataField[$ArrayColumn].length -lt 1823)
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#			# Excel 2007 limit of 8203 characters
#            elseif (($Excel_Exchange.version -ge 12) -and ($DataField[$ArrayColumn].length -lt 8203))
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#			# No known Excel 2010 limit
#            elseif ($Excel_Exchange.version -ge 14)
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#            else
#            {
#                Write-Host -Object "Number of characters in array member exceeds the version of limitations of this version of Excel" -ForegroundColor Yellow
#				Write-Host -Object "-- Writing value to temp variable" -ForegroundColor Yellow
#                $DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]
#                $BadArrayValue += "$ArrayRow,$ArrayColumn"
#            }
#		}
#		$ArrayRow++
#	}
#
#    # Replace big values in $DataArray
#    $BadArrayValue_count = $BadArrayValue.count
#    $BadArrayValue_Temp = @()
#    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
#    {
#        $BadArray_Split = $badarrayvalue[$i].Split(",")
#        $BadArrayValue_Temp += $DataArray[$BadArray_Split[0],$BadArray_Split[1]]
#        $DataArray[$BadArray_Split[0],$BadArray_Split[1]] = "**TEMP**"
#		Write-Host -Object "-- Replacing long value with **TEMP**" -ForegroundColor Yellow
#    }
#
#	$EndCellRow = ($RowCount+1)
#	$Data_range = $Worksheet.Range("a2","$EndCellColumn$EndCellRow")
#	$Data_range.Value2 = $DataArray
#
#    # Paste big values back into the spreadsheet
#    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
#    {
#        $BadArray_Split = $badarrayvalue[$i].Split(",")
#        # Adjust for header and $i=0
#        $CellRow = [int]$BadArray_Split[0] + 2
#        # Adjust for $i=0
#        $CellColumn = [int]$BadArray_Split[1] + 1
#
#        $Range = $Worksheet.cells.item($CellRow,$CellColumn)
#        $Range.Value2 = $BadArrayValue_Temp[$i]
#		Write-Host -Object "-- Pasting long value back in spreadsheet" -ForegroundColor Yellow
#    }
#}
#	#EndRegion Get-UmMailboxConfiguration sheet

##Region Get-UmMailboxPin sheet
#Write-Host -Object "---- Starting Get-UmMailboxPin"
#	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
#	$Worksheet.name = "UmMailboxPin"
#	$Worksheet.Tab.ColorIndex = $intColorIndex
#	$row = 1
#	$header = @()
#	$header +=  "UserID"
#	$header +=  "PinExpired"
#	$header +=  "FirstTimeUser"
#	$header +=  "LockedOut"
#	$header +=  "ObjectState"
#	$header +=  "IsValid"
#	$a = [int][char]'a' -1
#	if ($header.GetLength(0) -gt 26)
#	{$EndCellColumn = [char]([int][math]::Floor($header.GetLength(0)/26) + $a) + [char](($header.GetLength(0)%26) + $a)}
#	else
#	{$EndCellColumn = [char]($header.GetLength(0) + $a)}
#	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
#	$Header_range.value2 = $header
#	$Header_range.cells.interior.colorindex = 45
#	$Header_range.cells.font.colorindex = 0
#	$Header_range.cells.font.bold = $true
#	$row++
#	$intSheetCount++
#	$ColumnCount = $header.Count
#	$DataFile = @()
#	$EndCellRow = 1
#
#if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\GetUmMailboxPin") -eq $true)
#{
#	foreach ($file in (Get-ChildItem -LiteralPath "$RunLocation\output\Exchange\GetUmMailboxPin" | Where-Object {$_.name -match "~~GetUmMailboxPin"}))
#	{
#		$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\GetUmMailboxPin\" + $file)
#	}
#	$RowCount = $DataFile.Count
#	$ArrayRow = 0
#	$BadArrayValue = @()
#	$DataArray = New-Object 'object[,]' -ArgumentList $RowCount,$ColumnCount
#	Foreach ($DataRow in $DataFile)
#	{
#		$DataField = $DataRow.Split("`t")
#		for ($ArrayColumn = 0 ; $ArrayColumn -lt $ColumnCount ; $ArrayColumn++)
#		{
#			# Excel 2003 limit of 1823 characters
#            if ($DataField[$ArrayColumn].length -lt 1823)
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#			# Excel 2007 limit of 8203 characters
#            elseif (($Excel_Exchange.version -ge 12) -and ($DataField[$ArrayColumn].length -lt 8203))
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#			# No known Excel 2010 limit
#            elseif ($Excel_Exchange.version -ge 14)
#                {$DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]}
#            else
#            {
#                Write-Host -Object "Number of characters in array member exceeds the version of limitations of this version of Excel" -ForegroundColor Yellow
#				Write-Host -Object "-- Writing value to temp variable" -ForegroundColor Yellow
#                $DataArray[$ArrayRow,$ArrayColumn] = $DataField[$ArrayColumn]
#                $BadArrayValue += "$ArrayRow,$ArrayColumn"
#            }
#		}
#		$ArrayRow++
#	}
#
#    # Replace big values in $DataArray
#    $BadArrayValue_count = $BadArrayValue.count
#    $BadArrayValue_Temp = @()
#    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
#    {
#        $BadArray_Split = $badarrayvalue[$i].Split(",")
#        $BadArrayValue_Temp += $DataArray[$BadArray_Split[0],$BadArray_Split[1]]
#        $DataArray[$BadArray_Split[0],$BadArray_Split[1]] = "**TEMP**"
#		Write-Host -Object "-- Replacing long value with **TEMP**" -ForegroundColor Yellow
#    }
#
#	$EndCellRow = ($RowCount+1)
#	$Data_range = $Worksheet.Range("a2","$EndCellColumn$EndCellRow")
#	$Data_range.Value2 = $DataArray
#
#    # Paste big values back into the spreadsheet
#    for ($i = 0 ; $i -lt $BadArrayValue_count ; $i++)
#    {
#        $BadArray_Split = $badarrayvalue[$i].Split(",")
#        # Adjust for header and $i=0
#        $CellRow = [int]$BadArray_Split[0] + 2
#        # Adjust for $i=0
#        $CellColumn = [int]$BadArray_Split[1] + 1
#
#        $Range = $Worksheet.cells.item($CellRow,$CellColumn)
#        $Range.Value2 = $BadArrayValue_Temp[$i]
#		Write-Host -Object "-- Pasting long value back in spreadsheet" -ForegroundColor Yellow
#    }
#}
#	#EndRegion Get-UmMailboxPin sheet

#Region Get-UmMailboxPolicy sheet
Write-Host -Object "---- Starting Get-UmMailboxPolicy"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "UmMailboxPolicy"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Name"
	$header +=  "Identity"
	$header +=  "MaxGreetingDuration"
	$header +=  "MaxLogonAttempts"
	$header +=  "AllowCommonPatterns"
	$header +=  "PINLifetime"
	$header +=  "PINHistoryCount"
	$header +=  "AllowSMSNotification"
	$header +=  "ProtectUnauthenticatedVoiceMail"
	$header +=  "ProtectAuthenticatedVoiceMail"
	$header +=  "ProtectedVoiceMailText"
	$header +=  "RequireProtectedPlayOnPhone"
	$header +=  "MinPINLength"
	$header +=  "FaxMessageText"
	$header +=  "UMEnabledText"
	$header +=  "ResetPINText"
	$header +=  "SourceForestPolicyNames"
	$header +=  "VoiceMailText"
	$header +=  "UMDialPlan"
	$header +=  "FaxServerURI"
	$header +=  "AllowedInCountryOrRegionGroups"
	$header +=  "AllowedInternationalGroups"
	$header +=  "AllowDialPlanSubscribers"
	$header +=  "AllowExtensions"
	$header +=  "LogonFailuresBeforePINReset"
	$header +=  "AllowMissedCallNotifications"
	$header +=  "AllowFax"
	$header +=  "AllowTUIAccessToCalendar"
	$header +=  "AllowTUIAccessToEmail"
	$header +=  "AllowSubscriberAccess"
	$header +=  "AllowTUIAccessToDirectory"
	$header +=  "AllowTUIAccessToPersonalContacts"
	$header +=  "AllowAutomaticSpeechRecognition"
	$header +=  "AllowPlayOnPhone"
	$header +=  "AllowVoiceMailPreview"
	$header +=  "AllowCallAnsweringRules"
	$header +=  "AllowMessageWaitingIndicator"
	$header +=  "AllowPinlessVoiceMailAccess"
	$header +=  "AllowVoiceResponseToOtherMessageTypes"
	$header +=  "AllowVoiceMailAnalysis"
	$header +=  "AllowVoiceNotification"
	$header +=  "InformCallerOfVoiceMailAnalysis"
	$header +=  "VoiceMailPreviewPartnerAddress"
	$header +=  "VoiceMailPreviewPartnerAssignedID"
	$header +=  "VoiceMailPreviewPartnerMaxMessageDuration"
	$header +=  "VoiceMailPreviewPartnerMaxDeliveryDelay"
	$header +=  "IsDefault"
	$header +=  "IsValid"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "$RunLocation\output\Exchange\Exchange_UmMailboxPolicy.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_UmMailboxPolicy.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#EndRegion Get-UmMailboxPolicy sheet

# Misc
$intColorIndex = $intColorIndex_Misc
#Region Misc_AdminGroups sheet
Write-Host -Object "---- Starting Misc_AdminGroups"
	$Worksheet = $Excel_Exchange_workbook.worksheets.item($intSheetCount)
	$Worksheet.name = "Misc_AdminGroups"
	$Worksheet.Tab.ColorIndex = $intColorIndex
	$row = 1
	$header = @()
	$header +=  "Group Name"
	$header +=  "Member Count"
	$header +=  "Member"
	$HeaderCount = $header.count
	$EndCellColumn = Get-ColumnLetter $HeaderCount
	$Header_range = $Worksheet.Range("A1","$EndCellColumn$row")
	$Header_range.value2 = $header
	$Header_range.cells.interior.colorindex = 45
	$Header_range.cells.font.colorindex = 0
	$Header_range.cells.font.bold = $true
	$row++
	$intSheetCount++
	$ColumnCount = $header.Count
	$DataFile = @()
	$EndCellRow = 1

if ((Test-Path -LiteralPath "output\Exchange\Exchange_Misc_AdminGroups.txt") -eq $true)
{
	$DataFile += [System.IO.File]::ReadAllLines("$RunLocation\output\Exchange\Exchange_Misc_AdminGroups.txt")
	# Send the data to the function to process and add to the Excel worksheet
	Convert-Datafile $ColumnCount $DataFile $Worksheet $Excel_Version
}
	#endRegion Misc_AdminGroups sheet

# Autofit columns
Write-Host -Object "---- Starting Autofit"
$Excel_ExchangeWorksheetCount = $Excel_Exchange_workbook.worksheets.count
$AutofitSheetCount = 1
while ($AutofitSheetCount -le $Excel_ExchangeWorksheetCount)
{
	$ActiveWorksheet = $Excel_Exchange_workbook.worksheets.item($AutofitSheetCount)
	$objRange = $ActiveWorksheet.usedrange
	[Void]	$objRange.entirecolumn.autofit()
	$AutofitSheetCount++
}
$Excel_Exchange_workbook.saveas($O365DC_Exchange_XLS)
Write-Host -Object "---- Spreadsheet saved"
$Excel_Exchange.workbooks.close()
Write-Host -Object "---- Workbook closed"
$Excel_Exchange.quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel_Exchange)
Remove-Variable -Name Excel_Exchange
# If the ReleaseComObject doesn't do it..
#spps -n excel

	$EventLog = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application
	$EventLog.MachineName = "."
	$EventLog.Source = "O365DC"
	try{$EventLog.WriteEntry("Ending Core_Assemble_Exchange_Excel","Information", 43)}catch{}

