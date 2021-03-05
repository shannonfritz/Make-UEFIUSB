@ECHO OFF
REM Example script to extract drivers for Surface devices to be injected in the Windows image
REM ---
REM Download drivers from the site below and save them someplace like c:\surfacedrivers\
REM https://support.microsoft.com/en-us/help/4023482/surface-download-drivers-and-firmware-for-surface
REM Copy this script to the same directory
REM Open a cmd prompt in the same directory run the script to extract then to a Drivers subdirectory
REM ---


REM Make a Drivers directory in the current directory
if NOT EXIST "%CD%\Drivers" ( mkdir "%CD%\Drivers" )

REM Loop through and process every .msi with a subroutine
for %%f in (*.msi) do call :msifile %%~nf
goto:end


:msifile
echo Processing %1

REM Make a temporary eXtraction directory
if NOT EXIST "%CD%\x" ( mkdir "%CD%\x" )

if EXIST "%CD%\Drivers\%1" ( echo Deleting existing drivers for %1 && rmdir /s /q "%CD%\Drivers\%1" )

REM Extrat the drivers from the msi
REM msiexec -a SurfaceLaptop2_Win10_18362_19.100.3934.0.msi /qb targetdir="%CD%\x"
echo Extracting %1
msiexec -a %1.msi /qb targetdir=%CD%\x

REM Make a subdirectory for this driver
mkdir "%CD%\Drivers\%1"

REM Move the extracted drivers
echo Moving extracted drivers for %1
for /D %%D in ("%CD%\x\SurfaceUpdate\*") do @echo %%D && move /Y %%D "%CD%\Drivers\%1"

REM Delete whatever else was left
echo Cleaing up after %1
rmdir /s /q "%CD%\x"
goto:eof


:end
echo.
echo Done.
