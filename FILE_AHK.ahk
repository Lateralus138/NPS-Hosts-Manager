Class File {
	__New(file){
		If (this.file:=FileExist(file)?file:"")
			this.set()
	}
	set(){
		this.attrib:=this.GetAttrib(this.file) ; Get full attributes for a file
		this.rws:=this.GetReadWrite(this.file) ; Get Read/Write state setting to "R" & "W" respectively
		this.ro:=(this.rws="R") ; Enumerate boolean state for Read Only
		this.rw:=(this.rws="W") ; Enumerate boolean state for Read/Write
		this.path:=this.SplitPath(this.file) ; create associative array from file path
		this.type:=this.FileOrDir(this.file)
		; If (this.type="F") {
			; this.lines:=this.toLines(this.file) ; get an array of the files lines
			; VarSetCapacity(this.string,16)
			; this.string:=this.toLines(this.file,1) ; full file into var
		; }
		Return this.file
	}
	GetAttrib(file){
		If FileExist(file){
			FileGetAttrib,_attrib_,%file%
			Return _attrib_
		}
	}
	SetAttrib(file,attrib){
		If FileExist(file){
			Try FileSetAttrib,%attrib%,%file%
			Catch
				Return 0
			If (file=this.file){
				this.attrib:=this.GetAttrib(this.file) ; Get full attributes for a file
				this.rws:=this.GetReadWrite(this.file) ; Get Read/Write state setting to "R" & "W" respectively
				this.ro:=(this.rws="R") ; Enumerate boolean state for Read Only
				this.rw:=(this.rws="W") ; Enumerate boolean state for Read/Write
			}
			Return 1
		}
	}
	GetReadWrite(file){
		Return FileExist(file)
		?(InStr(this.GetAttrib(file),"r")?"R":"W")
		:""
	}
	SplitPath(file){
		If FileExist(file){
			SplitPath,% file,fn,fd,fx,fnx,fdr
			Return {"name":fn,"dir":fd,"exe":fx,"noexe":fnx,"drive":fdr}
		}
	}
	toLines(file,string:=0){
		If FileExist(file){
				Loop,Read,% file
					{
						If ! string {
							_lines:=IsObject(_lines)?_lines:[]
							_lines.Push(A_LoopReadLine)
						}
						Else
							_lines.=(_lines?"`n" A_LoopReadLine:A_LoopReadLine)
					}
			Return _lines
		}
	}
	FileOrDir(file){
		If FileExist(file)
			Return InStr(FileExist(File),"D")?"D":"F"
	}
}