@echo off
chcp 936 >nul
setlocal
title 卸载USB插入自动触发（需管理员权限）

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

set "TASK_NAME=USB_NetShare_AutoTrigger"

echo ============================================================
echo   卸载 USB 插入自动触发
echo ============================================================
echo.
echo   计划任务名：%TASK_NAME%
echo.

schtasks /delete /tn "%TASK_NAME%" /f

if %errorlevel% equ 0 (
    echo [OK] 计划任务已删除，USB 插入自动触发已卸载。
) else (
    echo [提示] 删除失败或任务不存在（可能本来就没有安装）。
)
echo.
pause
