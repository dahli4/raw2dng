@echo off
setlocal EnableExtensions
set "HERE=%~dp0"
set "DNGLAB=%HERE%dnglab.exe"
if defined RAW2DNG_DNGLAB set "DNGLAB=%RAW2DNG_DNGLAB%"

if "%~1"=="" (
  echo Usage: raw2dng.cmd [-f] [-r] input.RAW [output.dng]
  echo        raw2dng.cmd [-f] [-r] input_dir output_dir
  echo        raw2dng.cmd -V
  exit /b 1
)

set "FORCE="
set "RECURSIVE="
:parse
if /I "%~1"=="-V" (
  echo raw2dng 0.2.0 (portable)
  exit /b 0
)
if /I "%~1"=="--version" (
  echo raw2dng 0.2.0 (portable)
  exit /b 0
)
if /I "%~1"=="-h" (
  echo Usage: raw2dng.cmd [-f] [-r] input.RAW [output.dng]
  echo        raw2dng.cmd [-f] [-r] input_dir output_dir
  exit /b 0
)
if /I "%~1"=="--help" (
  echo Usage: raw2dng.cmd [-f] [-r] input.RAW [output.dng]
  echo        raw2dng.cmd [-f] [-r] input_dir output_dir
  exit /b 0
)
if /I "%~1"=="-f" (
  set "FORCE=-f"
  shift
  goto parse
)
if /I "%~1"=="-r" (
  set "RECURSIVE=-r"
  shift
  goto parse
)

if not exist "%DNGLAB%" (
  echo dnglab.exe not found next to raw2dng.cmd. Re-download the release package.
  exit /b 2
)

if "%~2"=="" (
  "%DNGLAB%" convert %FORCE% "%~1" "%~dpn1.dng"
  exit /b %ERRORLEVEL%
)

"%DNGLAB%" convert %FORCE% %RECURSIVE% %*
exit /b %ERRORLEVEL%
