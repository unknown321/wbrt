Walkman Backup/Restore Tool
===

Create and restore backups for MT8590-based Walkmans:
  - NW-A30/40/50
  - ZX300
  - WM1A
  - WM1Z
  - DMP-Z1

## Requirements

  - Windows >= 10

## Download

[Link](https://github.com/unknown321/wbrt/releases/latest)

## Usage

Run the exe and follow instructions.

[Video](https://www.youtube.com/watch?v=yDw7vh5G-Ss)

## FAQ

### Can this tool pull my device out of bootloop?

Yes, if you have made a backup beforehand. Flashing backups from other devices (even same model) is not 
recommended - your serial number and other factory settings will be overwritten with no chance of recovery.

### Can I restore using backup from another model onto my device?

No, it will brick your device. There are no checks, so be careful.

### "Unrecognized device driver" / "Open failed" error

You need to remove all related drivers first.

1. Open PowerShell as admin
2. `pnputil /enum-drivers`
3. Look for `VID_0E8D&PID_2000`, write down related inf names (`oem<number>.inf`)
4. Remove driver packets: `pnputil -f -d oem<number>.inf`
5. (Just in case) Reboot
6. Run the tool again
