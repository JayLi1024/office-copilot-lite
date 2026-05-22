' Office Copilot Lite - 兜底安装入口
' 双击此文件,通过 WScript 调用 cmd 启动 install.bat
' 用途:如果用户机器 .bat 关联被某个编辑器改坏了,可以用这个绕过
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
sh.Run "cmd.exe /c """ & scriptDir & "\install.bat""", 1, True
