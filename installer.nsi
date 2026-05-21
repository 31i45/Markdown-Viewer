; NSIS Installer Script for Markdown Viewer
; Neutralinojs desktop application installer for Windows
;
; Build:  makensis /INPUTCHARSET UTF8 installer.nsi
; Output: desktop-app\dist\markdown-viewer\Markdown-Viewer-Setup.exe

; ============================================================
; 1. Header & Metadata
; ============================================================

!define PRODUCT_NAME        "Markdown Viewer"
!define PRODUCT_VERSION     "1.0.0"
!define PRODUCT_PUBLISHER   "ThisIs-Developer"
!define PRODUCT_WEB_SITE    "https://github.com/ThisIs-Developer/Markdown-Viewer"
!define PRODUCT_EXE_NAME    "markdown-viewer-win_x64.exe"
!define PRODUCT_UNINST_KEY  "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_DIR_REGKEY  "Software\Microsoft\Windows\CurrentVersion\App Paths\${PRODUCT_EXE_NAME}"

; Output
!define OUTPUT_DIR  "desktop-app\dist\markdown-viewer"
!define OUTPUT_FILE "${OUTPUT_DIR}\Markdown-Viewer-Setup.exe"
OutFile "${OUTPUT_FILE}"

; Installer name (appears in window title and welcome page)
Name "${PRODUCT_NAME}"

; Compression — LZMA offers the best ratio for this workload
SetCompressor /SOLID lzma

; Unicode support
Unicode True

; ============================================================
; 2. Includes & MUI Setup
; ============================================================

!include "MUI2.nsh"
!include "FileFunc.nsh"

; Request admin privileges (required for HKLM registry writes)
RequestExecutionLevel admin

; Variables
Var StartMenuFolder

; Install directory defaults to Program Files
InstallDir "$PROGRAMFILES64\${PRODUCT_NAME}"

; ============================================================
; 3. Version Information (embedded in the EXE)
; ============================================================

VIProductVersion "${PRODUCT_VERSION}.0"
VIAddVersionKey "ProductName"     "${PRODUCT_NAME}"
VIAddVersionKey "ProductVersion"  "${PRODUCT_VERSION}"
VIAddVersionKey "FileVersion"     "${PRODUCT_VERSION}"
VIAddVersionKey "CompanyName"     "${PRODUCT_PUBLISHER}"
VIAddVersionKey "FileDescription" "${PRODUCT_NAME} Installer"
VIAddVersionKey "LegalCopyright"  "${PRODUCT_PUBLISHER}"
VIAddVersionKey "OriginalFilename" "Markdown-Viewer-Setup.exe"

; ============================================================
; 4. MUI Configuration
; ============================================================

!define MUI_ABORTWARNING
!define MUI_ICON   "assets\icon.ico"
!define MUI_UNICON "assets\icon.ico"

; --- Installer Pages ---
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!define MUI_STARTMENUPAGE_REGISTRY_ROOT       "HKLM"
!define MUI_STARTMENUPAGE_REGISTRY_KEY        "Software\${PRODUCT_NAME}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME  "StartMenuFolder"
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\${PRODUCT_EXE_NAME}"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${PRODUCT_NAME}"
!insertmacro MUI_PAGE_FINISH

; --- Uninstaller Pages ---
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; --- Language ---
!insertmacro MUI_LANGUAGE "English"

; ============================================================
; 5. Installer Sections
; ============================================================

; Reserve files for faster startup (loads these before the first page)
ReserveFile /plugin "InstallOptions.dll"

; --- Section: Core Application Files ---
Section "!Application Files" SEC01
  SectionIn RO  ; Always installed, cannot be deselected

  SetOutPath "$INSTDIR"

  ; Copy application binary (resources are embedded via --embed-resources)
  File "desktop-app\dist\markdown-viewer\${PRODUCT_EXE_NAME}"

  ; Copy icon file for shortcuts and file associations
  File "assets\icon.ico"

  ; Estimated installed size (KB) — helps the installer show disk space
  AddSize 5120

  ; Create uninstaller (only once)
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Register application path (allows "Start > Run > markdown-viewer-win_x64")
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\${PRODUCT_EXE_NAME}"

  ; Write uninstall metadata (appears in "Apps & Features" / "Programs and Features")
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayName"     "${PRODUCT_NAME}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayVersion"  "${PRODUCT_VERSION}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "Publisher"       "${PRODUCT_PUBLISHER}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "URLInfoAbout"    "${PRODUCT_WEB_SITE}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayIcon"     "$INSTDIR\icon.ico"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "NoModify"  1
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "NoRepair"  1
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "EstimatedSize" 5120

  ; Register application for "Open with" menu (Windows 10/11)
  WriteRegStr HKLM "Software\Classes\Applications\${PRODUCT_EXE_NAME}" "" "${PRODUCT_NAME}"
  WriteRegStr HKLM "Software\Classes\Applications\${PRODUCT_EXE_NAME}\shell\open\command" "" '"$INSTDIR\${PRODUCT_EXE_NAME}" "%1"'
  WriteRegStr HKLM "Software\Classes\Applications\${PRODUCT_EXE_NAME}\DefaultIcon" "" "$INSTDIR\icon.ico"

  ; Refresh shell icons
  System::Call 'shell32.dll::SHChangeNotify(i 0x8000000, i 0, p 0, p 0)'
