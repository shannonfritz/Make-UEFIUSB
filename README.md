#### Create a Bootable USB drive to install Windows on devices with UEFI

# Make-UEFIUSB.ps1
Creating a Bootable USB drive can be easy with tools like Rufus, but when making boot media to install Windows, sometimes you need to do more than just copy an ISO to a USB drive.  So I wrote a Powershell script to take care of all the things I needed to be done.

The basic usage looks like this:
1. Create a "Working Directory" and download Make-UEFIUSB.ps1 there. I'll use "C:\UEFIUSB" for example
2. Optionally, download and extract drivers for your device to C:\UEFIUSB\Drivers (see *Drivers* below)
3. Download the .iso of the version of Windows you want to use into C:\UEFIUSB
4. Make sure you only have one USB Storage device connected and run the script from an elevated powershell session 

After that you end up with a USB drive ready to boot and install Windows from scratch, ready for OOBE.


## What it does
The script will create a bootable USB drive for UEFI (not BIOS) devices to enable installation of Windows 10.  It does this using PowerShell commands to perform several tasks.

* Automatically mount the .iso
* Automatically inject Drivers (NOTE: Only for the Pro edition)
  * Attempt to shrink WinRE.wim if it's more than 400MB
  * Copy "Extras" into the install.wim (you may not want this, depending on what is in there)
* Clear the USB drive of all partitions/files/data
* Partition the USB drive with GPT and FAT32
* Copy all contents of the ISO to the USB drive
* Split the install.wim if it's larger than 4GB
* *Optionally* create another USB drive (loops)
* Clean up temporary files and dismount the ISO


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
The Windows Installation media usually has enough common drivers to get a device connected and let Windows Update take care of the rest, but sometimes that's not the case.  It can be helpful (even necessary) to inject drivers in the installation media so all the components like Wifi, Cameras and Keyboards are ready to go after a fresh install.  I leave the collection of drivers as an exercise for the reader, but for Surface devices you can download an .msi package with all the components for each model released at https://aka.ms/surfacedrivers

Download the driver pack for each model you want into your Working Directory and use extractdrivers.cmd to automatilly extact them to a Drivers directory.  If the Make-UEFIUSB.ps1 script find a Drivers directory it will automatically process and inject any drivers it finds for you.


## Shrink WinRE.wim?
This check only happens if also injecting drivers.  Once upon a time there was a case where WinRE was over 500MB which is larger than the defualt recovery partition size that setup.exe creates.  This isn't exactly a problem unless you enable BitLocker, at which point the WinRE is applied to that partiton and would fail, requiring another partition to be created and a reboot to do so. This was problemati for "Device Encryption" to automatically enable BitLocker, but it could be done manually. Regardless, this is not a *current* issue, but it's something I figure I'd check for and try to fix just in case.


## Thank Yous
I'm not going to pretend like I figured this out on my own.  there are a lot of great samples and coe snippets out there that I pulled from to put this together.  Most noteable mentions include...

* *Emin Atac* (https://p0w3rsh3ll.wordpress.com/2016/10/30/how-to-create-uefi-bootable-usb-media-to-install-windows-server-2016/) The Bones of this script is born from that one.  Thank you!
* *Simon Sheppard* (https://ss64.com/) I use your site all the time when I'm trying to remember quirky syntax in CMD
