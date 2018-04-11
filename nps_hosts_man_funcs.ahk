FileCRC32(sFile="",cSz=4){ ; by SKAN www.autohotkey.com/community/viewtopic.php?t=64211
	cSz := (cSz<0||cSz>8) ? 2**22 : 2**(18+cSz), VarSetCapacity( Buffer,cSz,0 ) ; 10-Oct-2009
	hFil := DllCall( "CreateFile", Str,sFile,UInt,0x80000000, Int,3,Int,0,Int,3,Int,0,Int,0 )
	IfLess,hFil,1, Return,hFil
	hMod := DllCall( "LoadLibrary", Str,"ntdll.dll" ), CRC32 := 0
	DllCall( "GetFileSizeEx", UInt,hFil, UInt,&Buffer ),    fSz := NumGet( Buffer,0,"Int64" )
	Loop % ( fSz//cSz + !!Mod( fSz,cSz ) )
		DllCall( "ReadFile", UInt,hFil, UInt,&Buffer, UInt,cSz, UIntP,Bytes, UInt,0 )
		, CRC32 := DllCall( "NTDLL\RtlComputeCrc32", UInt,CRC32, UInt,&Buffer, UInt,Bytes, UInt )
	DllCall( "CloseHandle", UInt,hFil )
	SetFormat, Integer, % SubStr( ( A_FI := A_FormatInteger ) "H", 0 )
	CRC32 := SubStr( CRC32 + 0x1000000000, -7 ), DllCall( "CharUpper", Str,CRC32 )
	SetFormat, Integer, %A_FI%
	Return CRC32, DllCall( "FreeLibrary", UInt,hMod )
}
RunAsAdmin(file,argV*){
	If FileExist(file){
		If IsObject(argV)
			For idx, param in argV
				params.=" " """" param """"
		If ! A_IsAdmin {
			Try, Run *RunAs %file% %params%
			Catch
				Return 0
			If (file=A_ScriptFullPath Or file=A_ScriptName)
				ExitApp
			Return 1
		}
	}
}
IsOrigHosts(){
	Return (FileCRC32(A_WinDir "\System32\drivers\etc\hosts")="259FD3A9")
}
SetTrans(trans:=255,win*){
	If win:=WinExist(win[1],win[2],win[3],win[4]) {
		l:= DllCall("GetWindowLong", "Uint", win, "Int", -20)
		DllCall("SetWindowLong", "UInt", win, "Int", -20, "UInt", l|0x00080000)
		Return DllCall("SetLayeredWindowAttributes"
						,"uint",win,"uint",0
						,"uchar",trans,"uint",2)
	}
}
Fade(start:=0,stop:=255,delay:=0,speed:=1,win*){
	If id:=WinExist(win[1],win[2],win[3],win[4]){
		For idx, num in range(start,stop,speed){
			If delay
				Sleep(delay)
			SetTrans(num,"ahk_id " id)
		}
	}
}
TempFade(win,fadeTo:=0,wait:=3000,delay:=0,speed:=1){
		Fade(254,fadeTo,delay,speed,"ahk_id " win)
		Sleep(wait)
		Fade(fadeTo+1,,delay,speed,"ahk_id " win)
}
range(from,to,step:=1){
    range:={}
    if (from<to)
        While (from<=to){
			range.Push(from)
			from+=step
		}
    else
        While (from>=to){
			range.Push(from)
			from-=step
		}
    return range
}
Sleep(time:=0){
	DllCall("Sleep","UInt",time)
}
MouseOver(x1,y1,x2,y2,coordmode:="Screen"){
	CoordMode,Mouse,%coordmode%
	MouseGetPos,_x,_y
	Return (_x>=x1 AND _x<=x2 AND _y>=y1 AND _y<=y2)
}
GetControls(title,control:=0,posvar:=0){
	If (control && posvar)
		{
			namenum:=EnumVarName(control)
			ControlGetPos,x,y,w,h,%control%,%title%
			pos:=(posvar == "X")?x
			:(posvar == "Y")?y
			:(posvar == "W")?w
			:(posvar == "H")?h
			:(posvar == "X2")?x+w
			:(posvar == "Y2")?Y+H
			:0
			Globals.SetGlobal(namenum posvar,pos)
			Return pos
		}
	Else If !(control && posvar)
		{
			WinGet,a,ControlList,%title%
			Loop,Parse,a,`n
				{
					namenum:=EnumVarName(A_LoopField)
					If namenum
						{
							ControlGetPos,x,y,w,h,%A_LoopField%,%title%
							Globals.SetGlobal(namenum "X",x)
							Globals.SetGlobal(namenum "Y",y)
							Globals.SetGlobal(namenum "W",w)
							Globals.SetGlobal(namenum "H",h)
							Globals.SetGlobal(namenum "X2",x+w)
							Globals.SetGlobal(namenum "Y2",y+h)				
						}
				}
			Return a
		}
}
EnumVarName(control){
	name:=InStr(control,"msctls_p")?"MP"
	:InStr(control,"Static")?"S"
	:InStr(control,"Button")?"B"
	:InStr(control,"Edit")?"E"
	:InStr(control,"ListBox")?"LB"
	:InStr(control,"msctls_u")?"UD"
	:InStr(control,"ComboBox")?"CB"
	:InStr(control,"ListView")?"LV"
	:InStr(control,"SysTreeView")?"TV"
	:InStr(control,"SysLink")?"L"
	:InStr(control,"msctls_h")?"H"
	:InStr(control,"SysDate")?"TD"
	:InStr(control,"SysMonthCal")?"MC"
	:InStr(control,"msctls_t")?"SL"
	:InStr(control,"msctls_s")?"SB"
	:InStr(control,"327701")?"AX"
	:InStr(control,"SysTabC")?"T"
	:0
	num:=(name == "MP")?SubStr(control,18)
	:(name == "S")?SubStr(control,7)
	:(name == "B")?SubStr(control,7)
	:(name == "E")?SubStr(control,5)
	:(name == "LB")?SubStr(control,8)
	:(name == "UD")?SubStr(control,15)
	:(name == "CB")?SubStr(control,9)
	:(name == "LV")?SubStr(control,14)
	:(name == "TV")?SubStr(control,14)
	:(name == "L")?SubStr(control,8)
	:(name == "H")?SubStr(control,16)
	:(name == "TD")?SubStr(control,18)
	:(name == "MC")?SubStr(control,14)
	:(name == "SL")?SubStr(control,18)
	:(name == "SB")?SubStr(control,19)
	:(name == "AX")?SubStr(control,5)
	:(name == "T")?SubStr(control,16)
	:0
	Return name num
}

WM_MOUSEMOVE(){
	Global
	If MouseOver(L1X,L1Y,L1X2,L1Y2,"Client")
		SetTimer,LinkTT,-1000
	If MouseOver(S8X,S8Y,S8X2,S8Y2,"Client")
		SetTimer,RWTT,-1000
}
KillTT:
	ToolTip,,,,20
Return
LinkTT:
	If MouseOver(L1X,L1Y,L1X2,L1Y2,"Client") {
		ToolTip,Find more of my AutoHotkey scripts @ GitHub...,,,20
		SetTimer,KillTT,-1250
	}
Return
RWTT:
	If MouseOver(S8X,S8Y,S8X2,S8Y2,"Client") {
		ToolTip,Change Read/Write state of the hosts file...,,,20
		SetTimer,KillTT,-1250
	}
Return
WM_LBUTTONDOWN(){
	Global
	If WinActive("ahk_id " SCRIPT_ID) {
		If MouseOver(S1X,S1Y,S1X2,S1Y2,"Client")
			PostMessage, 0xA1, 2,,,ahk_id %SCRIPT_ID%
		If MouseOver(MP2X,MP7Y,MP6X2,MP6Y2,"Client"){
			Fade(254,0,2,16,"ahk_id " SCRIPT_ID)
			WinMinimize,ahk_id %SCRIPT_ID%
			SetTrans(255,"ahk_id " SCRIPT_ID)
		}
		If MouseOver(MP7X,MP7Y,MP15X2,MP15Y2,"Client") {
			Fade(254,0,2,8,"ahk_id " SCRIPT_ID)
			Gosub,GuiClose
		}
		If (MouseOver(S3X,S3Y,S3X2,S3Y2,"Client") And ! NO_INPUT.state)
			Gosub,Backup
		If (MouseOver(S4X,S4Y,S4X2,S4Y2,"Client") And ! NO_INPUT.state)
			Gosub,Replace
		If (MouseOver(S5X,S5Y,S5X2,S5Y2,"Client") And ! NO_INPUT.state)
			Gosub,Restore
		If (MouseOver(S6X,S6Y,S6X2,S6Y2,"Client") And ! NO_INPUT.state)
			Gosub,Edit
		If (MouseOver(S7X,S7Y,S7X2,S7Y2,"Client") And ! NO_INPUT.state)
			Gosub,ToggleStatus
		If (MouseOver(S8X,S8Y,S8X2,S8Y2,"Client") And ! NO_INPUT.state)
			Gosub,ToggleRW
	}
}
CloseButton(x,y,lcolor,dcolor,subWin:="",small:=False){
	Global
	Local big
	small:=small?3:4
	big:=small*3
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% x%x% y%y% w%small% h%small% vClose1, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% y+0 x+0 w%small% h%small% vClose2, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% y+0 x+0 w%small% h%small% vClose3, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% y+0 xp-%small% w%small% h%small% vClose4, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% y+0 xp-%small% w%small% h%small% vClose5, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% yp-%big% xp+%big% w%small% h%small% vClose6, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% yp-%small% x+0 w%small% h%small% vClose7, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% yp+%big% xp-%small% w%small% h%small% vClose8, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% y+0 x+0 w%small% h%small% vClose9, 100
}
MinButton(x,y,lcolor,dcolor,subWin:="",small:=False){
	Global
	Local big
	small:=small?3:4
	big:=small*3
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% x%x% y%y% w%small% h%small% vMin1, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% yp x+0 w%small% h%small% vMin2, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% yp x+0 w%small% h%small% vMin3, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% yp x+0 w%small% h%small% vMin4, 100
	Gui, %subWin%Add, Progress, Background%lcolor% c%dcolor% yp x+0 w%small% h%small% vMin5, 100
}
GuiButton(title,txtvar,prgssvar,buttonHwnd,bTxtHwnd,subWin:="",color:="0x1D1D1D",border:="0x1D1D1D",x:="+0",y:="+0",w:="",h=""){ 
	Global
	%txtvar%:=title
	%prgssvar%:=100
	Gui,%subWin%Add,Progress,v%prgssvar% x%x% y%y% w%w% h%h% Background%border% c%color% Hwnd%buttonHwnd%,100
	Gui,%subWin%Add,Text,w%w% h%h% xp yp Center +BackgroundTrans 0x200 v%txtvar% Hwnd%bTxtHwnd%,%title%
}
Time(time:="",format:=""){
	FormatTime,vTime,%time%,%format%
	Return vTime
}
SetWinPos(winId,msgs*){
	If ! WinExist("ahk_id " winId)
		Return
	flag:=msgs[6]?msgs[6]:0x4000
	Return DllCall("SetWindowPos"
				, "UInt",winId
				, "UInt", msgs[1]?msgs[1]:""
				, "Int", msgs[2]?msgs[2]:""
				, "Int", msgs[3]?msgs[3]:""
				, "Int", msgs[4]?msgs[4]:""
				, "Int", msgs[5]?msgs[5]:""
				, "UInt", flag) 
}
Reload(params*){
	If params.MaxIndex()
		For idx, item in params
			param.=" " """" item """"
	Try,Run,%A_ScriptFullPath% %param%
	Catch
		Return
	ExitApp
}
DecToHex(num){
	If num Is Not Number
		Return
	restore:=A_FormatInteger
	SetFormat,IntegerFast,H
	num+=0
	SetFormat,Integer,%restore%
	Return num
}
HiLoBytes(bytes,array:=0){
	Return	!	array
			?	{"High":(bytes>>16) & 0xffff,"Low":bytes & 0xffff}
			:	[(bytes>>16) & 0xffff,bytes & 0xffff]
}
WM_HELP(){
	Global
	MSGBOX.Display(TITLE " Help",HELP_MSG
					,SCRIPT_ID,	MB_S["MB_OK"]
					+	MB_S["MB_ICONINFORMATION"]
					+	MB_S["MB_TASKMODAL"])
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Classes                                                                               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Class toggle {
	__New(init:=0){
		this.state:=!init?False:True
	}
	toggle(){
		Return this.state:=!this.state
	}
	off(){
		Return !(this.state:=False)
	}
	on(){
		Return this.state:=True
	}
}
Class Globals { ; my favorite way to set and retrive global tions. Good for
	SetGlobal(name,value=""){ ; setting globals from other functions
		Global
		%name%:=value
		Return
	}
	GetGlobal(name){	
		Global
		Local var:=%name%
		Return var
	}
}