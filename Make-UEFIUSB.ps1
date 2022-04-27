#####
##### Make-UEFIUSB.ps1
##### 

# ensure running in elevated session
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

##### Settings 

# Set here the path of your ISO file
#$iso = "$(Split-Path -Parent $PSCommandPath)\en-us_windows_11_business_editions_x64_dvd_3a304c08.iso"
# Let's assume there is just one ISO in the 
if (0 -eq (Get-ChildItem -Path "$(Split-Path -Parent $PSCommandPath)\*.iso" | Measure-Object).Count) { Write-Host "No ISO found.  Quitting."; exit }  
if (1 -lt (Get-ChildItem -Path "$(Split-Path -Parent $PSCommandPath)\*.iso" | Measure-Object).Count) { Write-Host "More than one ISO found.  Quitting."; exit }  
$iso = Get-ChildItem -Path "$(Split-Path -Parent $PSCommandPath)\*.iso"
Write-Host "Using $iso"

# If this will be used for Autopilot, fetch the Get-WindowsAutopilotInfo script too
#$GetAutopilotScripts = $true

# Specify a path to a folder that should get copied to copy to the USB drive
# If injecting drivers, it'll get put in the install.wim file too.
# Also, this script (that creates the USB drive) will be copied.
$CopyExtraFolder = $false
#$CopyExtraFolder = "$(Split-Path -Parent $PSCommandPath)\Autopilot\"
#$CopyExtraFolder = "C:\Users\shfritz\OneDrive\Documents\Get Modern Workshop\PrepDevice\Autopilot"
if (Test-Path -Path "$CopyExtraFolder") {
    Write-Output "Extra Folder to copy: $CopyExtraFolder"
}

# Surface drivers can be found here - download the ZIP and extract it somewhere
# https://support.microsoft.com/en-us/help/4023482/surface-download-drivers-and-firmware-for-surface

# Path to the folder with extracted drivers (.inf files, etc) exist (all subfolders will be processed)
# If you do NOT want to inject drivers, set this to $false
#$InjectDrivers = $false
$InjectDrivers = "$(Split-Path -Parent $PSCommandPath)\Drivers"
#$InjectDrivers = "C:\surface\Drivers"

# Where the winstall.wim will be modified.  It that will be removed when the script is done
# NOTE: If the script is terminated before Dismounting the image, use "Dism /Cleanup-Mountpoints" so you can delete this temp folder
# Several GB will be needed at this location to manipulate the install.wim file
$InjectTempPath = "C:\$(New-GUID)"


##### Begin...
Write-Output "Mounting ISO..."
# Mount iso
$miso = Mount-DiskImage -ImagePath $iso -StorageType ISO -PassThru

# Drive letter of the mounted ISO
$dl = ($miso | Get-Volume).DriveLetter
$InstallWIM = "$($dl):\sources\install.wim"


