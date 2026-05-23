' Office Copilot Lite - fallback install launcher
' Double-click this file to invoke install.bat via cmd through WScript.
' Use case: when .bat association is hijacked by some editor (VS Code / Notepad++ / Sublime).
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
sh.Run "cmd.exe /c """ & scriptDir & "\install.bat""", 1, True