SectionEnd

; --- Section: File Associations ---
Section "Associate .md and .markdown files" SEC02
  ; Register the ProgID (application identity for file types)
  WriteRegStr HKLM "Software\Classes\MarkdownViewer.Document" "" "Markdown Document"
  WriteRegStr HKLM "Software\Classes\MarkdownViewer.Document\DefaultIcon" "" "$INSTDIR\icon.ico"
  WriteRegStr HKLM "Software\Classes\MarkdownViewer.Document\shell\open\command" "" '"$INSTDIR\${PRODUCT_EXE_NAME}" "%1"'

  ; Point .md and .markdown extensions to our ProgID
  WriteRegStr HKLM "Software\Classes\.md"       "" "MarkdownViewer.Document"
  WriteRegStr HKLM "Software\Classes\.markdown"  "" "MarkdownViewer.Document"

  ; Add to "Open with" list for .md files (Windows 10/11)
  WriteRegStr HKLM "Software\Classes\.md\OpenWithList\${PRODUCT_EXE_NAME}" "" ""
  WriteRegStr HKLM "Software\Classes\.markdown\OpenWithList\${PRODUCT_EXE_NAME}" "" ""

  ; Notify the shell that file associations have changed
  System::Call 'shell32.dll::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
SectionEnd

; --- Section: Start Menu Shortcuts ---
Section "Create Start Menu shortcuts" SEC03
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${PRODUCT_NAME}.lnk" \
      "$INSTDIR\${PRODUCT_EXE_NAME}" "" "$INSTDIR\icon.ico" 0
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall ${PRODUCT_NAME}.lnk" \
      "$INSTDIR\uninstall.exe" "" "$INSTDIR\icon.ico" 0
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

; --- Section: Desktop Shortcut ---
Section "Create Desktop shortcut" SEC04
  CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" \
    "$INSTDIR\${PRODUCT_EXE_NAME}" "" "$INSTDIR\icon.ico" 0
SectionEnd

; ============================================================
; 6. Section Descriptions (shown in the "Components" page)
; ============================================================

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} "Core application files (required)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02} "Open .md and .markdown files with ${PRODUCT_NAME} when double-clicked"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC03} "Add shortcuts to the Start Menu"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC04} "Add a shortcut to the Desktop"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ============================================================
; 7. Uninstaller
; ============================================================

Section "Uninstall"
  ; --- Remove file associations (only our ProgID, not the .md root key) ---
  DeleteRegKey HKLM "Software\Classes\MarkdownViewer.Document"

  ; Only remove our extension pointer if it still points to us
  ReadRegStr $R0 HKLM "Software\Classes\.md" ""
  ${If} $R0 == "MarkdownViewer.Document"
    DeleteRegValue HKLM "Software\Classes\.md" ""
  ${EndIf}

  ReadRegStr $R0 HKLM "Software\Classes\.markdown" ""
  ${If} $R0 == "MarkdownViewer.Document"
    DeleteRegValue HKLM "Software\Classes\.markdown" ""
  ${EndIf}

  ; --- Remove registry keys ---
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  DeleteRegKey HKLM "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "Software\${PRODUCT_NAME}"

  ; --- Remove files ---
  Delete "$INSTDIR\${PRODUCT_EXE_NAME}"
  Delete "$INSTDIR\icon.ico"
  Delete "$INSTDIR\uninstall.exe"
  RMDir  "$INSTDIR"

  ; --- Remove shortcuts ---
  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  Delete "$SMPROGRAMS\$StartMenuFolder\${PRODUCT_NAME}.lnk"
  Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall ${PRODUCT_NAME}.lnk"
  RMDir  "$SMPROGRAMS\$StartMenuFolder"
  Delete "$DESKTOP\${PRODUCT_NAME}.lnk"

  ; Notify shell of changes
  System::Call 'shell32.dll::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
SectionEnd

; ============================================================
; 8. Installer Callbacks
; ============================================================

Function .onInit
  ; Check for a previous installation and offer to uninstall it
  ReadRegStr $R0 HKLM "${PRODUCT_UNINST_KEY}" "UninstallString"
  ${If} $R0 != ""
    ; Previous version found — ask the user what to do
    MessageBox MB_YESNOCANCEL|MB_ICONQUESTION \
      "${PRODUCT_NAME} is already installed.$\n$\nDo you want to uninstall the previous version first?$\n$\n(Click Cancel to abort this installation.)" \
      /SD IDYES IDYES UninstallOld IDNO SkipUninstall
    Abort  ; User clicked Cancel

    UninstallOld:
      ; Run the existing uninstaller silently, then continue
      ExecWait '"$R0" /S _?=$INSTDIR'
      ; Small delay to let the uninstaller fully exit and release file locks
      Sleep 500
      Delete "$INSTDIR\uninstall.exe"

    SkipUninstall:
      ; User chose No — install over the top (in-place upgrade)
  ${EndIf}
FunctionEnd
