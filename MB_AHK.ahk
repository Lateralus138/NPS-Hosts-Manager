; MsgBox Class for AutoHotkey
Debug(title,text,styles:=0,delim:="|",hwnd*){
	Return New MsgBox(title,text
	,	!hwnd[1]
	?	WinExist(A_ScriptName)
	:	!IsNum(hwnd[1])
	?	WinExist(hwnd[1],hwnd[2],hwnd[3],hwnd[4])
	:	hwnd[1]
	,	styles,delim).Display()
}
IsNum(n){
	Return (n+0)
}
HexToDec(hex){
	chars:="0123456789abcdef"
	If ! sub:=(SubStr(hex,1,2)="0x")
		Return
	newHex:=SubStr(hex,3)
	Loop % StrLen(newHex)
		If !InStr(chars,SubStr(newHex,A_Index,1))
			Return
	Return (SubStr(hex,1,2)="0x")?hex + 0:("0x" hex) + 0
}
LoadLib(lib){
	If FileExist(lib)
		Return DllCall("LoadLibrary","Str",lib,"Ptr")
}
Class MsgBox {
	__New(_title,_msg:="",_hwnd:=0,_styles:="",delim:="|"){	
		this.Owner:=_hwnd
		this.Title:=_title?_title:A_ScriptName
		this.Message:=_msg
		If (_styles!="" And !IsNum(_styles)){
			SetFormat,Integer,H
			hex_array:=[]
			Loop,Parse,_styles,%delim%
				hex_array.Push(HexToDec(this.Styles[A_LoopField]))
			For idx, hex in hex_array
				new+=hex
			this.Style:=new
			SetFormat,Integer,D
		} Else If IsNum(_styles){
			this.Style:=_styles
		} Else this.Style	:=	(	this.Styles["MB_OK"]
							+	this.Styles["MB_ICONINFORMATION"]	)
	}
	Clear(){
		this.Remove("",Chr(255))
		this.SetCapacity(0)
		this.base:=""
		Return ! IsObject(this.base)
	}
	Display(_title:="",_msg:="",_hwnd:="",_styles:=""){
		If lib:=LoadLib(A_WinDir . "\System32\User32.dll"){
			ret:=DllCall("MessageBox"	,"Uint",	_hwnd?_hwnd:this.Owner
										,"Str",		_msg?_msg:this.Message
										,"Str",		_title?_title:this.Title
										,"Uint",	_styles?_styles:this.Style)
			DllCall("FreeLibrary","Ptr",lib)
			Return ret
		}
	}
	Styles:=	{"MB_ABORTRETRYIGNORE":"0x00000002","MB_CANCELTRYCONTINUE":"0x00000006"
				,"MB_HELP":"0x00004000","MB_OK":"0x00000000"
				,"MB_OKCANCEL":"0x00000001","MB_RETRYCANCEL":"0x00000005"
				,"MB_YESNO":"0x00000004","MB_YESNOCANCEL":"0x00000003"
				,"MB_ICONEXCLAMATION":"0x00000030","MB_ICONWARNING":"0x00000030"
				,"MB_ICONINFORMATION":"0x00000040","MB_ICONASTERISK":"0x00000040"
				,"MB_ICONQUESTION":"0x00000020","MB_ICONSTOP":"0x00000010"
				,"MB_ICONERROR":"0x00000010","MB_ICONHAND":"0x00000010"
				,"MB_DEFBUTTON1":"0x00000000","MB_DEFBUTTON2":"0x00000100"
				,"MB_DEFBUTTON3":"0x00000200","MB_DEFBUTTON4":"0x00000300"
				,"MB_APPLMODAL":"0x00000000","MB_SYSTEMMODAL":"0x00001000"
				,"MB_TASKMODAL":"0x00002000","MB_DEFAULT_DESKTOP_ONLY":"0x00020000"
				,"MB_RIGHT":"0x00080000","MB_RTLREADING":"0x00100000"
				,"MB_SETFOREGROUND":"0x00010000","MB_TOPMOST":"0x00040000"
				,"MB_SERVICE_NOTIFICATION":"0x00200000"}
}