# If no drivers are beign injected, the whole section below is just skipped and
# the WIM is just written to the USB drive as-is.
# But, if we're injecting drivers, we'll need to manipulate the install.wim file
# so let's copy the WIM file someplace, mount it, inject the drivers, then save it
# https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-and-remove-drivers-to-an-offline-windows-image#add-drivers-to-an-offline-windows-image
if (Test-Path -Path "$InjectDrivers") {
    # Injecting drivers takes a long time, so we're only doing one image.  The ISO likely has more than one
    # image, so we want to specify which one should get the drivers, and all others will be removed.
    # It is recomended to use the "Pro" edition as that is what ships from OEMs,
    # and AAD Cloud Activation will SKU up from Pro to Enterprise anyway
    Write-Output "Finding images in $InstallWIM"
    Get-WindowsImage -ImagePath $InstallWIM | select ImageIndex,ImageName | Format-Table
    $InjectImageIndex = $null
    while ($InjectImageIndex -notmatch "^\d+$") {
        $InjectImageIndex = (Read-Host -Prompt "Enter the Image Index number for desired Windows Image")
    }
    Write-Output "Selected $InjectImageIndex"

    Write-Output "Creating temp workspace $InjectTempPath"
    New-Item -Path $InjectTempPath -Type directory | Out-Null
    New-Item -Path "$InjectTempPath\MOUNT" -Type directory | Out-Null

    Write-Output "Copying Install.WIM from the ISO"
    Copy-Item -Path "$InstallWIM" -Destination "$($InjectTempPath)\install.wim" -Verbose
    # Change $InstallWIM to the path of the new WIM file
    $InstallWIM = "$InjectTempPath\install.wim"

    # Because it was copied from an ISO, remove the ReadOnly flag
    Set-ItemProperty $InstallWIM -Name IsReadOnly -Value $false

    # Mount the image
    Write-Output "Mounting Install.WIM (this takes a while)"
    Mount-WindowsImage -Path "$InjectTempPath\MOUNT" -ImagePath "$InstallWIM" -Index $InjectImageIndex | Out-Null

    # Inject the drivers
    Write-Output "Mounting Injecting drivers from $($InjectDrivers)"
    $InjectDriverLog = "$InjectTempPath\InjectedDrivers.log"
    Add-WindowsDriver -Path "$InjectTempPath\MOUNT" -Driver $InjectDrivers -Recurse -Verbose -LogPath $InjectDriverLog | Out-Null

    # Fix WinRE while we are in here (the default recovery partition size is only 500MB)
    $WIMSize = (Get-Item "$InjectTempPath\MOUNT\Windows\System32\Recovery\winre.wim").length
    Write-Output "WinRE is $($WIMSize / 1MB)MB"
    if($WIMSize -gt 400MB)
    {
        Write-Output "If bigger than 500MB there can be trouble with BitLocker.  Attempting to shrink it."
        Export-WindowsImage -SourceImagePath "$InjectTempPath\MOUNT\Windows\System32\Recovery\winre.wim" -SourceIndex 1 -DestinationImagePath "$InjectTempPath\MOUNT\Windows\System32\Recovery\winre_new.wim"
        Remove-Item -Path "$InjectTempPath\MOUNT\Windows\System32\Recovery\winre.wim"
        Rename-Item -Path "$InjectTempPath\MOUNT\Windows\System32\Recovery\winre_new.wim" -NewName "winre.wim"
        $WIMSize = (Get-Item "$InjectTempPath\MOUNT\Windows\System32\Recovery\winre.wim").length
        Write-Output "WinRE is now $($WIMSize / 1MB)MB"
    }

    # Copy the scripts into the Image as well so they get on the installed device, not just the USB drive
    if (Test-Path -Path "$CopyExtraFolder") {
        Write-Output "Copying Extra Folder..."
        #$Location = New-Item -Path "$InjectTempPath\MOUNT\" -Name $(Split-Path $CopyExtraFolder -Leaf) -ItemType Directory
        $Location = "$InjectTempPath\MOUNT\"
        Copy-Item -Path $CopyExtraFolder -Recurse -Destination $Location -Container -Verbose

        # Copy this script to the USB drive too, why not.
        Copy-Item -Path $PSCommandPath -Destination $Location
    }

    # Commit the changes and unmount the image
    Write-Output "Saving changes to $InstallWIM (this also takes a while)"
    Dismount-WindowsImage -Path "$InjectTempPath\MOUNT" -Save | Out-Null
    #Dismount-WindowsImage -Path "$InjectTempPath\MOUNT" -Discard

    # Since we only update one image in the WIM, remove all of the others.
    # This only removes their metadata and XML files, not actually change the data
    # https://docs.microsoft.com/en-us/powershell/module/dism/remove-windowsimage
    # With just one image available for install, setup will just use it without prompting (presumably the Pro edition)
    $WindowsImages = Get-WindowsImage -ImagePath "$InstallWIM"
    foreach ($WindowsImage in $WindowsImages)
    {
        if ($WindowsImage.ImageIndex -ne $InjectImageIndex)
        {
            "Removing Image $($WindowsImage.ImageIndex), $($WindowsImage.ImageName)"
            Remove-WindowsImage -ImagePath "$InstallWIM" -Name $WindowsImage.ImageName | Out-Null
        }
    }

}


