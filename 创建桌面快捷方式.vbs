' 创建桌面快捷方式：USB网络共享-一键开启
' 用法：双击运行本文件即可，无需管理员权限
' 说明：快捷方式指向与本文件同目录下的主程序，可重复运行（覆盖旧快捷方式）

Set fso = CreateObject("Scripting.FileSystemObject")
strScriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
strTarget = strScriptDir & "\一键开启USB网络共享.bat"

If Not fso.FileExists(strTarget) Then
    MsgBox "未找到主程序：" & vbCrLf & strTarget & vbCrLf & vbCrLf & _
           "请确认本 vbs 文件与「一键开启USB网络共享.bat」在同一个文件夹！", _
           vbCritical, "错误"
    WScript.Quit 1
End If

Set oShell = WScript.CreateObject("WScript.Shell")
strDesktop = oShell.SpecialFolders("Desktop")
strLnk = strDesktop & "\USB网络共享-一键开启.lnk"

Set oLink = oShell.CreateShortcut(strLnk)
oLink.TargetPath = strTarget
oLink.WorkingDirectory = strScriptDir
oLink.WindowStyle = 1
oLink.Description = "一键开启安卓USB网络共享"
oLink.IconLocation = strTarget & ",0"
oLink.Save

MsgBox "桌面快捷方式已创建：" & vbCrLf & strLnk, vbInformation, "完成"
