#include <GUIConstantsEx.au3>
#include <File.au3>
#include <FileConstants.au3>
#include <WinAPIFiles.au3>
#include <AutoItConstants.au3>
#include <MsgBoxConstants.au3>
If not IsAdmin() Then
    MsgBox($MB_SYSTEMMODAL, "", "This needs to be run as admin" & @CRLF & "Admin rights not detected.")
	Exit
EndIf
; Variables
$eSetFilePath=@ScriptDir & "\eset"
$eSetFilter="install_config*.ini"
$eSetFileArray=_FileListToArray ( $eSetFilePath, $eSetFilter )
$eSetList = ""
$eSet2FilePath=@ScriptDir & "\Eset"
$eSet2Filter="e*64*.msi"
$eSet2FileArray=_FileListToArray ( $eSet2FilePath, $eSet2Filter )
$eSet2List = ""
$gTAFilePath=@ScriptDir & "\Connectwise"
$gTAFilter="*-ConnectWiseControl.ClientSetup.msi"
$gTAFileArray=_FileListToArray ( $gTAFilePath, $gTAFilter )
$gTAList = ""
$fCFilePath=@ScriptDir & "\Forticlient"
$fCFilter="Forticlient.conf*"
$fCFileArray=_FileListToArray ( $fCFilePath, $fCFilter )
$fCList = ""
$fCPath=@ScriptDir & "\Forticlient\"
$fCSetup=FileFindFirstFile($fCPath & "FortiClient*x64.msi")
$fCinstall=FileFindNextFile($fCSetup)
FileClose($fCSetup)
$o365FilePath=@ScriptDir & "\O365\"
$o365Filter="*install.xml"
$o365FileArray=_FileListToArray ( $o365FilePath, $o365Filter )
$o365List = ""
$10hFilePath=@ScriptDir & "\TenHats\"
$10hFilter="*.cmd"
$10hFileArray=_FileListToArray ( $10hFilePath, $10hFilter )
$10hList = ""
For $i = 0 To UBound($gTAFileArray) - 1
    $gTAList &= "|" & $gTAFileArray[$i]
Next
For $i = 0 To UBound($fCFileArray) - 1
    $fCList &= "|" & $fCFileArray[$i]
Next
For $i = 0 To UBound($eSetFileArray) - 1
    $eSetList &= "|" & $eSetFileArray[$i]
Next
For $i = 0 To UBound($eSet2FileArray) - 1
    $eSet2List &= "|" & $eSet2FileArray[$i]
Next
For $i = 0 To UBound($o365FileArray) - 1
    $o365List &= "|" & $o365FileArray[$i]
Next
For $i = 0 To UBound($10hFileArray) - 1
    $10hList &= "|" & $10hFileArray[$i]
Next
; Create a GUI

$hGUI = GUICreate("MSP Installs", 265, 230)

; Create the combo
$eSetCombo = GUICtrlCreateCombo("", 60, 10, 200, 20)
$eSet2Combo = GUICtrlCreateCombo("", 60, 40, 200, 20)
$gTACombo = GUICtrlCreateCombo("", 60, 70, 200, 20)
$fCCombo = GUICtrlCreateCombo("", 60, 100, 200, 20)
$o365Combo = GUICtrlCreateCombo("", 60, 130, 200, 20)
$fCCheck = GUICtrlCreateCheckbox("Forticlient",165,190)
$10hCombo = GUICtrlCreateCombo("", 60, 160, 200, 20)
$sButton=GUICtrlCreateButton("Install", 60, 190)
; And fill it
GUICtrlSetData($eSetCombo, $eSetList)
GUICtrlSetData($eSet2Combo, $eSet2List)
GUICtrlSetData($gTACombo, $gTAList)
GUICtrlSetData($fCCombo, $fCList)
GUICtrlSetData($o365Combo,$o365List)
GUICtrlSetData($10hCombo,$10hList)
; Create Labels
GUICtrlCreateLabel("Agent",10,10)
GUICtrlCreateLabel("Eset",10,40)
GUICtrlCreateLabel("CW",10,70)
GUICtrlCreateLabel("VPN",10,100)
GUICtrlCreateLabel("O365",10,130)
GUICtrlCreateLabel("TenHats",10,160)

