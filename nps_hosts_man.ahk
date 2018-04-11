;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                                       ;
INIT_CRC_CHECK:=FileCRC32(A_ScriptFullPath) ; This is added security; not full security,;
									;	but 											;
									;	it alerts the user if this file is being edited/;
									;	manipulated during run time. The author of a 	;
									;	program/software should be able to provide the 	;
									;	original files CRC.	A constant SetTimer	will	;
									;	continuously check this files CRC against mine.	;
									;	If the check in this file is manipulated it will;
									;	still exit and you can then check this file with;
									;	against the real CRC with my program NPS CRC 	;
									;	Check.											;
;                                                                                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                                     	;
; NPS Hosts Manager - Ian Pride - New Pride Services                                  	;
;                                                                                     	;
; Began - 9:29 AM Monday, April 2, 2018                                               	;
;                                                                                     	;
; Simple gui to make quick work of editing your Windows hosts file					  	;
; Edit, backup, restore, or replace your hosts file									  	;
;                                                                                     	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Init - Directives																	  	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetTimer,CheckCRC,1
If ! A_IsAdmin && ! RunAsAdmin(A_ScriptFullPath) {
	MsgBox,48,NPS Hosts Manager Info,% "You denied administrative privileges. You can"
									.	" not edit your hosts file without"
									.	" administrative privileges. Please try again."
	ExitApp
}	; This program can only be used with administrative privileges. You cannot manage
	; your hosts file otherwise.
If ! lib:=LoadLib(A_WinDir . "\System32\User32.dll") {
	MsgBox,16,NPS Hosts Manager Error,% A_WinDir "\System32\User32.dll could not be "
									.	"loaded and this program will not exit."
	ExitApp
} Else DllCall("FreeLibrary","Ptr",lib) ; test load library
									
#SingleInstance,Force
#InstallMouseHook												
;#MaxThreads,255    																  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Init - Performance																  	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetBatchLines,-1
SetKeyDelay,-1
SetWinDelay,0
#MaxThreads,255

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Init - Vars																		 	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TITLE:="NPS Hosts Manager"
MB_PRMS:=[TTL_ERR,"",A_ScriptHwnd]
MSGBOX:=New MsgBox(MB_PRMS[1],MB_PRMS[2],MB_PRMS[3])
MB_S:=MSGBOX.Styles
HOSTS_DIR:=New File(A_WinDir "\System32\drivers\etc")
HOSTS_FILE:=New File(HOSTS_DIR.file "\hosts")
IN_USE_MSG=
(

	It is always possible (and likely) that the "hosts" file
is in use by another program, especially by web applications
such as web browsers and anti-viruses. This is normal behavi-
or, but in order to edit your hosts file it cannot be locked.
A common file that can lock the hosts file is svchost.exe;
which, can lock it frequently. To ensure svchosts does not lock
the hosts file please shut off any web applications and allow
hosts editing in your AV while running this program.

)
If ! HOSTS_FILE.file
	Gosub,NoHostsFound
HOSTS_ORIG=
(
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#	127.0.0.1       localhost
#	::1             localhost

)
STATUS_TOGGLE:=New toggle
NO_INPUT:=New toggle
TTL_NFO:=TITLE " Info"
TTL_ERR:=TITLE " Error"
NL:="`n"
HELP_MSG=
(
%NL% %A_Tab% %TITLE% can easily manage your hosts
file even in read only mode. You can backup, replace, restore,
edit in temporary write mode (until file is exited), and change
the Read/Write mode very quickly.

	The one drawback is that some features in this
program are harder to use if the hosts file is in use.
%IN_USE_MSG%

)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Init - Pre-Process                                                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
For name, hex in {"WM_MOUSEMOVE":"0x200","WM_LBUTTONDOWN":"0x201"
				,"WM_HELP":"0x53"}
	OnMessage(hex,name)

