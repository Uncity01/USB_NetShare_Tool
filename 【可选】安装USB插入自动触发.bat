@echo off
chcp 936 >nul
setlocal
title 安装USB插入自动触发（需管理员权限）

rem ============================================================
rem  安装「USB 插入自动触发」计划任务
rem  触发条件：事件 ID 1006（Microsoft-Windows-Partition/Diagnostic，
rem           USB 存储设备接入事件）
rem  需以管理员身份运行本脚本
rem ============================================================

rem ---------- 检查管理员权限 ----------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 请以「管理员身份」运行本脚本！
    echo.
    echo 操作：右键本文件 → 以管理员身份运行
    echo.
    pause
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "TASK_NAME=USB_NetShare_AutoTrigger"
set "TARGET_BAT=%SCRIPT_DIR%一键开启USB网络共享.bat"
set "EVT_LOG=Microsoft-Windows-Partition/Diagnostic"
set "EVT_QUERY=*[System[Provider[@Name='Microsoft-Windows-Partition/Diagnostic'] and (EventID=1006)]]"

if not exist "%TARGET_BAT%" (
    echo [错误] 未找到主程序：%TARGET_BAT%
    pause
    exit /b 1
)

echo ============================================================
echo   安装 USB 插入自动触发
echo ============================================================
echo.
echo   计划任务名 ：%TASK_NAME%
echo   触发事件   ：事件 ID 1006（USB 设备接入）
echo   执行程序   ：%TARGET_BAT%
echo   运行身份   ：SYSTEM（最高权限，后台静默运行）
echo.

rem ---------- 创建计划任务 ----------
schtasks /create /tn "%TASK_NAME%" /tr "\"%TARGET_BAT%\"" /sc onevent /ec "%EVT_LOG%" /mo "%EVT_QUERY%" /ru SYSTEM /rl highest /f

if %errorlevel% equ 0 (
    echo [OK] 计划任务创建成功！
    echo.
    echo 从现在起，每次插入 USB 存储设备，系统会自动运行主程序开启 USB 网络共享。
    echo 可通过「任务计划程序」→ 任务计划程序库 → %TASK_NAME% 查看或禁用。
) else (
    echo.
    echo [失败] 计划任务创建失败。
    echo 请检查：是否以管理员运行；事件日志服务是否正常。
)
echo.
echo [重要提醒]
echo   1. 国产安卓系统锁屏/休眠会断开 adb 通道：插入后请解锁手机屏幕，
echo      否则自动触发也会失败。
echo   2. 事件 ID 1006 由「分区诊断」日志产生，主要针对 U 盘、移动硬盘等
echo      存储设备；手机以 MTP 文件传输模式接入不一定触发本事件，
echo      自动触发可靠性有限，请以手动双击主程序为主要使用方式。
echo      （备选方案：系统日志 → 来源 Kernel-PnP → 事件 ID 2003，
echo       可在任务计划程序中自行改配。）
echo   3. 卸载方法：以管理员运行「【可选】卸载USB插入自动触发.bat」。
echo.
pause
