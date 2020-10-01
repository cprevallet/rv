;RV Setup
;Written by Craig S. Prevallet
;based on NSIS Modern User Interface
;NSIS Modern User Interface
;Welcome/Finish Page Example Script
;Written by Joost Verburg

;--------------------------------
;Include LogicLib to check we
; are admin

!include LogicLib.nsh

Function .onInit
UserInfo::GetAccountType
pop $0
${If} $0 != "admin" ;Require admin rights on NT4+
    MessageBox mb_iconstop "Administrator rights required!"
    SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
    Quit
${EndIf}
FunctionEnd

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"

;--------------------------------
;General

  ;Name and file
  Name "rv"
  OutFile "rv Windows x64 Setup.exe"

  ;Default installation folder
  ;InstallDir "$LOCALAPPDATA\Fitplot"
  InstallDir "$PROGRAMFILES64\rv"

  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\rv" ""

  ;Request application privileges for Windows Vista
  RequestExecutionLevel admin
;--------------------------------
;Variables

  Var StartMenuFolder
;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "LICENSE"
  !insertmacro MUI_PAGE_DIRECTORY

  ;Start Menu Folder Page Configuration
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
  !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\rv" 
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
  
  !insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages

  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "Components" Components

  CreateDirectory "$INSTDIR"
  SetOutPath "$INSTDIR"

  ;Create an environmental variable for the static (help) file locations.
  ;setx available Win Vista and later.
  ;nsExec::Exec 'setx STATIC_FILES "$INSTDIR\nw.package\static"'

  ;Install the following files
  CreateDirectory $INSTDIR\interp
  CreateDirectory $INSTDIR\runfiles
  SetOutPath "$INSTDIR\\interp"
  File /r "interp\"
  SetOutPath "$INSTDIR\\runfiles"
  File /r "runfiles\"
  SetOutPath "$INSTDIR"
  File paned.tcl
  File prepare_packages.tcl
  File GORV.BAT
  File rv_imperial.bat
  File rv_metric.bat
  File smartwatch-charging.svg
  File LICENSE
  
  ;Store installation folder
  WriteRegStr HKCU "Software\rv" "" $INSTDIR
  
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    
    ;Create shortcuts
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\rv_imperial.lnk" "$INSTDIR\rv_imperial.bat"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\rv_metric.lnk" "$INSTDIR\rv_metric.bat"
  
  !insertmacro MUI_STARTMENU_WRITE_END

SectionEnd

;Uninstaller Section

Section "Uninstall"

  RMDir /r "$INSTDIR"

  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
    
  Delete "$SMPROGRAMS\$StartMenuFolder\rv_imperial.lnk" 
  Delete "$SMPROGRAMS\$StartMenuFolder\rv_metric.lnk" 
  Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk"
  RMDir "$SMPROGRAMS\$StartMenuFolder"
  
  ;nsExec::Exec 'set STATIC_FILES ""'

  DeleteRegKey /ifempty HKCU "Software\rv"

SectionEnd
