@echo off
setlocal
set HERE=%~dp0
if "%~1"=="" (
  echo Usage: raw2dng.cmd input.RAW
  echo        raw2dng.cmd input.RAW output.dng
  echo        raw2dng.cmd input_dir output_dir
  exit /b 1
)
if /I "%~1"=="-V" (
  echo raw2dng 0.1.1 (portable)
  exit /b 0
)
if /I "%~1"=="-h" (
  echo Usage: raw2dng.cmd input.RAW [output.dng]
  exit /b 0
)
if "%~2"=="" (
  "%HERE%dnglab.exe" convert -f "%~1" "%~dpn1.dng"
  exit /b %ERRORLEVEL%
)
"%HERE%dnglab.exe" convert -f %*
exit /b %ERRORLEVEL%
