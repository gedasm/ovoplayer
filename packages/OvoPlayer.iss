; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Cactus JukeBox"
#define MyAppVersion "0.4.2"
#define MyAppPublisher "Lazarus, Inc."
#define MyAppURL "http://www.lazarus.freepascal.org"
#define MyAppExeName "cactus_jukebox.exe"
                           
[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{540C04C4-8EB6-4837-AAA2-E4C94F6FD463}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName=C:\CactusJukeBox\
DefaultGroupName={#MyAppName}
LicenseFile=.\doc\CREDITS
InfoBeforeFile=.\doc\README
OutputBaseFilename=setup
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "cactus_jukebox.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "cactus.cfg"; DestDir: "{app}"; Flags: ignoreversion
Source: "mplayer.cfg"; DestDir: "{app}"; Flags: ignoreversion
Source: "doc\*"; DestDir: "{app}\doc\"; Flags: ignoreversion recursesubdirs createallsubdirs 
Source: "icon\*"; DestDir: "{app}\icon\"; Flags: ignoreversion recursesubdirs createallsubdirs 
;Source: "plugins\*"; DestDir: "{app}\plugins\"; Flags: ignoreversion
Source: "skins\*"; DestDir: "{app}\skins\"; Flags: ignoreversion recursesubdirs createallsubdirs 
Source: "mplayer\*"; DestDir: "{app}\mplayer\"; Flags: ignoreversion recursesubdirs createallsubdirs 
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, "&", "&&")}}"; Flags: nowait postinstall skipifsilent