GUISetState()

; On TOp
$hWnd = WinGetHandle("[ACTIVE]")
WinSetOnTop($hWnd, "", $WINDOWS_ONTOP)

While 1
   Switch GUIGetMsg()
	  Case $GUI_EVENT_CLOSE
         Exit
;	   Case $10hCombo
; 	   testing string
;		   MsgBox(1,"Test",@SystemDir & "\msiexec.exe /i " & $10hFilePath & GUICtrlRead($10hCombo) & " TRANSFORMS=" & """" & $10hFilePath & StringTrimRight(GUICtrlRead($10hCombo),1) & "t" & """")
	  Case $sButton
			GUICtrlSetState($sButton,$GUI_DISABLE)
			InstallStuff()
		 Case $fCCombo
			if not GUICtrlRead($fCCombo) = "" Then GUICtrlSetState($fCCheck, $GUI_CHECKED)
   EndSwitch
WEnd
Exit

; Now action the choice
Func InstallStuff()
	$eSetConfSel=@WindowsDir & "\temp\" & (StringTrimright(GUICtrlRead($eSetCombo),(StringLen(GUICtrlRead($eSetCombo))-14))) & ".ini"
	$fCConfSel=@WindowsDir & "\temp\" & GUICtrlRead($fCCombo)
	if not GUICtrlRead($eSetCombo) = "" Then FileCopy (@ScriptDir & "\eset\" & GUICtrlRead($eSetCombo), $eSetConfSel, $FC_OVERWRITE)
	if not GUICtrlRead($fCCombo) = "" Then FileCopy (@ScriptDir & "\Forticlient\" & GUICtrlRead($fCCombo), $fCConfSel, $FC_OVERWRITE)
	if not GUICtrlRead($eSetCombo) = "" Then FileCopy (@ScriptDir & "\eset\Agent_x64.msi", @WindowsDir & "\temp\",$FC_OVERWRITE)
	if not GUICtrlRead($gTACombo) = "" Then FileCopy (@ScriptDir & "\eset\" & GUICtrlRead($gTACombo), @WindowsDir & "\temp\",$FC_OVERWRITE)
	if not GUICtrlRead($eSetCombo) = "" Then
		Local $eAGT=Run(@SystemDir & "\msiexec.exe /i " & @WindowsDir & "\temp\agent_x64.msi /qbn",@WindowsDir & "\temp\")
		ProcessWaitClose($eAGT)
	EndIf
	if not GUICtrlRead($eSet2Combo) = "" Then
		Local $eAPP=Run(@SystemDir & "\msiexec.exe /i " & $eSet2FilePath & "\" & GUICtrlRead($eSet2Combo) & " /qbn")
		ProcessWaitClose($eAPP)
	EndIf
	if not GUICtrlRead($gTACombo) = "" Then
		Local $CWPID=Run(@SystemDir & "\msiexec.exe /i " & $gTAFilePath & "\" & GUICtrlRead($gTACombo) & " /qbn")
		ProcessWaitClose($CWPID)
	EndIf
    If GUICtrlRead($fCCheck) = $GUI_CHECKED Then
		$fPID=Run(@SystemDir & "\msiexec.exe /i " & $fCPath & $fCinstall & " /qbn INSTALLLEVEL=3")
		ProcessWaitClose($fPID)
	EndIf
    if not GUICtrlRead($fCCombo) = "" Then
		$fcPID=Run(@ProgramFilesDir & "\fortinet\forticlient\FCConfig.exe -m all -f " & $fCConfSel & " -o import -i 1")
		ProcessWaitClose($fcPID)
	EndIf
	if not GUICtrlRead($o365Combo) = "" Then
		Local $oPID=Run($o365FilePath & "setup.exe /configure " & $o365FilePath & GUICtrlRead($o365Combo))
		ProcessWaitClose($oPID)
	EndIf
	if not GUICtrlRead($10hCombo) = "" Then
		$10hPID=Run(@SystemDir & "\cmd.exe /c " & $10hFilePath & GUICtrlRead($10hCombo))
		ProcessWaitClose($10hPID)
	EndIf
EndFunc