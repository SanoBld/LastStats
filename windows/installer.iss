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
SetupIconFile=windows\runner\resources\app_icon.ico
WizardStyle=modern
DisableProgramGroupPage=yes
#if MyArch == "arm64"
ArchitecturesInstallIn64BitMode=arm64
ArchitecturesAllowed=arm64
#else
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french";  MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "build\windows\{#MyArch}\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\LastStats"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,LastStats}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\LastStats"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,LastStats}"; Flags: nowait postinstall skipifsilent
