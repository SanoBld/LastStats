; LastStats Windows installer script (Inno Setup)
; Compiled by the CI workflow — see .github/workflows/build-windows.yml
;
; Usage: ISCC.exe windows\installer.iss /DMyArch=x64   (or arm64)
;        with env var APP_VERSION set (e.g. "2.7.0")
;
; NOTE: assumes the built exe is named "laststats_mobile.exe" (from the
; pubspec.yaml project name). If the actual exe has a different name,
; update MyAppExeName below.

#define MyAppExeName "laststats_mobile.exe"
#define MyAppVersion GetEnv("APP_VERSION")
#ifndef MyArch
  #define MyArch "x64"
#endif

[Setup]
AppId={{8F2E4C1A-9B3D-4E5F-A123-1234567890AB}
AppName=LastStats
AppVersion={#MyAppVersion}
AppPublisher=SanoBld
AppPublisherURL=https://github.com/SanoBld/LastStats
DefaultDirName={autopf}\LastStats
DefaultGroupName=LastStats
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputBaseFilename=LastStats-Setup-{#MyArch}
OutputDir=installer_output
Compression=lzma
SolidCompression=yes
SetupIconFile=runner\resources\app_icon.ico
WizardStyle=modern
DisableProgramGroupPage=yes
CloseApplications=yes
RestartApplications=yes
#if MyArch == "arm64"
ArchitecturesInstallIn64BitMode=arm64
ArchitecturesAllowed=arm64
#else
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
#endif

[Languages]
Name: "english";           MessagesFile: "compiler:Default.isl"
Name: "french";            MessagesFile: "compiler:Languages\French.isl"
Name: "spanish";           MessagesFile: "compiler:Languages\Spanish.isl"
Name: "german";            MessagesFile: "compiler:Languages\German.isl"
Name: "italian";           MessagesFile: "compiler:Languages\Italian.isl"
Name: "portuguese";        MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "japanese";          MessagesFile: "compiler:Languages\Japanese.isl"
Name: "russian";           MessagesFile: "compiler:Languages\Russian.isl"
Name: "arabic";            MessagesFile: "compiler:Languages\Arabic.isl"
; Chinese (Simplified) is NOT bundled with Inno Setup and has no reliably
; reachable official download URL — left out rather than risk another
; broken build. Can be added later with a verified source if needed.

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\{#MyArch}\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\LastStats"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,LastStats}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\LastStats"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,LastStats}"; Flags: nowait postinstall skipifsilent
