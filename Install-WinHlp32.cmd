@echo off
setlocal EnableExtensions
setlocal EnableDelayedExpansion

set ScriptDir=%~dp0
set ScriptDir=%ScriptDir:~0,-1%

echo +----------------------------------------------------------------------------+
echo ^| Windows Help program ^(WinHlp32^) installer                                  ^|
echo ^|                                                                            ^|
echo ^| Revision 1                                                                 ^|
echo ^| July 21st, 2020                                                            ^|
echo ^| Copyright ^(c^) 2020 Wrong-Code. All rights reserved.                        ^|
echo ^|                                                                            ^|
echo ^| Based on the original script by Komeil Bahmanpour.                         ^|
echo +----------------------------------------------------------------------------+
echo.

:: ---------------------------------------------------------------------------
:: Check if running as an administrator

"%SystemRoot%\System32\net.exe" session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo This script must be run with administrative privileges.
  goto :ERROR
)

:: ---------------------------------------------------------------------------
:: Check if wget is available

if not exist "%ScriptDir%\wget.exe" (
  echo wget.exe is not available. Please download it from
  echo.
  echo   https://eternallybored.org/misc/wget/releases/wget-1.20.3-win32.zip
  echo.
  echo ^(or use a newer/different build^) and place it in this script's directory.
  goto :ERROR
)

:: ---------------------------------------------------------------------------
:: Windows version detection

echo Setup is detecting the Windows version...

ver | "%SystemRoot%\System32\findstr.exe" /il "10\.0\." >nul
if %ERRORLEVEL% EQU 0 (
  echo Microsoft Windows 10 / Windows Server 2016/2019 detected.
  set WindowsVersion=10_2016_2019

  rem No direct support for Windows 10 / 2016 / 2019. We will use the KB for
  rem Windows 8.1 / 2012 R2 to hack in the needed files.

  if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
    set URL=https://download.microsoft.com/download/A/5/6/A5651A53-2487-43C6-835A-744EB9C72579/Windows8.1-KB917607-x64.msu
  ) else (
    set URL=https://download.microsoft.com/download/3/8/C/38C68F7C-1769-4089-BF21-3F5D8A556CBC/Windows8.1-KB917607-x86.msu
  )
  goto :DownloadKB
)

ver | "%SystemRoot%\System32\findstr.exe" /il "6\.3\." >nul
if %ERRORLEVEL% EQU 0 (
  echo Microsoft Windows 8.1 / Windows Server 2012 R2 detected.
  set WindowsVersion=8.1_2012R2
  if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
    set URL=https://download.microsoft.com/download/A/5/6/A5651A53-2487-43C6-835A-744EB9C72579/Windows8.1-KB917607-x64.msu
  ) else (
    set URL=https://download.microsoft.com/download/3/8/C/38C68F7C-1769-4089-BF21-3F5D8A556CBC/Windows8.1-KB917607-x86.msu
  )
  goto :DownloadKB
)

ver | "%SystemRoot%\System32\findstr.exe" /il "6\.2\." >nul
if %ERRORLEVEL% EQU 0 (
  echo Microsoft Windows 8 / Windows Server 2012 detected.
  set WindowsVersion=8_2012
  if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
    set URL=https://download.microsoft.com/download/2/0/0/200C7BAF-48D7-4C0A-9C12-088CBA3DB13B/Windows8-RT-KB917607-x64.msu
  ) else (
    set URL=https://download.microsoft.com/download/2/0/0/200C7BAF-48D7-4C0A-9C12-088CBA3DB13B/Windows8-RT-KB917607-x86.msu
  )
  goto :DownloadKB
)

ver | "%SystemRoot%\System32\findstr.exe" /il "6\.1\." >nul
if %ERRORLEVEL% EQU 0 (
  echo Microsoft Windows 7 / Windows Server 2008 R2 detected.
  set WindowsVersion=7_2008R2
  if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
    set URL=https://download.microsoft.com/download/9/A/8/9A8FCFAA-78A0-49F5-8C8E-4EAE185F515C/Windows6.1-KB917607-x64.msu
  ) else (
    set URL=https://download.microsoft.com/download/9/A/8/9A8FCFAA-78A0-49F5-8C8E-4EAE185F515C/Windows6.1-KB917607-x86.msu
  )
  goto :DownloadKB
)

ver | "%SystemRoot%\System32\findstr.exe" /il "6\.0\." >nul
if %ERRORLEVEL% EQU 0 (
  echo Microsoft Windows Vista / Windows Server 2008 detected.
  set WindowsVersion=Vista_2008
  if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
    set URL=https://download.microsoft.com/download/4/d/5/4d56f3c4-e65a-402b-826f-b87ef81fc31c/Windows6.0-KB917607-x64.msu
  ) else (
    set URL=https://download.microsoft.com/download/4/d/5/4d56f3c4-e65a-402b-826f-b87ef81fc31c/Windows6.0-KB917607-x86.msu
  )
  goto :DownloadKB
)

echo Unsupported Windows version. This script must be run under one of
echo the following operating systems:
echo.
echo * Microsoft Windows 10    / Windows Server 2016/2019
echo * Microsoft Windows 8.1   / Windows Server 2012 R2
echo * Microsoft Windows 8     / Windows Server 2012
echo * Microsoft Windows 7     / Windows Server 2008 R2
echo * Microsoft Windows Vista / Windows Server 2008
goto :ERROR

:: ---------------------------------------------------------------------------
:: Download the Windows KB

