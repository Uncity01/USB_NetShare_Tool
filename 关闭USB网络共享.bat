@echo off
chcp 936 >nul
setlocal
title 关闭USB网络共享

rem ============================================================
rem  关闭 USB 网络共享
rem  - 自动扫描所有已授权 adb 设备，无需输入序列号
rem  - 不生成任何配置文件，不保存任何手机设备信息
rem  - 优先命令：svc usb setFunctions none
rem    失败自动降级：service call connectivity 30 i32 0
rem ============================================================

set "SCRIPT_DIR=%~dp0"
set "ADB_EXE=%SCRIPT_DIR%adb\adb.exe"

rem ---- 检测是否以 SYSTEM 身份运行（计划任务自动触发场景），跳过弹窗与暂停 ----
set "IS_SYSTEM=0"
whoami /user 2>nul | findstr /i "S-1-5-18" >nul
if not errorlevel 1 set "IS_SYSTEM=1"

echo ============================================================
echo             关闭 USB 网络共享
echo ============================================================
echo.

rem ---------- 1. 环境自检 ----------
echo [1/4] 检查 adb 环境...
if not exist "%ADB_EXE%" (
    echo.
    echo [错误] 未找到 adb.exe ！
    echo 请自行下载 platform-tools 并解压到：
    echo   %SCRIPT_DIR%adb\
    echo 官方下载：https://developer.android.com/tools/releases/platform-tools
    echo 国内镜像：https://mirrors.tuna.tsinghua.edu.cn/Android/repository/platform-tools/
    echo.
    if "%IS_SYSTEM%"=="0" msg * "未找到 adb.exe，请先将 platform-tools 解压到项目 adb 子文件夹后再运行！"
    if "%IS_SYSTEM%"=="0" pause
    exit /b 1
)
if not exist "%SCRIPT_DIR%adb\AdbWinApi.dll" (
    echo.
    echo [错误] platform-tools 文件不完整：缺少 AdbWinApi.dll
    echo 请重新完整解压 platform-tools。
    if "%IS_SYSTEM%"=="0" msg * "platform-tools 文件不完整，请重新完整解压后再运行！"
    if "%IS_SYSTEM%"=="0" pause
    exit /b 1
)
echo [OK] adb 环境检查通过：%ADB_EXE%
echo.

rem ---------- 2. 启动 adb server ----------
echo [2/4] 启动 adb server...
"%ADB_EXE%" start-server >nul 2>&1
echo [OK]
echo.

rem ---------- 3. 扫描已授权设备 ----------
echo [3/4] 扫描已授权 adb 设备...
echo.
set "AUTH_COUNT=0"
set "RAW_COUNT=0"
for /f "skip=1 tokens=1,2" %%i in ('"%ADB_EXE%" devices') do (
    if not "%%i"=="" (
        set /a RAW_COUNT+=1
        if "%%j"=="device" (
            set /a AUTH_COUNT+=1
            echo   [设备] %%i    状态：已授权
        ) else (
            echo   [设备] %%i    状态：%%j（未授权/离线，已跳过）
        )
    )
)
echo.
if %RAW_COUNT% EQU 0 (
    echo [提示] 未检测到任何 adb 设备。
    echo.
    call :troubleshoot
    if "%IS_SYSTEM%"=="0" pause
    exit /b 1
)
if %AUTH_COUNT% EQU 0 (
    echo [提示] 检测到 %RAW_COUNT% 台设备，但均未授权。
    echo 请解锁屏幕并重新插拔数据线，在手机上允许 USB 调试授权。
    echo.
    call :troubleshoot
    if "%IS_SYSTEM%"=="0" pause
    exit /b 1
)
echo [OK] 已授权设备 %AUTH_COUNT% 台，开始关闭 USB 网络共享...
echo.

rem ---------- 4. 逐台执行关闭命令 ----------
echo [4/4] 执行关闭命令...
echo.
set "OK_COUNT=0"
for /f "skip=1 tokens=1,2" %%i in ('"%ADB_EXE%" devices') do (
    if "%%j"=="device" (
        echo   ==========================================
        echo   设备：%%i
        echo   ==========================================
        echo   [命令] svc usb setFunctions none
        "%ADB_EXE%" -s %%i shell svc usb setFunctions none >nul 2>&1
        if errorlevel 1 (
            echo   [提示] 优先命令失败，降级备选：service call connectivity 30 i32 0
            "%ADB_EXE%" -s %%i shell service call connectivity 30 i32 0 >nul 2>&1
            if errorlevel 1 (
                echo   [失败] 设备 %%i 关闭失败，请检查连接状态后重试。
            ) else (
                echo   [OK] 设备 %%i 已通过备选命令关闭。
                set /a OK_COUNT+=1
            )
        ) else (
            echo   [OK] 设备 %%i 已执行关闭命令。
            set /a OK_COUNT+=1
        )
        echo.
    )
)

echo ============================================================
echo   处理完成：成功 %OK_COUNT% 台 / 已授权 %AUTH_COUNT% 台
echo ============================================================
echo.
echo 手机端「USB网络共享」应已关闭。若电脑端 RNDIS 网卡仍存在，
echo 可拔插一次数据线刷新，或在网络连接中手动禁用该网卡。
echo.
if "%IS_SYSTEM%"=="0" pause
exit /b 0

rem ---------- 排错提示 ----------
:troubleshoot
echo ============================================================
echo   未检测到可用的 adb 设备，请逐项排查：
echo ============================================================
echo.
echo   [1] 数据线是否插好？建议换 USB 口、换数据线。
echo   [2] 手机屏幕是否解锁？
echo   [3] 是否开启「开发者选项」（设置→关于手机→连点版本号7次）？
echo   [4] 是否开启「USB 调试」？
echo   [5] 是否开启「USB 调试（安全设置）」？
echo   [6] USB 模式是否为「文件传输 MTP」？（不能仅充电）
echo   [7] 首次连接是否授权？未授权请重新插拔并点「允许」。
echo   [8] 是否开启超级省电模式（会禁用 adb）？
echo   [9] 保持亮屏，避免锁屏休眠切断 adb 通道。
echo   [10] 重新插拔后重试；或 adb kill-server 后再试。
echo ============================================================
exit /b 0
