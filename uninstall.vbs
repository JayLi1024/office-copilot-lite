' Office Copilot Lite - fallback uninstall launcher
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
sh.Run "cmd.exe /c """ & scriptDir & "\uninstall.bat""", 1, True