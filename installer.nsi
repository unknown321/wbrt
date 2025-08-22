; This examples demonstrates how libwdi can be used in an installer script
; to automatically install USB drivers along with your application.
;
; Requirements: Nullsoft Scriptable Install System (http://nsis.sourceforge.net/)
;
; To use this script, do the following:
; - configure libwdi (see config.h)
; - compile wdi-simple.exe
; - customize this script (application strings, wdi-simple.exe parameters, etc.)
; - open this script with Nullsoft Scriptable Install System
; - compile and run

; Use modern interface
  !include MUI2.nsh
  !define MUI_FINISHPAGE_NOAUTOCLOSE

; General
  Name                  "Walkman Backup/Restore Tool"
  OutFile               "walkman-backup-restore-tool.exe"
  ShowInstDetails       show
  RequestExecutionLevel admin

; Pages
  !insertmacro MUI_PAGE_LICENSE "LICENSE"
   Page custom actionEnter "" ": select action"
   Page custom destEnter "" ": select path"
  !insertmacro MUI_PAGE_INSTFILES

;Languages
  !insertmacro MUI_LANGUAGE "English"

!macro NSD_SetUserData hwnd data
    nsDialogs::SetUserData ${hwnd} ${data}
!macroend
!define NSD_SetUserData `!insertmacro NSD_SetUserData`

!macro NSD_GetUserData hwnd outvar
    nsDialogs::GetUserData ${hwnd}
    Pop ${outvar}
!macroend
!define NSD_GetUserData `!insertmacro NSD_GetUserData`

!include nsDialogs.nsh
!include "FileFunc.nsh"
!insertmacro GetTime
Var Dialog
Var hwnd
Var SelectedAction
Var destination
Var backupSize

Function .onInit
    InitPluginsDir
    StrCpy $destination ""
    StrCpy $SelectedAction "1"
    StrCpy $backupSize 1073741824 ; 1GB, 1024*1024*1024
FunctionEnd

Function actionEnter
    nsDialogs::Create 1018
    Pop $Dialog

    ${If} $Dialog == error
        Abort
    ${EndIf}

    !insertmacro MUI_HEADER_TEXT "Select action" ""

    ${NSD_CreateLabel} 0 0 100% 6% "Action:"

    ${NSD_CreateRadioButton} 0 12% 40% 6% "Backup"
        Pop $hwnd
        ${NSD_SetState} $hwnd 1
        ${NSD_AddStyle} $hwnd ${WS_GROUP}
        ${NSD_SetUserData} $hwnd 1
        ${NSD_OnClick} $hwnd actionClick

    ${NSD_CreateRadioButton} 0 20% 40% 6% "Restore"
        Pop $hwnd
        ${NSD_SetUserData} $hwnd 0
        ${NSD_OnClick} $hwnd actionClick

    nsDialogs::Show
FunctionEnd

Function actionClick
    Pop $hwnd
    ${NSD_GetUserData} $hwnd $SelectedAction
FunctionEnd

var CustomDir
Function selectDest
    ${If} $SelectedAction == "1"
        nsDialogs::SelectFolderDialog "Please choose backup directory" "$DESKTOP"
    ${Else}
        nsDialogs::SelectFileDialog "Please choose backup file" "$DESKTOP" "*.bin|*.bin"
    ${EndIf}

    Pop $CustomDir
    GetDlgItem $0 $hWndParent 1 ; Get button handle

    ${If} $CustomDir == "error"
        StrCpy $CustomDir ""
    ${EndIf}

    StrCmp $CustomDir "" bad
        StrCpy $destination $CustomDir
        EnableWindow $0 1
        ${NSD_CreateLabel} 0 15% 100% 6% "Selected: $destination"
        goto done
    bad:
        MessageBox MB_ICONEXCLAMATION|MB_OK "You must select a destination before continuing! $CustomDir"
        EnableWindow $0 0
    done:
FunctionEnd

var BUTTON
Function destEnter
    nsDialogs::Create 1018

    !insertmacro MUI_HEADER_TEXT "Select path" ""

    GetDlgItem $0 $hWndParent 1 ; Get button handle
    EnableWindow $0 0


    ${If} $SelectedAction == "1"
        ${NSD_CreateButton} 0 0 100% 15u "Select backup directory"
    ${Else}
        ${NSD_CreateButton} 0 0 100% 15u "Select backup file"
    ${EndIf}

    Pop $BUTTON
    GetFunctionAddress $0 selectDest
    nsDialogs::OnClick $BUTTON $0

    nsDialogs::Show
FunctionEnd

Function GetSafeDateTime
    ${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6

    # Ensure two digits
    StrLen $7 $0
    ${If} $7 == 1
        StrCpy $0 "0$0"
    ${EndIf}

    StrLen $7 $1
    ${If} $7 == 1
        StrCpy $1 "0$1"
    ${EndIf}

    StrLen $7 $3
    ${If} $7 == 1
        StrCpy $3 "0$3"
    ${EndIf}

    StrLen $7 $4
    ${If} $7 == 1
        StrCpy $4 "0$4"
    ${EndIf}

    StrLen $7 $5
    ${If} $7 == 1
        StrCpy $5 "0$5"
    ${EndIf}

    # YYYYMMDD_HHMMSS
    StrCpy $R0 "$2$1$0_$4$5$6"
    Push $R0
FunctionEnd


; Call wdi-simple
;
; -n, --name <name>          set the device name
; -f, --inf <name>           set the inf name
; -m, --manufacturer <name>  set the manufacturer name
; -v, --vid <id>             set the vendor ID (VID)
; -p, --pid <id>             set the product ID (PID)
; -i, --iid <id>             set the interface ID (MI)
; -t, --type <driver_type>   set the driver to install
;                            (0=WinUSB, 1=libusb0, 2=libusbK, 3=usbser, 4=custom)
; -d, --dest <dir>           set the extraction directory
; -x, --extract              extract files only (don't install)
; -c, --cert <certname>      install certificate <certname> from the
;                            embedded user files as a trusted publisher
;     --stealth-cert         installs certificate above without prompting
; -s, --silent               silent mode
; -b, --progressbar=[HWND]   display a progress bar during install
;                            an optional HWND can be specified
; -o, --timeout              set timeout (in ms) to wait for any 
;                            pending installations
; -l, --log                  set log level (0=debug, 4=none)
; -h, --help                 display usage

var foundCode
var SafeDateTime
!include "x64.nsh"
var exitCode

Section reviewPageLeave
    ; https://learn.microsoft.com/en-us/windows/win32/winprog64/file-system-redirector
    ; In most cases, whenever a 32-bit application attempts to access %windir%\System32, the access is redirected to an architecture-specific path.
    ${If} ${RunningX64}
        ${DisableX64FSRedirection}
    ${EndIf}

    ReadEnvStr $R7 COMSPEC

    ; libwdi certificate stays after driver uninstallation, unreliable
    ; ExecWait '"$R0" /C certutil -store -silent Root | findstr /i "CN=USB\VID_0E8D&PID_2000 ^(libwdi autogenerated^)"' $foundCode
    nsExec::ExecToStack /OEM '"$R7" /C "pnputil /enum-drivers | findstr /i \'VID_0E8D&PID_2000 ^(libwdi autogenerated^)\'"'
    Pop $foundCode

    ${If} ${RunningX64}
        ${EnableX64FSRedirection}
    ${EndIf}

    StrCmp $foundCode "0" found
        DetailPrint "Driver not found and will be installed"
        File "/oname=$PLUGINSDIR\wdi-simple.exe" "libwdi/examples/wdi-simple.exe"
        ReadEnvStr $R0 userprofile
        nsExec::ExecToLog '"$PLUGINSDIR\wdi-simple.exe" --name \"Walkman Backup/Restore (MT65xx Preloader)\" --vid 0x0E8D --pid 0x2000 --progressbar=$HWNDPARENT --timeout 120000 --log 0 --dest "$R0\WalkmanBackupRestoreDriver" --type 0'
        DetailPrint "Driver installed"
        goto done
    found:
        DetailPrint "Driver already installed"
    done:

    Call GetSafeDateTime
    Pop $SafeDateTime

    File "/oname=$PLUGINSDIR\flash_tool.exe" "deps/flash_tool.exe"
    File "/oname=$PLUGINSDIR\DA.bin" "deps/DA.bin"
    DetailPrint "Saving to $destination\walkman_backup.$SafeDateTime.bin"
    DetailPrint ""
    DetailPrint "1. Detach cable and turn the device off"
    DetailPrint "2. Hold Play and Volume Down buttons, insert cable"

    ${If} $SelectedAction == "1"
        ExecWait '"$R7" /C "$PLUGINSDIR\flash_tool.exe" -d $PLUGINSDIR\DA.bin -l $backupSize -R -D $destination\walkman_backup.$SafeDateTime.bin'
    ${Else}
        ; don't use reboot flag here, device won't boot
        ExecWait '"$R7" /C "$PLUGINSDIR\flash_tool.exe" -d $PLUGINSDIR\DA.bin -l $backupSize -F $destination'
        DetailPrint "Detach cable, hold power button to turn device on"
    ${EndIf}
    Pop $exitCode

SectionEnd