[Setup]
AppName=Sogutma Cevrimi Deney Izleme
AppVersion=1.0.0
AppPublisher=Berk Acar
AppPublisherURL=https://www.linkedin.com/in/berkacar/
DefaultDirName={autopf}\SogutmaCevrimi
DefaultGroupName=Sogutma Cevrimi
UninstallDisplayIcon={app}\SogutmaCevrimi.exe
OutputDir=.\build\installer
OutputBaseFilename=SogutmaCevrimi_Setup_v1.0
SetupIconFile=.\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Files]
Source: ".\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: ".\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\Sogutma Cevrimi"; Filename: "{app}\SogutmaCevrimi.exe"; IconFilename: "{app}\SogutmaCevrimi.exe"
Name: "{commondesktop}\Sogutma Cevrimi"; Filename: "{app}\SogutmaCevrimi.exe"; IconFilename: "{app}\SogutmaCevrimi.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Masaustune kisayol olustur"; GroupDescription: "Ek kisayollar:"

[Run]
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Visual C++ Runtime yukleniyor..."; Flags: waituntilterminated skipifsilent; Check: VCRedistNeedsInstall
Filename: "{app}\SogutmaCevrimi.exe"; Description: "Uygulamayi Baslat"; Flags: nowait postinstall skipifsilent

[Code]
function VCRedistNeedsInstall: Boolean;
begin
  Result := not FileExists(ExpandConstant('{sys}\vcruntime140.dll'));
end;
