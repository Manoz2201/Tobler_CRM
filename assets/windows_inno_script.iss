[Setup]
AppName=Tobler CRM
AppVersion=1.0
AppPublisher=Tobler India
DefaultDirName={commonpf}\Tobler\Tobler CRM
DefaultGroupName=Tobler CRM
OutputDir=D:\aryesha aPP\Crm_Aryesha\Crm_Tobler\installer
OutputBaseFilename=Tobler India
Compression=lzma
SolidCompression=yes
PrivilegesRequired=lowest
AllowNoIcons=yes
DisableProgramGroupPage=no
DisableDirPage=no
DisableReadyPage=no
SetupIconFile=D:\aryesha aPP\Crm_Aryesha\Crm_Tobler\assets\toblerIcon.ico
UninstallDisplayIcon={app}\Tobler.exe

[Files]
Source: "D:\aryesha aPP\Crm_Aryesha\Crm_Tobler\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Tobler CRM"; Filename: "{app}\Tobler.exe"; IconFilename: "{app}\Tobler.exe"
Name: "{group}\Uninstall Tobler CRM"; Filename: "{uninstallexe}"; IconFilename: "{app}\Tobler.exe"
Name: "{commondesktop}\Tobler CRM"; Filename: "{app}\Tobler.exe"; IconFilename: "{app}\Tobler.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"