If HOSTS_FILE.rw {
	If (MSGBOX.Display(TTL_NFO,HOSTS_FILE.file " is currently:`nReadable/Writable [RW]." 
		. 	"`n`nThis is not recommended, would you like to set the file to:" 
		.	"`nRead Only [RO]?",SCRIPT_ID,	MB_S["MB_YESNO"]
								+	MB_S["MB_ICONQUESTION"]
								+	MB_S["MB_TASKMODAL"])=6)	{
		If ! HOSTS_FILE.SetAttrib(HOSTS_FILE.file,"+R")
			InfoErr("The attempt to set your hosts file to Read"
					.	"Only was not successful. Is the file in use by another"
					.	" program?")
		Else InfoMsg(HOSTS_FILE.file  " was set to:`nRead Only`nsuccessfully.")
	} Else InfoMsg("You can change your hosts file to Read Only at any time by"
				.	"clicking the [Restore Default Hosts File] button.")
}
						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System tray menu																	    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Menu,Tray,NoStandard
Menu,Tray,Add,&Reload %TITLE%,Reload
Menu,Tray,Add
Menu,Tray,Add,E&xit %TITLE%,Exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Gui																				    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Gui,-Caption +Border +LastFound
SCRIPT_ID:=WinExist()
Gui,Color,0x34495E,0xFEFEFE
Gui,Font,c0x34495E s12 q5 w500,Segoe UI
Gui,Margin,0,0
GuiButton(TITLE,"TitleVar","ProgVar","TitleProgHwnd","TitleTxtHwnd",,"0xE0E0E0"
			,"0x34495E",0,0,408,28)
MinButton(360,20,"0x34495E","0x34495E")
CloseButton("+4",4,"0x34495E","0xD50000")
Gui,Add,Text,Section x8 y+12 w392 h1
Gui,Font,s11 w400
GuiButton("&Backup Hosts File","BackupVar","BackProgVar"
			,"BackupProgHwnd","BackupTxtHwnd",,"0xE0E0E0","0xFEFEFE","s","s",192,28)
GuiButton("&Replace Hosts File","ReplaceVar","ReplaceProgVar"
			,"ReplaceProgHwnd","ReplaceTxtHwnd",,"0xE0E0E0","0xFEFEFE","+8","p",192,28)
GuiButton("&Restore &Default Hosts File","RestoreVar","RestoreProgVar"
			,"RestoreProgHwnd","RestoreTxtHwnd",,"0xE0E0E0","0xFEFEFE","8","+8",192,28)
GuiButton("&Edit Hosts File","EditButtonVar","EditProgVar"
			,"EditProgHwnd","EditTxtHwnd",,"0xE0E0E0","0xFEFEFE","+8","p","192",28)
Gui,Font,s8
GuiButton("Show &Status","StatusButtonVar","StatusProgVar"
			,"StatusProgHwnd","StatusTxtHwnd",,"0xE0E0E0","0xFEFEFE","8","+8","92",20)
GuiButton("RW &Mode: " ( (HOSTS_FILE.file)? (HOSTS_FILE.rw?"Read":"Write") : "NA" )
		,"ToggleRWButtonVar","ToggleRWProgVar","ToggleRWProgHwnd","ToggleRWTxtHwnd"
		,,"0xE0E0E0","0xFEFEFE","+8","p","92",20)
Gui,Add,Picture,x+8 yp w20 h20 Icon211 gWM_HELP, shell32.dll
Gui,Font,c0xFFFFFF s6
Gui,Add,Text,x+4 yp h20,F1
Gui,Font,s8
Gui,Add,Link,x+52 yp h20 w108 +BackgroundTrans +0x400000 -Caption,<a href="https://lateralus138.github.io/">lateralus138.github.io</a>
Gui,Add,Text,xs y+0 w392 h8
Gui,Add,StatusBar,Hidden vStatusVar hwndStatusHwnd
Gui,Show,AutoSize,%TITLE%
SB_SetParts(318,90)
SB_SetIcon("shell32.dll",278,1)
SB_SetIcon("shell32.dll",(HOSTS_FILE.rws="W")?78:212,2) ; 212
SB_SetText(HOSTS_FILE.file?HOSTS_FILE.file " is currently : ":"No hosts file found.",1)
SB_SetText(  HOSTS_FILE.file?((HOSTS_FILE.rws="W")?"Writable":"Read Only"):"Not Found",2)
GetControls(TITLE)

Return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Hotkeys                                                                               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#If (WinActive(TITLE) And ! NO_INPUT.state)
	s::Gosub,ToggleStatus
	b::Gosub,Backup
	r::Gosub,Replace
	d::Gosub,Restore
	e::Gosub,Edit
	m::Gosub,ToggleRW
