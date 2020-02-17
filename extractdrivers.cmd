@ECHO OFF
REM Example script to extract drivers for Surface devices to be injected in the Windows image
REM ---
REM Download drivers from the site below and save them someplace like c:\surfacedrivers\
REM https://support.microsoft.com/en-us/help/4023482/surface-download-drivers-and-firmware-for-surface
REM Copy this script to the same directory
REM Open a cmd prompt in the same directory run the script
REM ---

REM Make a Drivers and a temporary "x" directory in the current directory
if NOT EXIST "%CD%\x" ( mkdir "%CD%\x" )
if NOT EXIST "%CD%\Drivers" ( mkdir "%CD%\Drivers" )

REM Extract all the drivers to the "x" direcotry
forfiles /M *.msi /C "cmd.exe /C echo @file && msiexec -a @file /qb targetdir=%CD%\x"

REM if you want to extract them in a specific order, then specify what to do below
REM msiexec -a SurfaceGo_Win10_17763_1902010_WiFi_2.msi /qb targetdir="%CD%\x"
REM msiexec -a SurfacePro4_Win10_18362_19.100.2166.0.msi /qb targetdir="%CD%\x"
REM msiexec -a SurfacePro_Win10_18362_19.092.25297.0.msi /qb targetdir="%CD%\x"
REM msiexec -a SurfaceLaptop2_Win10_18362_19.100.3934.0.msi /qb targetdir="%CD%\x"
REM msiexec -a SurfaceLaptop_Win10_18362_19.100.3933.0.msi /qb targetdir="%CD%\x"

REM move the extracted drivers to the "Drivers" directory
for /D %%D in ("%CD%\x\SurfaceUpdate\*") do @echo %%D && move /Y %%D "%CD%\Drivers\"
rmdir /s /q "%CD%\x"
