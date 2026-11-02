#ifndef AppSource
 #error AppSource is required
#endif
#ifndef OutputDir
 #error OutputDir is required
#endif
#ifndef AppVersion
 #error AppVersion is required
#endif
#ifndef PackageBaseName
 #error PackageBaseName is required
#endif
[Setup]
AppId={{D7C89A67-AE47-4958-A425-24167395961F}
AppName=MacMarker
AppVersion={#AppVersion}
AppPublisher=Alexander Fisenkov
AppPublisherURL=https://alexfisenkov.github.io/MacMarker/
AppSupportURL=https://github.com/alexfisenkov/MacMarker/issues
DefaultDirName={localappdata}\Programs\MacMarker
DefaultGroupName=MacMarker
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.19041
OutputDir={#OutputDir}
OutputBaseFilename={#PackageBaseName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\MacMarker.exe
AppMutex=Local\MacMarker.Desktop
CloseApplications=yes
RestartApplications=no
DisableProgramGroupPage=yes
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
[Files]
Source: "{#AppSource}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{userprograms}\MacMarker"; Filename: "{app}\MacMarker.exe"
[Run]
Filename: "{app}\MacMarker.exe"; Description: "{cm:LaunchProgram,MacMarker}"; Flags: nowait postinstall skipifsilent
[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var StartupCommand: String;
begin
 if CurUninstallStep = usUninstall then
 begin
  if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'MacMarker', StartupCommand) then
   if CompareText(StartupCommand, '"' + ExpandConstant('{app}\MacMarker.exe') + '"') = 0 then
    RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'MacMarker');
 end;
end;
