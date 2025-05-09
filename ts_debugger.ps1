#
# Author 	: systanddeploy (Damien VAN ROBAEYS)
# Date 		: 12/11/2018
# Website	: http://www.systanddeploy.com/
#
#========================================================================

[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom('MahApps.Metro.dll') | out-null
[System.Reflection.Assembly]::LoadFrom('System.Windows.Interactivity.dll') | out-null
[System.Reflection.Assembly]::LoadFrom('MahApps.Metro.IconPacks.dll') | out-null
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
# Add-Type -AssemblyName "System.Drawing"
[System.Windows.Forms.Application]::EnableVisualStyles()

#########################################################################
#                        Load Main Panel                                #
#########################################################################

$Global:pathPanel= split-path -parent $MyInvocation.MyCommand.Definition

function LoadXaml ($filename){
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}


$XamlMainWindow=LoadXaml($pathPanel+"\TS_Debugger.xaml")
$reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form = [Windows.Markup.XamlReader]::Load($reader)


$DataGrid_Steps = $Form.FindName("DataGrid_Steps")
$DataGrid_Variables = $Form.FindName("DataGrid_Variables")


$Regedit = $Form.FindName("Regedit")
$Task_manager = $Form.FindName("Task_manager")
$picture = $Form.FindName("picture")
$Shutdown_PE = $Form.FindName("Shutdown_PE")
$Trace = $Form.FindName("Trace")
$pause = $Form.FindName("pause")
$Start_Stop_Timer = $Form.FindName("Start_Stop_Timer")
$Timer_Icon = $Form.FindName("Timer_Icon")
$CMD_Prompt = $Form.FindName("CMD_Prompt")
$PowerShell_Prompt = $Form.FindName("PowerShell_Prompt")
$Set_Keyboard = $Form.FindName("Set_Keyboard")

$French = $Form.FindName("French")
$English_US = $Form.FindName("English_US")
$German = $Form.FindName("German")
$Spanish = $Form.FindName("Spanish")
$Portuguese = $Form.FindName("Portuguese")


$Choose_Log  = $Form.FindName("Choose_Log")
$GroupBox_Diplay_Log  = $Form.FindName("GroupBox_Diplay_Log")
$Progress_Bar = $Form.FindName("Progress_Bar")
$Set_Log = $Form.FindName("Set_Log")
$Block_Message_Loading = $Form.FindName("Block_Message_Loading")
$GroupBox_Diplay_Log_Waiting = $Form.FindName("GroupBox_Diplay_Log_Waiting")
$Block_Message = $Form.FindName("Block_Message")
$Error_Failed_Step = $Form.FindName("Error_Failed_Step")
$Failed_Step_Block = $Form.FindName("Failed_Step_Block")
$Message_Error = $Form.FindName("Message_Error")

$DART_Block = $Form.FindName("DART_Block")
$Explorer = $Form.FindName("Explorer")
$remoterecovery = $Form.FindName("remoterecovery")
$compmgmt = $Form.FindName("compmgmt")
$diskcmdr = $Form.FindName("diskcmdr")
$filesearch = $Form.FindName("filesearch")
$solutionwizard = $Form.FindName("solutionwizard")
$tcpcfg = $Form.FindName("tcpcfg")
$CrashAnalyze = $Form.FindName("CrashAnalyze")
$hotfixuninstall = $Form.FindName("hotfixuninstall")
$locksmith = $Form.FindName("locksmith")
$filerestore = $Form.FindName("filerestore")
$sfcscan = $Form.FindName("sfcscan")
$Capture_Logs = $Form.FindName("Capture_Logs")


$Block_Message_Loading.Visibility = "Collapsed"
$Block_Message.Visibility = "Visible"


function LoadXml ($global:filename)
{
	$XamlLoader=(New-Object System.Xml.XmlDocument)
	$XamlLoader.Load($filename)
	return $XamlLoader
}
$xamlDialog  = LoadXml(".\Load.xaml")

$read=(New-Object System.Xml.XmlNodeReader $xamlDialog)
$Load_DialogForm=[Windows.Markup.XamlReader]::Load($read)

$Load_Dialog = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($form)
$Load_Dialog.AddChild($Load_DialogForm)



Try
	{
		$Global:MyTSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
		$TS_Wizard_Status = $true
	}
Catch
	{
		$TS_Wizard_Status = $false
		[System.Windows.Forms.MessageBox]::Show("Can not load the TS object.`nSome options might not be available.")
	}

If($TS_Wizard_Status -eq $True)
	{
		$DART_VAR = $MyTSEnv.Value("DARTIP001")
		$DART_VAR2 = $MyTSEnv.Value("DARTPORT001")

		If(($DART_VAR -ne $null) -OR ($DART_VAR2 -ne $null))
			{
				If(test-path $Dart_DLL)
					{
						$DART_Block.Visibility = "Visible"
					}
				Else
					{
						$DART_Block.Visibility = "Collapsed"
					}
			}
	}
Else
	{
		$DART_Block.Visibility = "Collapsed"
	}


$DART_Block.Visibility = "Visible"

#===========================================================================
# Declare the change_theme button and action on this button
#===========================================================================
$Change_Theme = $Form.FindName("Change_Theme")
$Change_Theme.Add_Click({
	$Theme = [MahApps.Metro.ThemeManager]::DetectAppStyle($form)
	$my_theme = ($Theme.Item1).name
	If($my_theme -eq "BaseLight")
		{
			$DataGrid_Steps.BorderBrush = "Gray"
			$DataGrid_Variables.BorderBrush = "Gray"

			[MahApps.Metro.ThemeManager]::ChangeAppStyle($form, $Theme.Item2, [MahApps.Metro.ThemeManager]::GetAppTheme("BaseDark"));
		}
	ElseIf($my_theme -eq "BaseDark")
		{
			$DataGrid_Steps.BorderBrush = "Blue"
			$DataGrid_Variables.BorderBrush = "Blue"

			[MahApps.Metro.ThemeManager]::ChangeAppStyle($form, $Theme.Item2, [MahApps.Metro.ThemeManager]::GetAppTheme("BaseLight"));
		}
})



Function Get_Variables
	{
		$AllVariables = $MyTSEnv.GetVariables() | Where {$_ -ne "_SMSTSTaskSequence"}
		ForEach($Variable in $AllVariables)
		{
			New-Object PSObject -Property @{
			  "Variable_Name" = $Variable;
			  "Variable_Value" = $MyTSEnv.Value($Variable);
			}
		}
	}


Function Populate_Variables_Datagrid
	{
		$Global:MyData = Get_Variables | select Variable_Name, Variable_Value
		ForEach ($data in $MyData)
			{
				$Variables_values = New-Object PSObject
				$Variables_values = $Variables_values | Add-Member NoteProperty Variables_Name $data.Variable_Name -passthru
				$Variables_values = $Variables_values | Add-Member NoteProperty Variables_Value $data.Variable_Value -passthru
				$DataGrid_Variables.Items.Add($Variables_values) > $null
			}
	}


Function Get_Steps
	{
		$Deployroot_folder = $MyTSEnv.Value("DeployRoot")
		$TS_ID = $MyTSEnv.Value("TaskSequenceID")
		$Script:Current_Step_Number = $MyTSEnv.Value("_SMSTSNextInstructionPointer")
		$XML_file = "$Deployroot_folder\Control\$TS_ID\TS.xml"
		[xml]$Get_Content_TS = get-content $XML_file
		$AllSteps = ($Get_Content_TS.SelectNodes("//step")) | where{$_.Disable -eq "False"}
		$Steeps_Count = $AllSteps.Count
		ForEach($Step in $AllSteps)
		{
			New-Object PSObject -Property @{
			  "Step_name" = $Step.name;
			  "Step_action" = $step.action;
			}
		}
	}


Function Populate_Steps_Datagrid
	{
		$Global:MyData_Steps = Get_Steps | Select Step_Name, Step_action

		$TS_Action_Name = $MyTSEnv.Value("_SMSTSCurrentActionName")
		ForEach ($data in $MyData_Steps)
			{
				$TS_Step_Name = $data.Step_name
				If($TS_Step_Name -ne $TS_Action_Name)
					{
						$Step_Status = ""
					}
				Else
					{
						$Step_Status = "Current step"
					}
				$Steps_values = New-Object PSObject
				$Steps_values = $Steps_values | Add-Member NoteProperty Current_Step $Step_Status -passthru
				$Steps_values = $Steps_values | Add-Member NoteProperty All_Steps $data.Step_Name -passthru
				$Steps_values = $Steps_values | Add-Member NoteProperty Steps_Action $data.Step_action -passthru
				$DataGrid_Steps.Items.Add($Steps_values) > $null

			}
		# $DataGrid_Steps.Items[$Current_Step_Number].Current_Step = "Current step"
	}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.add_tick({UpdateUi})

Function UpdateUi()
{
	($DataGrid_Steps.items).Clear()
	($DataGrid_Variables.items).Clear()
	Get_Variables
	Get_Steps
	Populate_Variables_Datagrid
	Populate_Steps_Datagrid
}

$Start_Stop_Timer.Add_Click({
	$Timer_Status = $timer.Enabled
	If ($Timer_Status -eq $true)
		{
			# We'will stop the timer
			$Start_Stop_Timer.ToolTip = "Refresh your deployment status each 10 seconds"
			$timer.Stop()
			$Timer_Icon.Kind = "play"
		}
	Else
		{
			# We'will stop the timer
			$Start_Stop_Timer.ToolTip = "Stop the refresh"
			$timer.start()
			$Timer_Icon.Kind = "playpause"
		}
})




$Regedit.Add_Click({
	start-process regedit
})

$Task_manager.Add_Click({
	start-process taskmgr
})

$Shutdown_PE.Add_Click({
	wpeutil Shutdown
})


$picture.Add_Click({
	$Continue_Process = $False
	$Stop_Capture_Process = $False

	$Form.Left = $([System.Windows.SystemParameters]::WorkArea.Width-$Form.Width) / 2
	$Form.Top = $([System.Windows.SystemParameters]::WorkArea.Height-$Form.Height) / 2

	$ProgData = $env:PROGRAMDATA
	If($SystemDrive -like "*X:*")
		{
			$Script:Dest_Folder = "$SystemDrive\ScreenMe_Pictures\Screen"
			$Script:Full_Path = "$Dest_Folder\ScreenMe_Picture.jpg"
		}
	ElseIf($SystemDrive -like "*C:*")
		{
			$Script:Dest_Folder = "$ProgData\ScreenMe_Pictures"
			$Script:Full_Path = "$Dest_Folder\ScreenMe_Picture.jpg"
		}

	$okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative

	$Button_Style_Obj = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
	$Button_Style_Obj.AffirmativeButtonText = "Local"
	$Button_Style_Obj.NegativeButtonText     = "Mapped drive"

	$Button_Style_Obj.DialogTitleFontSize = "16"
	$Button_Style_Obj.DialogMessageFontSize = "12"

	$result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Picture path","Save the picture locally ?",$okAndCancel, $Button_Style_Obj)
	If($result -eq "Affirmative")
		{
			$Button_Style_Obj.AffirmativeButtonText = "Copy"
			$Button_Style_Obj.NegativeButtonText = "Cancel"
			$Button_Style_Obj.DefaultText = $Full_Path
			$Button_Style_Obj.DefaultButtonFocus = "Affirmative"

			$Script:Get_Screenshot_Path = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($Form,"Picture path","Where do you want to save the picture ?", $Button_Style_Obj)

			If($Get_Screenshot_Path -eq "")
				{
					$Script:Continue_Process = $False
				}
			ElseIf($Get_Screenshot_Path -eq $null)
				{
					$Script:Continue_Process = $False
				}
			Else
				{
					$Script:Export_Type = "Local_Drive"
					$Script:Continue_Process = $True
					$Script:Get_Screenshot_Folder_Path = split-path $Get_Screenshot_Path
				}
		}
	Else
		{
			$Button_Style_Obj.AffirmativeButtonText = "Continue"
			$Button_Style_Obj.NegativeButtonText     = "Cancel"
			$Script:Get_Screenshot_Path = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($Form,"Picture path","Where do you want to save the picture ?", $Button_Style_Obj)

			If($Get_Screenshot_Path -eq "")
				{
					$Script:Continue_Process = $False
				}
			ElseIf($Get_Screenshot_Path -eq $null)
				{
					$Script:Continue_Process = $False
				}
			Else
				{
					$Script:Export_Type = "Mapped_Drive"
					$Button_Style_Obj = [MahApps.Metro.Controls.Dialogs.LoginDialogSettings]::new()
					$Button_Style_Obj.EnablePasswordPreview = $true
					$Button_Style_Obj.RememberCheckBoxText = $true
					$Button_Style_Obj.DialogTitleFontSize = "16"
					$Button_Style_Obj.DialogMessageFontSize = "12"
					$Button_Style_Obj.AffirmativeButtonText = "Copy"
					$Button_Style_Obj.NegativeButtonText     = "Cancel"
					$Button_Style_Obj.NegativeButtonVisibility  = "Visible"

					$Login = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalLoginExternal($Form,"Credentials","Type your credentials", $Button_Style_Obj)
					$User_Login = $Login.Username
					$User_PWD  = $Login.Password

					If($Login -eq "")
						{
							$Script:Continue_Process = $False
						}
					ElseIf($Login -eq $null)
						{
							$Script:Continue_Process = $False
						}
					Else
						{
							$Script:Continue_Process = $True
							Try
								{
									$Secure_PWD = $User_PWD | ConvertTo-SecureString -AsPlainText -Force
									$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User_Login, $Secure_PWD
									New-PSDrive -name "K" -PSProvider FileSystem -Root $Get_Screenshot_Path -Persist -Credential $Creds -ea silentlycontinue -ErrorVariable PSDrive_Error

									If($PSDrive_Error -ne $null)
										{
											[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Oops :-(","Can not map the drive !!!",$okAndCancel)
											$Script:Continue_Process = $False
										}
									Else
										{
											$Script:Continue_Process = $True
										}
								}
							Catch
								{
									[System.Windows.Forms.MessageBox]::Show("Oops`nCan not map the drive !!!")
									$Script:Continue_Process = $False
								}
							$Script:Get_Screenshot_Folder_Path = $Get_Screenshot_Path
							$Script:Get_Screenshot_Path = "$Get_Screenshot_Path\ScreenMe_Picture.jpg"
						}
				}
		}

		If($Continue_Process -eq "True")
			{
				If(test-path $Get_Screenshot_Path)
					{
						$Button_Style_Obj.AffirmativeButtonText = "Copy"
						$Button_Style_Obj.NegativeButtonText = "Cancel"
						$Button_Style_Obj.DefaultText = ''
						$Button_Style_Obj.DefaultButtonFocus = "Affirmative"

						$Script:Get_New_Name = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($Form,"Oops :-(","This file already exists. Type new JPG name", $Button_Style_Obj)
						If($Get_New_Name -eq "")
							{
								$Script:Stop_Capture_Process = $True
							}
						ElseIf($Get_New_Name -eq $null)
							{
								$Script:Stop_Capture_Process = $True
							}
						Else
							{
								If(($Get_New_Name -notlike "*.jpg"))
									{
										$Get_New_Name = "$Get_New_Name.jpg"
									}
								$Script:Get_Screenshot_Path = "$Get_Screenshot_Folder_Path\$Get_New_Name"
								$Script:Stop_Capture_Process = $False
							}
					}

				If($Script:Export_Type -eq "Local_Drive")
					{
						$Script:Export_Folder_Path = split-path $Get_Screenshot_Path
						If(!(test-path $Export_Folder_Path))
							{
								Try
									{
										new-item $Export_Folder_Path -Type Directory -Force -ea stop
									}
								catch
									{
										[System.Windows.Forms.MessageBox]::Show("Oops`nCan not create the file !!!")
										$Script:Stop_Capture_Process = $True
									}
							}
					}

				If($Stop_Capture_Process -ne $True)
					{
						$Form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
						Try
							{
								sleep 1

								Add-Type -AssemblyName System.Windows.Forms
								Add-type -AssemblyName System.Drawing
								$Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
								$Width = $Screen.Width
								$Height = $Screen.Height
								$Left = $Screen.Left
								$Top = $Screen.Top
								$bitmap = New-Object System.Drawing.Bitmap $Width, $Height
								$graphic = [System.Drawing.Graphics]::FromImage($bitmap)
								$graphic.CopyFromScreen($Left, $Top, 0, 0, $bitmap.Size)
								$bitmap.Save($Get_Screenshot_Path)

								$Form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
								$Open_Folder.Visibility = "Visible"
							}
						Catch
							{
								[System.Windows.Forms.MessageBox]::Show("Oops`nCan not create the file !!!")
								$Form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
								$Open_Folder.Visibility = "Visible"
							}
					}
			}
})

$Trace.Add_Click({
	& .\CMTrace.exe
})
$pause.IsEnabled = $True
# If($TS_Wizard_Status -eq $True)
	# {
		# $TSPause_Var = $MyTSEnv.Value("TSPause")
		# If($TSPause_Var -ne "")
			# {
				# $pause.IsEnabled = $True
			# }
		# Else
			# {
				# $pause.IsEnabled = $False
			# }
	# }
# Else
	# {
		# $pause.IsEnabled = $False
	# }


$pause.Add_Click({
	$MyTSEnv.Value("TSPause") = "TRUE"
})

$CMD_Prompt.Add_Click({
	start-process cmd
})

$PowerShell_Prompt.Add_Click({
	start-process powershell
})



# DART
$locksmith.Add_Click({
	start-process locksmith
})

$hotfixuninstall.Add_Click({
	start-process hotfixuninstall
})

$CrashAnalyze.Add_Click({
	start-process CrashAnalyze
})

$tcpcfg.Add_Click({
	start-process tcpcfg
})

$solutionwizard.Add_Click({
	start-process solutionwizard
})

$filesearch.Add_Click({
	start-process filesearch
})

$diskcmdr.Add_Click({
	start-process diskcmdr
})

$compmgmt.Add_Click({
	start-process compmgmt
})

$remoterecovery.Add_Click({
	start-process remoterecovery
})

$Explorer.Add_Click({
	start-process Explorer
})

$filerestore.Add_Click({
	start-process filerestore
})

$sfcscan.Add_Click({
	start-process sfcscan
})





Function Copy_Logs{
	param(
	$Logs_Path_To_Copy
	)

	If(Test-Path $Logs_Path_To_Copy)
		{
			copy-item $Logs_Path_To_Copy $ZIP_Export_Path -recurse -force
		}
	}

Function Generate_Log_Folder
	{
		$DISM_folder = "$env:SystemRoot\Panther\Logs\DISM"
		$Panther_folder = "$env:SystemRoot\Panther"
		$Debug_folder = "$env:SystemRoot\Panther\debug"
		$EVTX_Logs_Folder = "$ZIP_Export_Path\Events_Logs"

		$DeploymentLogs_folder = "$env:SystemRoot\Temp\DeploymentLogs"
		$MININT_folder = "$env:SystemDrive\MININT"
		$SMSTaskSequence_folder = "$env:SystemDrive\_SMSTaskSequence"

		If(!(test-path $EVTX_Logs_Folder)){new-item $EVTX_Logs_Folder -type directory -force}
		wevtutil epl system "$EVTX_Logs_Folder\System_logs.evtx"
		wevtutil epl Application "$EVTX_Logs_Folder\Application_logs.evtx"
		wevtutil epl Setup "$EVTX_Logs_Folder\Setup_logs.evtx"

		# Copy_Logs -Logs_Path_To_Copy $Logs_Folder
		Copy_Logs -Logs_Path_To_Copy $Panther_folder
		Copy_Logs -Logs_Path_To_Copy $DISM_foldr
		Copy_Logs -Logs_Path_To_Copy $Debug_folder
}





$Capture_Logs.Add_Click({
	$okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
	$ZIP_Button_Style_Obj = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()

	$ZIP_Button_Style_Obj.AffirmativeButtonText = "Yes"
	$ZIP_Button_Style_Obj.NegativeButtonText     = "No"

	$ZIP_Button_Style_Obj.DialogTitleFontSize = "20"
	$ZIP_Button_Style_Obj.DialogMessageFontSize = "14"

	$ZIP_Log_result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"ZIP logs","Do you want to ZIP deployment and event logs ?",$okAndCancel, $ZIP_Button_Style_Obj)

	If($ZIP_Log_result -eq "Affirmative")
		{
			$Script:Continue_Process = $True

			$okAndCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
			$ZIP_Button_Style_Obj.AffirmativeButtonText = "Locally"
			$ZIP_Button_Style_Obj.NegativeButtonText = "Network share"

			$ZIP_Log_result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Saving mode","How do you want to capture ZIP logs ?",$okAndCancel, $ZIP_Button_Style_Obj)
			If($ZIP_Log_result -eq "Affirmative")
				{
					$ZIP_Button_Style_Obj.AffirmativeButtonText = "Copy"
					$ZIP_Button_Style_Obj.NegativeButtonText = "Cancel"
					$ZIP_Button_Style_Obj.DefaultButtonFocus = "Affirmative"

					$Script:Get_ZIP_Export_Path = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($Form,"ZIP location","Type the ZIP path:", $ZIP_Button_Style_Obj)
					If($Get_ZIP_Export_Path -eq "")
						{
							$Script:Continue_Process = $False
						}
					ElseIf($Get_ZIP_Export_Path -eq $null)
						{
							$Script:Continue_Process = $False
						}
					Else
						{
							$Script:Export_Type = "Local_Drive"
							$Script:Continue_Process = $True
							$Script:Get_ZIP_Folder_Path = split-path $Get_ZIP_Export_Path
						}
				}
			Else
				{
					$ZIP_Button_Style_Obj.AffirmativeButtonText = "Continue"
					$ZIP_Button_Style_Obj.NegativeButtonText     = "Cancel"
					$Get_ZIP_Export_Path = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($Form,"Network path","Type the network path where to save the ZIP logs file:", $ZIP_Button_Style_Obj)

					If($Get_ZIP_Export_Path -eq "")
						{
							$Script:Continue_Process = $False
						}
					ElseIf($Get_ZIP_Export_Path -eq $null)
						{
							$Script:Continue_Process = $False
						}
					Else
						{
							$Script:Export_Type = "Mapped_Drive"
							$ZIP_Button_Style_Obj = [MahApps.Metro.Controls.Dialogs.LoginDialogSettings]::new()
							$ZIP_Button_Style_Obj.EnablePasswordPreview = $true
							$ZIP_Button_Style_Obj.AffirmativeButtonText = "Copy"
							$ZIP_Button_Style_Obj.NegativeButtonText     = "Cancel"
							$ZIP_Button_Style_Obj.NegativeButtonVisibility  = "Visible"

							$Login = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalLoginExternal($Form,"Credentials","Type your network credentials", $ZIP_Button_Style_Obj)
							$User_Login = $Login.Username
							$User_PWD  = $Login.Password

							If($Login -eq "")
								{
									$Script:Continue_Process = $False
								}
							ElseIf($Login -eq $null)
								{
									$Script:Continue_Process = $False
								}
							Else
								{
									$Script:Continue_Process = $True
									Try
										{
											$Secure_PWD = $User_PWD | ConvertTo-SecureString -AsPlainText -Force
											$Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User_Login, $Secure_PWD
											New-PSDrive -name "K" -PSProvider FileSystem -Root $Get_ZIP_Export_Path -Persist -Credential $Creds -ea silentlycontinue -ErrorVariable PSDrive_Error

											If($PSDrive_Error -ne $null)
												{
													$ok = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
													[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Oops :-(","Can not connect to the share !!!`nCheck username or password",$ok)
													$Script:Continue_Process = $False
												}
											Else
												{
													$Script:Continue_Process = $True
												}
										}
									Catch
										{
											[System.Windows.Forms.MessageBox]::Show("Oops`nCan not connect to the share !!!`n  Impossible de se connecter au share !!!`nCheck username or password")
											$Script:Continue_Process = $False
										}
									$Script:Get_ZIP_Folder_Path = $Get_ZIP_Export_Path
									$Script:Get_ZIP_Export_Path = "$Get_ZIP_Export_Path\ScreenMe_Picture.jpg"
								}
						}
				}
		}


		If($Continue_Process -eq "True")
			{
				$Comp_Name = $env:COMPUTERNAME
				$ZIP_File = "$Get_ZIP_Export_Path\Logs_$Comp_Name" + ".zip"
				$New_Name_Status = $False

				If($Get_ZIP_Export_Path -ne $null)
					{
						$ZIP_Export_Path = "$Get_ZIP_Export_Path\ZIP_Export_Path"

						If(test-path $ZIP_File)
							{
								$ZIP_Button_Style_Obj.AffirmativeButtonText = "Continue"
								$ZIP_Button_Style_Obj.NegativeButtonText     = "Cancel"
								$ZIP_Button_Style_Obj.DefaultText = ''
								$ZIP_Button_Style_Obj.DefaultButtonFocus = "Affirmative"

								$Script:New_File_Name = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($Form,"Oops :-(","This file alrdy exists. Please type a new file name.", $ZIP_Button_Style_Obj)
								If($New_File_Name -eq "")
									{
										$Script:Stop_Capture_Process = $True
										$New_Name_Status = $False
									}
								ElseIf($New_File_Name -eq $null)
									{
										$Script:Stop_Capture_Process = $True
										$New_Name_Status = $False
									}
								Else
									{
										$New_Name_Status = $True
										$Script:Stop_Capture_Process = $False
									}
							}
						Else
							{
								new-item $ZIP_Export_Path -Type Directory -Force
								$Script:Stop_Capture_Process = $False
							}

						If($Stop_Capture_Process -eq $False)
							{
								Generate_Log_Folder

								If($New_Name_Status -eq $True)
									{
										$ZIP_File = "$Get_ZIP_Export_Path\$New_File_Name" + ".zip"
									}
								Else
									{
										$ZIP_File = "$Get_ZIP_Export_Path\Logs_$Comp_Name" + ".zip"
									}
								# $Comp_Name = $env:COMPUTERNAME
								# $ZIP_File = "$Get_ZIP_Export_Path\ZIP_Export_Path" + ".zip"
								Try
									{
										Add-Type -assembly "system.io.compression.filesystem"
										[io.compression.zipfile]::CreateFromDirectory($ZIP_Export_Path, $ZIP_File)
										[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Success :-)","The ZIP file has been successfully created.")
									}
								Catch
									{
										[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"Oops :-(","Can not create ZIP logs file")
									}
								Remove-item $ZIP_Export_Path -force -recurse
							}
					}
			}
})


















$Set_Keyboard.Add_Click({
	If($English_US.IsSelected -eq $True)
		{
			wpeutil setkeyboardlayout "0409:00000409"
		}
	ElseIf($French.IsSelected -eq $True)
		{
			wpeutil setkeyboardlayout "040c:0000040c"
		}
	ElseIf($German.IsSelected -eq $True)
		{
			wpeutil setkeyboardlayout "0407:00000407"
		}
	ElseIf($Portuguese.IsSelected -eq $True)
		{
			wpeutil setkeyboardlayout "0816:00000816"
		}
	ElseIf($Spanish.IsSelected -eq $True)
		{
			wpeutil setkeyboardlayout "040a:0x0000040a"
		}
})

# $TS_Wizard_Status = $true
Function Get_Log_Folder
	{
		If($TS_Wizard_Status -eq $True)
			{
				Try
				{
					$Script:Logs_Folder = $MyTSEnv.Value("LogPath")
					$Script:SMSTS_Logs_Folder = $MyTSEnv.Value("_SMSTSLogPath")

					$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
					$TSProgressUI.CloseProgressDialog()
					$TSProgressUI = $null
				}
				Catch
				{
				}

				Return $Logs_Folder
			}

	}

Function Populate_Combo_Logs
	{
		$Script:Logs_Folder_Content = Get-Childitem $Logs_Folder, $SMSTS_Logs_Folder | Where {$_.Extension -like "*log*"}
		foreach ($Log in $Logs_Folder_Content)
			{
				$Log_Full_Path = $Log.FullName
				$Log_Short_Name = $Log.Name
				$Choose_Log.Items.Add($Log_Short_Name) | out-null
			}
	}

# Get_Log_Folder


$Choose_Log.add_SelectionChanged({
	$Script:Logs_Folder_Content = Get-Childitem $Logs_Folder | Where {$_.Extension -like "*log*"}
	$Script:My_Log = $Choose_Log.SelectedItem
	foreach ($Log in $Logs_Folder_Content)
		{
			If ($My_Log -eq $Log.Name)
				{
					$Script:Log_Full_Path = $Log.FullName
					$Log_Short_Name = $Log.Name
					$GroupBox_Diplay_Log.Header = "Content of log: $Log_Short_Name"
				}
		}
})

$Set_Log.add_Click({
	$Message_Error.Items.Clear();
	Load_Log -Log_File $Log_Full_Path
})


function Load_Log
{
	Param
	 (
		[String]$Log_File
	 )

	$Block_Message_Loading.Visibility = "Visible"
	$Block_Message.Visibility = "Collapsed"

	$Form.Dispatcher.Invoke([action] {}, "Render")

	$SMSLOGS = Get-Content $Log_File
	$i=0
	$Progress_Bar.Maximum = $SMSLOGS.count
	Foreach ($Line in $SMSLOGS)
	{
		$i++

		try
		{
			if ($Line.indexof("><") -ne -1 -and $Line.split(">").count -gt 2)
			{
				$Message = $Line.split(">")[0].replace("<![LOG[", "").replace("]LOG]!", "")
				$Datemsg = ($Line.split(">")[1].replace("<", "").split(" ") | Where-Object { $_ -like "date*" }).split("=")[1].replace('"', "")
				$Timemsg = ($Line.split(">")[1].replace("<", "").split(" ") | Where-Object { $_ -like "time*" }).split("=")[1].split(".")[0].replace('"', "")
				$item = "$Datemsg $Timemsg $Message"

				$Message_Error.Items.Add($item)

				$Progress_Bar.Value = $i
				$Form.Dispatcher.Invoke([action] {}, "Render")
				$Message_Error.SetSelected($Message_Error.Items.Count - 1, $true)
			}

		}
		catch
		{
			$Line
		}

	}

	$Block_Message_Loading.Visibility = "Collapsed"
	$Block_Message.Visibility = "Visible"
}

If($TS_Wizard_Status -eq $true)
	{
		Populate_Variables_Datagrid
		Populate_Steps_Datagrid
		Get_Log_Folder
		Populate_Combo_Logs
	}

$Form.ShowDialog() | Out-Null   ‘   {"EmbedFiles":false,"AssemblyVersion":"0.0.0.0","FileVersion":"0.0.0.0","ProductName":"","ProductDescription":"","CompanyName":"","Copyright":""}