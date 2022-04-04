#### Create a Bootable USB drive to install Windows on devices with UEFI

# Make-UEFIUSB.ps1
Creating a Bootable USB drive can be easy with tools like [Rufus](https://rufus.ie/), but when making boot media to install Windows, sometimes you need to do more than just copy an ISO to a USB drive.  So I wrote a PowerShell script to take care of all the things I needed to be done.

The basic usage looks like this:
1. Create a "Working Directory" and download Make-UEFIUSB.ps1 there. I'll use "C:\UEFIUSB" for example
2. Optionally, download and extract drivers for your device to C:\UEFIUSB\Drivers (see *Drivers* below)
3. Download the .iso of the version of Windows you want to use into C:\UEFIUSB
4. Make sure you only have one USB Storage device connected and run the script from an elevated powershell session 

After that you end up with a USB drive ready to boot and install Windows from scratch, ready for OOBE.


## What it does
The script will create a bootable USB drive for UEFI (not BIOS) devices to enable installation of Windows 10/11/Server.  It does this using PowerShell commands to perform several tasks.

* Automatically mount the .iso
* Automatically inject Drivers (NOTE: Only for the Pro edition)
  * Prompts you to select the Image to use (I recommend Pro)
  * Attempt to shrink WinRE.wim if it's more than 400MB
  * Copy "Extras" into the install.wim (edit the script to enable this)
* Clear the USB drive of all partitions/files/data
* Partition the USB drive with GPT and FAT32
* Copy all contents of the ISO to the USB drive
* Split the install.wim if it's larger than 4GB
* *Optionally* create another USB drive (loops)
* Clean up temporary files and dismount the ISO

## Usage
If you want to inject drivers, download and extraact them first.  See *Drivers* below for an example for Surface devices.

1. Make sure the .ps1 and the .iso are in the same folder (or edit the script to specify the path to the iso)
2. Connect the USB drive you want to overwrite
3. launch an elevated PowerShell session in that folder and run the script.

Then just wait for it to finish.

```
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\Windows\system32> cd C:\UEFIUSB\                                                                                  
PS C:\UEFIUSB> .\Make-UEFIUSB.ps1
Extra Folder to copy: C:\UEFIUSB\Autopilot\
Mounting ISO...
Creating temp workspace C:\7acfec0c-cd3b-41e7-9282-59998daf7fae
Copying Install.WIM from the ISO
VERBOSE: Performing the operation "Copy File" on target "Item: D:\sources\install.wim Destination:
C:\7acfec0c-cd3b-41e7-9282-59998daf7fae\install.wim".
Mounting Install.WIM (this takes a while)
Mounting Injecting drivers from C:\UEFIUSB\Drivers
VERBOSE: Target Image Version 10.0.18363.535
VERBOSE: Successfully added driver C:\UEFIUSB\Drivers\8897BT\mbtr8897w81x64.inf
VERBOSE: Successfully added driver C:\UEFIUSB\Drivers\8897WLAN\mrvlpcie8897.inf
VERBOSE: Successfully added driver C:\UEFIUSB\Drivers\AudioDetectionDriver\DetectionVerificationDrv.inf
VERBOSE: Successfully added driver C:\UEFIUSB\Drivers\AudioSST\IntcOED.inf
VERBOSE: Successfully added driver C:\UEFIUSB\Drivers\AudioSSTBus\IntcAudioBus.inf
...
```


## Requirements
This script is written in PowerShell and was only tested running on Windows 10.  Just be on a Supported build and it should be fine.

The **installation media** should be a Windows 10 .iso, preferrably the "business editions" but it really should work on any Windows iso (including Server, but you would need to edit the script a bit).  If you have a Visual Studio Subscription (formerly MSDN) you can download a copy from https://visualstudio.microsoft.com/.  Just log in and click "Subscriber Access" then Download.  It works with ISO's from the VLSC as well.

You'll need enough **free disk space** for at least a copy of the ISO and the drivers you've extracted. The script doesn't check for this, so if you run out, I don't know what will happen, but it won't be great.

You'll also want to make sure you only have **one USB drive** connected when running the script.  It prompts about errasing the drive, but it doesn't really examine or select one of multiple drives.  So *if you have a USB drive connected that you care about, remove it before running the script* or it'll destroy all the data there.

And some **paitence** doesn't hurt.  It's a fair amount of data being processed so it takes a while, but there is a loop at the end to create multiple USB drives more quickly in case you wanted to make more than one.


## Why Pro?
It is common practice to "re-image" computers with Enterprise, so I get asked a lot, *why am I using Pro*?

I want to re-create, as close as possible, the kind of factory imaging that an OEM would be doing on a device and OEM's only provide the Pro edition of Windows.  Also, Windows 10 provides the ability to "sku up" to Enterprise without needing to Download anything, without installing anything, without even a reboot.  So there is no real need to install Enterprise directly.

Keep in mind that this only comes in to play if you are injecting drivers.  If you do not inject drivers then all editions are available to install.  When you inject drivers, then Pro will automatically be installed.

If you really want to you can edit the script and change $InjectImageName to whatever edtion you want.  This would be useful if you wanted to make a bootable USB drive for the Education edition, or even Windows Server.


## Drivers
The Windows Installation media usually has enough of the common drivers to get a device connected to the Internet and then let Windows Update take care of the rest, but sometimes that's not the case.  It can be helpful (even necessary) to inject drivers in the installation media so all the components like Wifi, Cameras and Keyboards are ready to go after a fresh install and durring OOBE.  I leave the collection of drivers as an exercise for the reader, but for Surface devices you can download an .msi package with all the components for each model released at https://aka.ms/surfacedrivers

If you download the driver pack for each Surface model you want, you can place them in your Working Directory and just run **extractdrivers.cmd** to automatically extact each of them under a Drivers directory.  If **Make-UEFIUSB.ps1** finds a Drivers directory it will automatically process and inject all the drivers it finds in there for you.

**NOTE:** If you are not using a Surface device then you won't need to use **extractdrivers.cmd** but you can still place the extracted drivers for those other models under *\Drivers\modelname* to have them incorporated in the installation media for you by **Make-UEFIUSB.ps1**.

```
Microsoft Windows [Version 10.0.19042.804]
(c) 2020 Microsoft Corporation. All rights reserved.

C:\UEFIUSB>extractsurfacedrivers.cmd
Processing SurfaceGo_Win10_18362_21.015.38060_WiFi_0
Deleting existing drivers for SurfaceGo_Win10_18362_21.015.38060_WiFi_0
Extracting SurfaceGo_Win10_18362_21.015.38060_WiFi_0
Moving extracted drivers for SurfaceGo_Win10_18362_21.015.38060_WiFi_0
C:\UEFIUSB\x\SurfaceUpdate\Drivers
        1 dir(s) moved.
C:\UEFIUSB\x\SurfaceUpdate\Firmware
        1 dir(s) moved.
Cleaing up after SurfaceGo_Win10_18362_21.015.38060_WiFi_0
Processing SurfaceLaptop3_Win10_18362_20.121.13124.0
Deleting existing drivers for SurfaceLaptop3_Win10_18362_20.121.13124.0
Extracting SurfaceLaptop3_Win10_18362_20.121.13124.0
Moving extracted drivers for SurfaceLaptop3_Win10_18362_20.121.13124.0
C:\UEFIUSB\x\SurfaceUpdate\AudioDetectionDriver
        1 dir(s) moved.
C:\UEFIUSB\x\SurfaceUpdate\audiosst
        1 dir(s) moved.
C:\UEFIUSB\x\SurfaceUpdate\audiosstbus
        1 dir(s) moved.
C:\UEFIUSB\x\SurfaceUpdate\bluetooth
        1 dir(s) moved.
...
        1 dir(s) moved.
Cleaing up after SurfaceLaptop3_Win10_18362_20.121.13124.0

Done.

C:\UEFIUSB>
```


## Shrink WinRE.wim?
This check only happens if also injecting drivers.  Once upon a time there was a case where WinRE.wim was over 500MB which is larger than the defualt recovery partition size that setup.exe creates.  This wasn't exactly a problem until BitLocker was enabled; at which point the WinRE is applied to that partiton but wouldn't fit, requiring another partition to be created and a reboot to do so. This was problematic for "Device Encryption" to automatically enable BitLocker, but it could be done manually.

Regardless, this is not a *current* issue, but it's something I figure I'd check for and try to fix just in case.


## Thank Yous
I'm not going to pretend like I figured this out on my own.  there are a lot of great samples and coe snippets out there that I pulled from to put this together.  Most noteable mentions include...

* *Emin Atac* (https://p0w3rsh3ll.wordpress.com/2016/10/30/how-to-create-uefi-bootable-usb-media-to-install-windows-server-2016/) The Bones of this script is born from that one.  Thank you!
* *Simon Sheppard* (https://ss64.com/) I use your site all the time when I'm trying to remember quirky syntax in CMD
