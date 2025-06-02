@echo off
REM Build script for jpeg_decoder_wrapper.dll with proper turbojpeg linking

echo Building jpeg_decoder_wrapper.dll...

REM Check if Visual Studio tools are available
where cl >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Visual Studio compiler (cl.exe) not found in PATH
    echo Please run this from a Visual Studio Developer Command Prompt
    exit /b 1
)

REM Compile the wrapper DLL
cl /LD /Fe:jpeg_decoder_wrapper.dll jpeg_decoder_wrapper.c ^
   /I. ^
   /link lib\turbojpeg.lib ^
   /LIBPATH:lib

if %ERRORLEVEL% EQU 0 (
    echo Successfully built jpeg_decoder_wrapper.dll
) else (
    echo Failed to build jpeg_decoder_wrapper.dll
    exit /b 1
)

echo Build completed.