##### Start a loop to copy contents to multiple USB drives

DO {

    # Clean ! will clear any plugged-in USB stick!!
    Write-Output "Looking for USB drives..."
    Get-Disk | Where BusType -eq 'USB' | Clear-Disk -RemoveData -Confirm:$true -PassThru | Out-Null

    # Convert GPT
    Write-Output "Setting USB disk to GPT"
    if ((Get-Disk | Where BusType -eq 'USB').PartitionStyle -eq 'RAW') {
        Get-Disk | Where BusType -eq 'USB' | 
        Initialize-Disk -PartitionStyle GPT | Out-Null
    } else {
        Get-Disk | Where BusType -eq 'USB' | 
        Set-Disk -PartitionStyle GPT | Out-Null
    }

    # Create partition primary and format to FAT32
    Write-Output "Creating FAT32 partition..."
    $volume = Get-Disk | Where BusType -eq 'USB' | 
    New-Partition -UseMaximumSize -AssignDriveLetter | 
    Format-Volume -FileSystem FAT32

    Write-Output "Copying ISO to USB disk..."

    # Make an empty txt file with the same name as the source ISO, as a note-to-self
    New-Item -Path "$($volume.DriveLetter):\" -Name "$($(Get-ChildItem $iso).basename).txt" -ItemType File | Out-Null

    if ($InjectDriverLog) {
        Copy-Item -Path $InjectDriverLog -Destination "$($volume.DriveLetter):\" -Verbose -Force
    }

    if (Test-Path -Path "$CopyExtraFolder") {
        Write-Output "Copying Extra Folder..."
        #$Location = New-Item -Path "$($volume.DriveLetter):\" -Name $(Split-Path $CopyExtraFolder -Leaf) -ItemType Directory
        $Location = "$($volume.DriveLetter):\"
        Copy-Item -Path $CopyExtraFolder -Recurse -Destination $Location -Container -Verbose

        # Copy this script to the USB drive too, why not.
        Copy-Item -Path $PSCommandPath -Destination $Location
    }

    # Copy ISO content to USB except install.wim
    Write-Output "Copying contents of the ISO..."
    Copy-Item -Path "$($dl):\*" -Destination "$($volume.DriveLetter):\" -Recurse -Exclude "install.wim" -Verbose -Force

    # Check if file is larger than 4GB
    $WIMSize = (Get-Item "$InstallWIM").length
    if($WIMSize -gt 4GB)
    {
        Write-Output "Install.WIM is larger than 4GB ($($WIMSize / 1GB)), splitting it into SWM files..."
        Split-WindowsImage -ImagePath $InstallWIM -SplitImagePath "$($volume.DriveLetter):\sources\install.swm" -FileSize 4096 | Out-Null
    } else {
        Write-Output "Install.WIM is smaller than 4GB, copying it..."
        Copy-Item -Path "$InstallWIM" -Destination "$($volume.DriveLetter):\sources\install.wim"
    }

    Write-Output "Done."
    $confirmation = Read-Host "Write another USB drive? (y/n)"
} while ($confirmation -eq 'y')


##### Cleanup

# Eject USB
#Write-Output "Ejecting USB disk..."
#(New-Object -comObject Shell.Application).NameSpace(17).
#ParseName("$($volume.DriveLetter):").InvokeVerb('Eject')

# Dismount ISO
Write-Output "Dismounting ISO virtual disc..."
Dismount-DiskImage -ImagePath $iso | Out-Null

# Remove any modified install.wim files
if (Test-Path -Path "$InjectDrivers") {
    Write-Output "Deleting $InjectTempPath"
    Remove-Item -Path $InjectTempPath -Recurse
}

# Dism /Cleanup-Mountpoints

Write-Output "Finished." 
