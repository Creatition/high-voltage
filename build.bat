@echo off
REM ============================================================================
REM  Timeshot — one-shot Windows build + zip
REM ----------------------------------------------------------------------------
REM  What this does:
REM    1. Runs Godot in headless mode to export a release Windows build.
REM    2. Zips the build folder into builds\Timeshot-<date>.zip using tar.
REM
REM  Prerequisites (do these ONCE before first run):
REM    1. Open the project in Godot 4: timeshot\project.godot
REM    2. Project -> Export -> Add... -> Windows Desktop
REM       (If templates are missing, click "Manage Export Templates" and
REM        download. Without templates the headless export will fail.)
REM    3. Leave the preset name as "Windows Desktop" — or edit EXPORT_PRESET
REM       below to match whatever you named it.
REM    4. Save & close Godot. The project now has an export_presets.cfg.
REM
REM  Usage:
REM    build.bat               -> builds with defaults
REM    build.bat clean         -> deletes prior builds folder, then builds
REM ============================================================================

setlocal enabledelayedexpansion

REM --- Config -----------------------------------------------------------------
REM  Override GODOT_EXE here if Godot isn't on your PATH. Use the FULL path
REM  to the console version of Godot, e.g.:
REM    set "GODOT_EXE=C:\Program Files\Godot\Godot_v4.x-stable_win64_console.exe"
REM  The non-console exe also works but won't show progress in this window.
set "GODOT_EXE="

set "PROJECT_DIR=%~dp0timeshot"
set "EXPORT_PRESET=Windows Desktop"
set "EXE_NAME=Timeshot.exe"
set "BUILD_ROOT=%~dp0builds"
set "BUILD_DIR=%BUILD_ROOT%\timeshot-win"

REM --- Find Godot -------------------------------------------------------------
REM  Preferred: the console build of Godot 4.6.2 living in Downloads (current
REM  setup on this machine). Fall back to PATH, common install spots, and
REM  finally a recursive search through Downloads for any Godot_v*_console.exe
REM  so a future Godot version "just works" without editing this file.
if "%GODOT_EXE%"=="" (
    set "GODOT_EXE_CANDIDATE=%USERPROFILE%\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"
    if exist "!GODOT_EXE_CANDIDATE!" set "GODOT_EXE=!GODOT_EXE_CANDIDATE!"
)
if "%GODOT_EXE%"=="" (
    where godot >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%g in ('where godot') do set "GODOT_EXE=%%g" & goto :found_godot
    )
    REM Common install spots — extend this list if yours differs.
    if exist "C:\Program Files\Godot\godot.exe" set "GODOT_EXE=C:\Program Files\Godot\godot.exe"
    if exist "C:\Program Files\Godot\Godot.exe" set "GODOT_EXE=C:\Program Files\Godot\Godot.exe"
    if exist "%LOCALAPPDATA%\Godot\godot.exe" set "GODOT_EXE=%LOCALAPPDATA%\Godot\godot.exe"
)
REM Last resort: scan Downloads for any Godot console build (newest wins).
if "%GODOT_EXE%"=="" (
    for /f "delims=" %%g in ('dir /b /s /a-d "%USERPROFILE%\Downloads\Godot_v*_console.exe" 2^>nul') do set "GODOT_EXE=%%g"
)
if "%GODOT_EXE%"=="" (
    for /f "delims=" %%g in ('dir /b /s /a-d "%USERPROFILE%\Downloads\Godot_v*_win64.exe" 2^>nul') do set "GODOT_EXE=%%g"
)
:found_godot

if "%GODOT_EXE%"=="" (
    echo [ERROR] Godot not found.
    echo   Either add godot.exe to your PATH, or edit build.bat and set
    echo   GODOT_EXE to the full path of your Godot executable.
    exit /b 1
)
if not exist "%GODOT_EXE%" (
    echo [ERROR] GODOT_EXE points to a file that doesn't exist:
    echo   %GODOT_EXE%
    exit /b 1
)

REM --- Sanity check project ---------------------------------------------------
if not exist "%PROJECT_DIR%\project.godot" (
    echo [ERROR] Could not find project.godot at:
    echo   %PROJECT_DIR%\project.godot
    exit /b 1
)
if not exist "%PROJECT_DIR%\export_presets.cfg" (
    echo [ERROR] No export_presets.cfg in %PROJECT_DIR%.
    echo   Open the project in Godot once and add a "Windows Desktop" preset
    echo   via Project -^> Export. See the comments at the top of this file.
    exit /b 1
)

REM --- Optional clean ---------------------------------------------------------
if /i "%~1"=="clean" (
    echo [build] Cleaning %BUILD_ROOT% ...
    if exist "%BUILD_ROOT%" rmdir /s /q "%BUILD_ROOT%"
)

REM --- Prepare output folder --------------------------------------------------
if not exist "%BUILD_ROOT%" mkdir "%BUILD_ROOT%"
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"

REM --- Date stamp for the zip (YYYY-MM-DD, locale-independent) ---------------
for /f "tokens=2 delims==" %%i in ('wmic os get localdatetime /value ^| find "="') do set "LDT=%%i"
set "STAMP=!LDT:~0,4!-!LDT:~4,2!-!LDT:~6,2!"

REM --- Export -----------------------------------------------------------------
echo [build] Godot:    %GODOT_EXE%
echo [build] Project:  %PROJECT_DIR%
echo [build] Preset:   %EXPORT_PRESET%
echo [build] Output:   %BUILD_DIR%\%EXE_NAME%
echo.
echo [build] Exporting (this can take a minute)...

pushd "%PROJECT_DIR%"
"%GODOT_EXE%" --headless --export-release "%EXPORT_PRESET%" "%BUILD_DIR%\%EXE_NAME%"
set "EXPORT_ERR=!errorlevel!"
popd

if not !EXPORT_ERR! equ 0 goto :export_failed
if not exist "%BUILD_DIR%\%EXE_NAME%" goto :export_missing_exe

REM --- Zip --------------------------------------------------------------------
set "ZIP_NAME=Timeshot-%STAMP%.zip"
set "ZIP_PATH=%BUILD_ROOT%\%ZIP_NAME%"
if exist "%ZIP_PATH%" del /q "%ZIP_PATH%"

echo.
echo [build] Zipping to %ZIP_PATH% ...
pushd "%BUILD_ROOT%"
tar -a -c -f "%ZIP_NAME%" "timeshot-win"
set "ZIP_ERR=!errorlevel!"
popd

if not !ZIP_ERR! equ 0 goto :zip_failed

echo.
echo [build] Done.
echo   Build folder:  %BUILD_DIR%
echo   Shippable zip: %ZIP_PATH%
echo.
echo   Send the .zip - the recipient unzips and runs %EXE_NAME%.
echo   Windows SmartScreen will likely warn; they click "More info" then "Run anyway".

endlocal
exit /b 0


:export_failed
echo.
echo [ERROR] Godot export failed with exit code !EXPORT_ERR!.
echo   Common causes:
echo     - Export templates not installed. In Godot: Editor menu, Manage Export Templates, Download and Install.
echo     - Preset name mismatch. Current EXPORT_PRESET = "%EXPORT_PRESET%".
echo     - Script parse errors in the project.
exit /b !EXPORT_ERR!


:export_missing_exe
echo [ERROR] Godot reported success but %EXE_NAME% wasn't produced.
exit /b 1


:zip_failed
echo [ERROR] tar failed with exit code !ZIP_ERR!.
echo   tar is built into Windows 10+. On older Windows, zip the build folder by hand.
exit /b !ZIP_ERR!