:DownloadKB
echo Downloading the Windows KB...
"%ScriptDir%\wget.exe" -q -O "%TEMP%\winhlp.wusa" "%URL%"
if not exist "%TEMP%\winhlp.wusa" (
  echo Could not download the Windows KB from %URL%
  goto :ERROR
)

:: ---------------------------------------------------------------------------
:: Preparing for the installation

echo Terminating all the running instances of WinHlp32...
"%SystemRoot%\System32\taskkill.exe" /f /im WinHlp32.exe /t >nul 2>&1

:: ---------------------------------------------------------------------------
:: Apply the KB (except on Windows 10 / 2016 / 2019)

if %WindowsVersion% NEQ 10_2016_2019 (
  echo Applying the Windows KB...
  "%SystemRoot%\System32\wusa.exe" "%TEMP%\winhlp.wusa" /quiet /norestart
  if %ERRORLEVEL% NEQ 0 (
    goto :ERROR
  )
  goto :EXIT
)

:: ---------------------------------------------------------------------------
:: On Windows 10 / 2016 / 2019, we need to extract the .cab from the .wusa
:: file, and then expand it

echo Expanding the .cab file...
mkdir "%TEMP%\winhlp32_expand" >nul 2>&1
"%SystemRoot%\System32\expand.exe" -F:Windows*.cab "%TEMP%\winhlp.wusa" "%TEMP%\winhlp32_expand" >nul 2>&1
for %%f in ("%TEMP%\winhlp32_expand\*.cab") do (
  "%SystemRoot%\System32\expand.exe" -R -F:* "%%f" "%TEMP%\winhlp32_expand" >nul 2>&1
)

:: Get the MUI language

for /f "delims=" %%i in ('wmic os get MUILanguages ^| find "{"') do set MuiLang=%%i
for /f delims^=^"^ tokens^=2 %%i in ('echo %MuiLang%') do set MuiLang=%%i

:: Find the proper EXE/MUI source directories

for /f "delims=" %%f in ('dir /ad /b "%TEMP%\winhlp32_expand\%PROCESSOR_ARCHITECTURE%*" ^| find /v "resources"') do (
  set SrcExeDir=%TEMP%\winhlp32_expand\%%f
)
for /f "delims=" %%f in ('dir /ad /b "%TEMP%\winhlp32_expand\%PROCESSOR_ARCHITECTURE%*%MuiLang%*"') do (
  set SrcMuiDir=%TEMP%\winhlp32_expand\%%f
)

:: ---------------------------------------------------------------------------
:: Hack in the extracted files

echo Installing the WinHlp32 system files...
for %%f in ("%SrcExeDir%\*.*") do (
  echo   %%~nxf
  set sysfile=%SystemRoot%\%%~nxf
  rem Take care of the existing WinHlp32 stubs
  if exist "!sysfile!" (
    "%SystemRoot%\System32\takeown.exe" /f "!sysfile!" >nul 2>&1
    "%SystemRoot%\System32\icacls.exe" "!sysfile!" /grant "%UserName%":F >nul 2>&1
  )
  rem Replace the system file
  "%SystemRoot%\System32\xcopy.exe" "%%f" "%SystemRoot%" /r /y /h /q >nul 2>&1
  if %ERRORLEVEL% NEQ 0 goto :COPYERROR
)

for %%f in ("%SrcMuiDir%\*.*") do (
  echo   %MuiLang%\%%~nxf
  set sysfile=%SystemRoot%\%MuiLang%\%%~nxf
  rem Take care of the existing WinHlp32 stubs
  if exist "!sysfile!" (
    "%SystemRoot%\System32\takeown.exe" /f "!sysfile!" >nul 2>&1
    "%SystemRoot%\System32\icacls.exe" "!sysfile!" /grant "%UserName%":F >nul 2>&1
  )
  rem Replace the system file
  "%SystemRoot%\System32\xcopy.exe" "%%f" "%SystemRoot%\%MuiLang%" /r /y /h /q >nul 2>&1
  if %ERRORLEVEL% NEQ 0 goto :COPYERROR
)

echo Fixing the ACL...
"%SystemRoot%\System32\icacls.exe" "%SystemRoot%" /restore "%ScriptDir%\WinHlp32_Exe_ACL.txt" /c >nul 2>&1
"%SystemRoot%\System32\icacls.exe" "%SystemRoot%\%MuiLang%" /restore "%ScriptDir%\WinHlp32_MUI_ACL.txt" /c >nul 2>&1

echo Updating the registry...
"%SystemRoot%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\WinHelp" /v "AllowProgrammaticMacros" /t REG_DWORD /d "0x00000001" /f >nul 2>&1
"%SystemRoot%\System32\reg.exe" add "HKLM\SOFTWARE\Microsoft\WinHelp" /v "AllowIntranetAccess" /t REG_DWORD /d "0x00000001" /f >nul 2>&1
if %PROCESSOR_ARCHITECTURE% EQU AMD64 (
  "%SystemRoot%\System32\reg.exe" add "HKLM\SOFTWARE\Wow6432Node\Microsoft\WinHelp" /v "AllowProgrammaticMacros" /t REG_DWORD /d "0x00000001" /f >nul 2>&1
  "%SystemRoot%\System32\reg.exe" add "HKLM\SOFTWARE\Wow6432Node\Microsoft\WinHelp" /v "AllowIntranetAccess" /t REG_DWORD /d "0x00000001" /f >nul 2>&1
)

echo Done.
goto :EXIT

:: ---------------------------------------------------------------------------
:: Error management

:COPYERROR
echo An error occurred while installing this file.

:ERROR
echo 
pause
exit /b 1

:EXIT
exit /b 0
