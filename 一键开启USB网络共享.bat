@echo off
chcp 936 >nul
setlocal
title 一键开启USB网络共享

rem ============================================================
rem  一键开启 USB 网络共享（安卓 USB Tethering / RNDIS）
rem  - 自动扫描所有已授权 adb 设备，无需输入序列号
rem  - 不生成任何配置文件，不保存任何手机设备信息
rem  - 优先命令：svc usb setFunctions rndis,adb
rem    失败自动降级：service call connectivity 30 i32 1
rem ============================================================

set "SCRIPT_DIR=%~dp0"
set "ADB_EXE=%SCRIPT_DIR%adb\adb.exe"

rem ---- 检测是否以 SYSTEM 身份运行（计划任务自动触发场景），跳过弹窗与暂停 ----
set "IS_SYSTEM=0"
whoami /user 2>nul | findstr /i "S-1-5-18" >nul
if not errorlevel 1 set "IS_SYSTEM=1"

echo ============================================================
echo             一键开启 USB 网络共享
echo ============================================================
echo.

rem ---------- 1. 环境自检 ----------
echo [1/4] 检查 adb 环境...
if not exist "%ADB_EXE%" (
    echo.
    echo [错误] 未找到 adb.exe ！
    echo.
    echo 请自行下载 Android platform-tools 并解压到：
    echo   %SCRIPT_DIR%adb\
    echo 确保目录结构为：
    echo   %SCRIPT_DIR%adb\adb.exe
    echo   %SCRIPT_DIR%adb\AdbWinApi.dll
    echo   %SCRIPT_DIR%adb\AdbWinUsbApi.dll
    echo.
    echo 官方下载（需科学上网）：
    echo   https://developer.android.com/tools/releases/platform-tools
    echo 国内镜像：
    echo   https://mirrors.tuna.tsinghua.edu.cn/Android/repository/platform-tools/
    echo.
    if "%IS_SYSTEM%"=="0" msg * "未找到 adb.exe，请先将 platform-tools 解压到项目 adb 子文件夹后再运行！"
    if "%IS_SYSTEM%"=="0" pause
    exit /b 1
)
if not exist "%SCRIPT_DIR%adb\AdbWinApi.dll" (
    echo.
    echo [错误] platform-tools 文件不完整：缺少 AdbWinApi.dll
    echo 请重新完整解压 platform-tools，不要只复制 adb.exe。
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
    echo [提示] 未检测到任何 adb 设备（连未授权的都没有）。
    echo.
    call :troubleshoot
    if "%IS_SYSTEM%"=="0" pause
    exit /b 1
)
if %AUTH_COUNT% EQU 0 (
    echo [提示] 检测到 %RAW_COUNT% 台设备，但均未授权（状态不是 device）。
    echo 请解锁手机屏幕，重新插拔数据线，在手机上点选
    echo 「允许 USB 调试」并勾选「始终允许使用这台计算机」。
    echo.
    call :troubleshoot
    if "%IS_SYSTEM%"=="0" pause
    exit /b 1
)
echo [OK] 已授权设备 %AUTH_COUNT% 台，开始开启 USB 网络共享...
echo.

rem ---------- 4. 逐台执行开启命令 ----------
echo [4/4] 执行开启命令...
echo.
set "OK_COUNT=0"
for /f "skip=1 tokens=1,2" %%i in ('"%ADB_EXE%" devices') do (
    if "%%j"=="device" (
        echo   ==========================================
        echo   设备：%%i
        echo   ==========================================
        echo   [命令] svc usb setFunctions rndis,adb
        "%ADB_EXE%" -s %%i shell svc usb setFunctions rndis,adb >nul 2>&1
        if errorlevel 1 (
            echo   [提示] 优先命令失败，降级备选：service call connectivity 30 i32 1
            "%ADB_EXE%" -s %%i shell service call connectivity 30 i32 1 >nul 2>&1
            if errorlevel 1 (
                echo   [失败] 设备 %%i 开启失败，请检查连接状态后重试。
            ) else (
                echo   [OK] 设备 %%i 已通过备选命令开启。
                set /a OK_COUNT+=1
            )
        ) else (
            echo   [OK] 设备 %%i 已执行开启命令。
            set /a OK_COUNT+=1
        )
        echo.
    )
)

echo ============================================================
echo   处理完成：成功 %OK_COUNT% 台 / 已授权 %AUTH_COUNT% 台
echo ============================================================
echo.
echo 请在手机端确认已开启「USB网络共享」（部分机型会自动弹出）。
echo 电脑端通常会在几秒内识别出新的 RNDIS 网卡（网络连接里出现
echo 新的「远程 NDIS 兼容设备」/「以太网」）。
echo.
echo 若 10 秒内未生效，请尝试：
echo   1. 重新插拔一次数据线（保持手机亮屏）；
echo   2. 在 cmd 中执行：adb kill-server，然后重新运行本脚本。
echo.
if "%IS_SYSTEM%"=="0" pause
exit /b 0

rem ---------- 排错提示 ----------
:troubleshoot
echo ============================================================
echo   未检测到可用的 adb 设备，请逐项排查：
echo ============================================================
echo.
echo   [1] 数据线是否插好？建议换一个 USB 口、换一根数据线。
echo   [2] 手机屏幕是否解锁？锁屏状态 adb 无法连接。
echo   [3] 是否已开启「开发者选项」？
echo       设置 → 关于手机 → 连续点击「版本号」7 次。
echo   [4] 是否已开启「USB 调试」？
echo       设置 → 开发者选项 → USB 调试。
echo   [5] 是否已开启「USB 调试（安全设置）」？
echo       部分机型叫「允许通过 USB 调试修改权限/模拟点击」。
echo   [6] USB 连接模式是否选择「文件传输 MTP」？
echo       插线后下拉通知栏 → USB 连接方式 → 选择 文件传输。
echo       不能选「仅充电」或「反向充电」。
echo   [7] 首次连接是否弹窗「允许 USB 调试」？
echo       请勾选「始终允许使用这台计算机」后点允许；
echo       若之前误选了拒绝：开发者选项 → 撤销 USB 调试授权，
echo       然后重新插拔数据线。
echo   [8] 是否开启了超级省电/极致省电模式？
echo       省电模式会禁用 adb 调试，请关闭。
echo   [9] 国产系统锁屏休眠会切断 adb 通道：
echo       建议在开发者选项开启「不锁定屏幕」或
echo       「充电时保持屏幕唤醒」，运行期间保持亮屏。
echo   [10] 重新插拔数据线后再次运行本脚本；
echo        或在 cmd 中执行 adb kill-server 后再试。
echo   [11] 换一台电脑/换一根线排除硬件问题。
echo ============================================================
exit /b 0
