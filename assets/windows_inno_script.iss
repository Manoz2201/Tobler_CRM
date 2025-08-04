[Setup]
AppName=Tobler
AppVersion=1.0
DefaultDirName={pf}\Tobler\Tobler
DefaultGroupName=Aluminum Formwork CRM
OutputDir=D:\App\ToblerApps\Tobler\AluminumFormworkCRM\installer
OutputBaseFilename=Tobler India
Compression=lzma
SolidCompression=yes

[Files]
Source: "D:\App\ToblerApps\Tobler\AluminumFormworkCRM\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Aluminum Formwork CRM"; Filename: "{app}\Tobler.exe"
Name: "{group}\Uninstall Aluminum Formwork CRM"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Aluminum Formwork CRM"; Filename: "{app}\Tobler.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"