#IfWinActive
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Functions																			    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#Include, C:\Users\FluxApex\Documents\AutoHotkey\Projects\NPS Hosts Manager (master compile)\MB_AHK.ahk
#Include, C:\Users\FluxApex\Documents\AutoHotkey\Projects\NPS Hosts Manager (master compile)\FILE_AHK.ahk
#Include, C:\Users\FluxApex\Documents\AutoHotkey\Projects\NPS Hosts Manager (master compile)\nps_hosts_man_funcs.ahk
#Include, C:\Users\FluxApex\Documents\AutoHotkey\Projects\NPS Hosts Manager (master compile)\SB_SETPROGRESS.ahk

InfoMsg(msg){
	Global
	MSGBOX.Display(TTL_NFO,msg,SCRIPT_ID,MB_S["MB_OK"]
							+	MB_S["MB_ICONINFORMATION"]
							+	MB_S["MB_TASKMODAL"])
}
InfoErr(msg){
	Global
	MSGBOX.Display(TTL_ERR,msg,SCRIPT_ID,MB_S["MB_OK"]
							+	MB_S["MB_ICONERROR"]
							+	MB_S["MB_TASKMODAL"])
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Subs																				    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ToggleRW:
	If HOSTS_FILE.set() {
		If HOSTS_FILE.ro {
			If HOSTS_FILE.SetAttrib(HOSTS_FILE.file,"-R") {
				SB_SetText("Hosts file was set to Read/Write successfully.")
				HOSTS_FILE.set()
				GuiControl,,ToggleRWButtonVar,% "RW &Mode: " ( (HOSTS_FILE.file)
									? (HOSTS_FILE.rw?"Read":"Write") : "NA")
				Gosub,ShowRWS
			}	Else InfoErr("Could not set your hosts file to Read Only."
						.	"`nIs your hosts file in use by another program?`n" IN_USE_MSG)
		}	Else	{
			If HOSTS_FILE.SetAttrib(HOSTS_FILE.file,"+R") {
				SB_SetText("Hosts file was set to Read Only successfully.")
				HOSTS_FILE.set()
				GuiControl,,ToggleRWButtonVar,% "RW &Mode: " ( (HOSTS_FILE.file)
									? (HOSTS_FILE.rw?"Read":"Write") : "NA")
				Gosub,ShowRWS				
			}	Else InfoErr("Could not set your hosts file to Read/Write."
						.	"`nIs your hosts file in use by another program?`n" IN_USE_MSG)
		}
	}	Else	{
			SB_SetText("Hosts file does not exist.")
			GuiControl,,ToggleRWButtonVar,% "RW &Mode: " ( (HOSTS_FILE.file)
								? (HOSTS_FILE.rw?"Read":"Write") : "NA")
			Gosub,ShowRWS
	}
Return
Edit:
	HOSTS_FILE:=New File(A_WinDir "\System32\drivers\etc\hosts")
	If HOSTS_FILE.set() {
		If HOSTS_FILE.ro {
			If HOSTS_FILE.SetAttrib(HOSTS_FILE.file,"-R")
				Gosub,TryNP
			Else {
				InfoErr("Your hosts file was not set to Read/Write."
						.	"`nIs your hosts file in use by another program?`n" IN_USE_MSG)
				Return
			}
		} 	Else Gosub,TryNP
	}	Else Gosub,NoHostsFound
Return
TryNP:
	Try,Run,% "notepad " HOSTS_FILE.file
	Catch NP_RUN_ERR {
		InfoErr("Could not run notepad for an unknown reason.")
		Return
	}
	SetTimer,CheckNP,1000
Return
CheckNP:
	WinWaitClose,hosts - Notepad
	HOSTS_FILE:=New File(A_WinDir "\System32\drivers\etc\hosts")
	If HOSTS_FILE.set()
		If HOSTS_FILE.rw
			If ! HOSTS_FILE.SetAttrib(HOSTS_FILE.file,"+R")
				InfoErr("Your hosts file was not set to Read/Write."
						.	"`nIs your hosts file in use by another program?`n" IN_USE_MSG)
	SetTimer,,Off
Return
Backup:
	If IsObject(hosts_file_obj:=FileOpen(HOSTS_FILE.file,"r")) {
		SetTimer,EnterFile,-500
		FileSelectFile,BackupFile,S26,% HOSTS_DIR.file,% "Backup file - " """" 
			.	HOSTS_FILE.path.name """" " to: "
			,	Backup File [can be saved as any file] (*.bak)
		If BackupFile {
			If FileExist(BackupFile) {
				Try,FileDelete,%BackupFile%
				Catch FILE_DEL_ERR {
					InfoErr("The file you selected for backup:`n`n"
							.	BackupFile "`n`nexisted already and could not be"
							.	" replaced.`nIs the file in use by another program?"
							.	"`nMake sure the file is not in use in and try again"
							.	" or select/create a different file name.")
					BackupFile:=FILE_DEL_ERR:=""
					hosts_file_obj.Close()
					Return
				}
			}
			Try,FileAppend,% hosts_file_obj.Read(),%BackupFile%
			Catch FILE_BACK_ERR {
				InfoErr("Could not create file:`n`n" BackupFile
						.	"`n`nfor an unknown reason. Please make sure"
						.	" the folder you are trying to save in is not"
						.	" Read Only.")
				BackupFile:=FILE_BACK_ERR:=""
				hosts_file_obj.Close()
				Return
			}
			InfoMsg(HOSTS_FILE.file "`n`nwas backed up successfully to"
							.	"`n`n" BackupFile)
			BackupFile:=""
			hosts_file_obj.Close()
		} Else {
			SB_SetText("No file was selected for backup.")
			InfoMsg("No file was selected for backup.")
		}
		hosts_file_obj.Close()
	} Else Gosub,NoHostsFound
		hosts_file_obj.Close()
Return
NoHostsFound:
		If ( MSGBOX.Display(TTL_NFO,"No hosts file was found."
			.	" Would you like to create the default?"
			,SCRIPT_ID,MB_S["MB_YESNO"] + MB_S["MB_ICONQUESTION"])=6)
				Gosub,CreateDefaultHosts
		Else InfoMsg("You do not have a hosts file. You"
						.	" can create a default hosts file at any time"
						.	" with the [Restore Default] button.")	
Return
CreateDefaultHosts:
	Try,FileAppend,% HOSTS_ORIG,% A_WinDir "\System32\drivers\etc\hosts"
	Catch CREATE_DEF_ERR {
		InfoErr("Could not create file:`n`n" A_WinDir 
				.	"\System32\drivers\etc\hosts"
				.	"`n`nfor an unknown reason. Please make sure"
				.	" the folder you are trying to save in is not"
				.	" Read Only.")
		CREATE_DEF_ERR:=""
		Return
	}
	HOSTS_FILE:=New File(HOSTS_DIR.file "\hosts")
	Gosub,ShowRWS
	InfoMsg(A_WinDir "\System32\drivers\etc\hosts"
			.	"`nwas created successfully.")
Return
ShowRWS:
	HOSTS_FILE.set()
	SB_SetText(HOSTS_FILE.file?HOSTS_FILE.file " is currently : ":"No hosts file found.",1)
	SB_SetIcon("shell32.dll",(HOSTS_FILE.rws="W" Or !HOSTS_FILE.file)?78:212,2)
	SB_SetText(  HOSTS_FILE.file?((HOSTS_FILE.rws="W")
					?"Writable":"Read Only")
					:"Not Found",2)
Return
EnterFile:
	Sleep,100
	ControlSetText,Edit1,% HOSTS_FILE.file "_" Time(,"MM-dd-yyyy_HH-mm-ss") ".bak"
				,ahk_class #32770
Return
Replace:
	FileSelectFile,ReplaceFile,3,% HOSTS_DIR.file,% "Select file to replace your "
								.	"current hosts file:"
								,	Any Plain Text File (*.*)
	If ReplaceFile {
		replace_obj:=FileOpen(ReplaceFile,"r")
		test_length:=replace_obj.length
		If HOSTS_FILE.ro
			HOSTS_FILE.SetAttrib(HOSTS_FILE.file,"-R")
		old_obj:=FileOpen(A_WinDir "\System32\drivers\etc\hosts",5)
		old_obj.Write(replace_obj.Read())
		replace_obj.Close()
		old_obj.Close()
		If ((success_test_obj:=FileOpen(A_WinDir "\System32\drivers\etc\hosts"
										,	"r").length)=test_length){
			InfoMsg("Your hosts file was replaced successfully.")
		} Else InfoErr("Your hosts file was not replaced."
						.	"`nIs your hosts file in use by another program?`n" IN_USE_MSG)
		success_test_obj.Close()
		If IsObject(HOSTS_FILE)
			HOSTS_FILE.set()
		Else
			HOSTS_FILE:=New File(A_WinDir "\System32\drivers\etc\hosts")
		If HOSTS_FILE.rw
			HOSTS_FILE.SetAttrib(HOSTS_FILE.file,"+R")
		ReplaceFile:=success_test_obj:=old_obj:=replace_obj:=test_length:=""
	}	Else {
			SB_SetText("No file was selected to replace your hosts file.")
			InfoMsg("No file was selected to replace your hosts file.")
	}
Return
Restore:
	If (MSGBOX.Display(TTL_NFO,"Would you like to restore your hosts file to default?"
						,SCRIPT_ID,MB_S["MB_YESNO"] + MB_S["MB_ICONQUESTION"])=6){
		If HOSTS_FILE.file {
			If HOSTS_FILE.ro {
				If HOSTS_FILE.SetAttrib(HOSTS_FILE.file,"-R")
					Gosub,WriteReplaceRoHosts
				Else {
					InfoErr("Your hosts file was not set to Read/Write and could not be restored."
							.	"`nIs your hosts file in use by another program?`n" IN_USE_MSG)
					Return
				}
			} 	Else Gosub,WriteReplaceRoHosts
		}	Else Gosub,CreateDefaultHosts
	}
Return
WriteReplaceRoHosts:
	If write_hosts_obj:=FileOpen(HOSTS_FILE.file,5) {
		write_hosts_obj.Write(HOSTS_ORIG)
		obj_len_test:=write_hosts_obj.length
		write_hosts_obj.Close()					
		If (obj_len_test=824)
			InfoMsg("Your hosts file was restored to default successfully.")
		Else {
			InfoErr("Your hosts file was not restored to default."
					.	"`nIs your hosts file in use by another program?`n" IN_USE_MSG)
			Return
		}
		If ! HOSTS_FILE.SetAttrib(HOSTS_FILE.file,"+R")
			InfoErr("Your hosts file was not set to Read Only."
					.	"`nIs your hosts file in use by another program?`n" IN_USE_MSG)
		obj_len_test:=""
		HOSTS_FILE.set()
	}
Return
ToggleStatus:
	NO_INPUT.on()
	If STATUS_TOGGLE.toggle() {
		SB_SetText("Checking...",2)
		GuiControl,,StatusButtonVar,Hide &Status
		SetTimer,FadeInStatus,-53
		GuiControl,Show,StatusVar
		Gui,Show,AutoSize,%TITLE%
		SetTimer,Progress,-59
	} Else {
		GuiControl,,StatusButtonVar,Show &Status
		Fade(254,0,1,16,"ahk_id " StatusHwnd)
		WinSet,Transparent,Off,ahk_id %StatusHwnd%
		GuiControl,Hide,StatusVar
	}
	Gui,Show,AutoSize,%TITLE%
	NO_INPUT.off()
Return
Progress:
	NO_INPUT.on()
	Loop,100
		{
			WinSet,Transparent,Off,ahk_id %StatusHwnd%
			SB_SetProgress(A_Index,2)
		}
	SB_SetProgress(0,2)
	HOSTS_FILE.set()
	Gosub,ShowRWS
	NO_INPUT.off()
Return
FadeInStatus:
	noinput:=1
	Fade(1,255,1,8,"ahk_id " StatusHwnd)
	Gui,Show,AutoSize,%TITLE%
	noinput:=0
Return
CheckCRC:
	If (INIT_CRC_CHECK!=FileCRC32(A_ScriptFullPath)) {
		; Reload() ; Only for debug on save
		InfoErr("This file is not the same as it was at runtime.`n It has"
			.	" been tampered with and will now exit.")
		ExitApp
	}
Return
Reload:
	Fade(254,0,2,16,"ahk_id " SCRIPT_ID)
	Reload()
GuiClose:
Exit:
	ExitApp