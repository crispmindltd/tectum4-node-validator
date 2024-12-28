unit App.Updater;

interface

uses
  App.Intf,
  Classes,
//  FMX.Types,
  IOUtils,
  SysUtils,
  {$IFDEF MSWINDOWS}
  Winapi.Windows, Winapi.ShellAPI
  {$ELSE}
  Posix.Stdlib
  {$ENDIF};

const
  BatText = '@echo off' + sLineBreak +
            'echo Please wait until update is done' + sLineBreak +
            'set currentDir=%~dp0' + sLineBreak +
            'if "%currentDir:~-1%"=="\" set "currentDir=%currentDir:~0,-1%"' + sLineBreak +
            'echo Loading new version...' + sLineBreak +
            'powershell -Command "(New-Object System.Net.WebClient).DownloadFile(''#URLexe#'', ''%currentDir%\#NAMEexe#'')"' + sLineBreak +
            'taskkill /IM #OldNAMEexe# /F' + sLineBreak +
            'start "" "%currentDir%\#NAMEexe#"' + sLineBreak +
            'timeout /t 2 >nul' + sLineBreak +
            'tasklist | findstr /i #NAMEexe# >nul && (' + sLineBreak +
            'echo Success' + sLineBreak +
            ') || (' + sLineBreak +
            'echo Update failed. Launching previous version...' + sLineBreak +
            'start "" "%currentDir%\#OldNAMEexe#")';

type
  TVersionBytes = array[0..1] of Byte;

  TNodeUpdater = class
  const
    NodeVersion = 'v4.0.100 beta';
    VersionRequestDelay = 5000;
  strict private
    FStatus: Byte;
    FLinkToExe: string;
  private
    FPathToBat: string;
    FPathToFile: string;
//    FCheckVerTimer: TTimer;

    procedure CheckVersionFromFile(Sender: TObject);
    function GetVersion: string;
    function GetStringVersion(const AVerBytes: TVersionBytes): string;
    function GetMajorVersion: Byte;
    function GetMinorVersion: Byte;
    function GetVersionAsBytes: TVersionBytes;
    function GetTxtLink: string;
    procedure DoUpdate;
    procedure RemoveOldUpdater;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Run;
    function CheckAndUpdate(const AVersion: string; AStatus: Byte;
      ALink: string): Boolean; overload;
    function CheckAndUpdate(const AVerBytes: TVersionBytes;
      AStatus: Byte; ALink: string): Boolean; overload;

    property CurVersion: string read GetVersion;
    property CurVersionAsBytes: TVersionBytes read GetVersionAsBytes;
    property Status: Byte read FStatus write FStatus;
    property LinkToExe: string read FLinkToExe write FLinkToExe;
  end;

var
  Updater: TNodeUpdater;

implementation

{ TNodeUpdater }

function ExtractFileNameFromUrl(const AUrl: string): string;
var
  LastPos: Integer;
begin
  LastPos := LastDelimiter('/', AUrl);
  if LastPos > 0 then
    Result := Copy(AUrl, LastPos + 1, MaxInt)
  else
    Result := '';
end;

function ExtractFilePathFromUrl(const AUrl: string): string;
var
  LastPos: Integer;
begin
  LastPos := LastDelimiter('/', AUrl);
  if LastPos > 0 then
    Result := Copy(AUrl, 1, LastPos - 1)
  else
    Result := '';
end;

procedure RunExecutable(const ExeName: string; const Parameters: string = '');
begin
  {$IFDEF MSWINDOWS}
  ShellExecute(0, 'OPEN', PChar(ExeName), PChar(Parameters), nil, SW_SHOWNORMAL);
  {$ENDIF}

  {$IFDEF MACOS}
  _system(PAnsiChar('./' + ExeName + ' ' + Parameters));
  {$ENDIF}

  {$IFDEF LINUX}
  _system(PAnsiChar('./' + ExeName + ' ' + Parameters));
  {$ENDIF}
end;

function TNodeUpdater.CheckAndUpdate(const AVerBytes: TVersionBytes;
  AStatus: Byte; ALink: string): Boolean;
begin
  Result := CheckAndUpdate(GetStringVersion(AVerBytes), AStatus, ALink);
end;

function TNodeUpdater.CheckAndUpdate(const AVersion: string; AStatus: Byte;
  ALink: string): Boolean;
begin
  Result := False;
  FStatus := AStatus;
  FLinkToExe := ALink;
  if AVersion <> NodeVersion then
  begin
    UI.ShowVersionDidNotMatch;
    if FStatus > 0 then
    begin
      Result := True;
      DoUpdate;
    end;
  end;
end;

procedure TNodeUpdater.CheckVersionFromFile(Sender: TObject);
var
  FileStrings: TStringList;
begin
  if FileExists(FPathToFile) then
  begin
    FileStrings := TStringList.Create;
    try
      FileStrings.Clear;
      FileStrings.LoadFromFile(FPathToFile);
//      FCheckVerTimer.Enabled := not CheckAndUpdate(FileStrings.Strings[0],
//        FileStrings.Strings[1].ToInteger, FileStrings.Strings[2]);
    finally
      FileStrings.Free;
    end;
  end else
//    FCheckVerTimer.Enabled := False;
end;

constructor TNodeUpdater.Create;
begin
  FPathToBat := TPath.Combine(ExtractFilePath(ParamStr(0)), 'update.bat');
  FPathToFile := TPath.Combine(ExtractFilePath(ParamStr(0)), '1.txt');
//  FCheckVerTimer := nil;
  FStatus := 0;
  FLinkToExe := '';
end;

destructor TNodeUpdater.Destroy;
begin
//  FCheckVerTimer.Free;

  inherited;
end;

procedure TNodeUpdater.DoUpdate;
var
  BatLines: TStrings;
  PathBat: string;
begin
  UI.DoMessage('Please wait until update is done...');
  BatLines := TStringList.Create;
  try
    BatLines.Clear;
    BatLines.Text := BatText;
    BatLines.Text:= StringReplace(BatLines.Text, '#URLexe#', FLinkToExe, [rfReplaceAll]);
    BatLines.Text:= StringReplace(BatLines.Text, '#URLtxt#', GetTxtLink, [rfReplaceAll]);
    BatLines.Text:= StringReplace(BatLines.Text, '#NAMEexe#', ExtractFileNameFromUrl(FLinkToExe), [rfReplaceAll]);
    BatLines.Text:= StringReplace(BatLines.Text, '#NAMEtxt#', ChangeFileExt(ExtractFileNameFromUrl(GetTxtLink), '.tx'), [rfReplaceAll]);
    BatLines.Text:= StringReplace(BatLines.Text, '#OldNAMEexe#', ExtractFileName(ParamStr(0)), [rfReplaceAll]);
    PathBat:= IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'update.bat';

    try
      BatLines.SaveToFile(PathBat);
    except
      exit;
    end;
  finally
    BatLines.Free;
  end;

  RunExecutable(PathBat);
end;

function TNodeUpdater.GetMajorVersion: Byte;
begin
  Result := CurVersion.Replace('v', '').Split(['.', '_'])[0].ToInteger;
end;

function TNodeUpdater.GetMinorVersion: Byte;
begin
  Result := CurVersion.Replace('v', '').Split(['.', '_'])[1].ToInteger;
end;

function TNodeUpdater.GetTxtLink: string;
begin
  Result := ExtractFilePathFromUrl(FLinkToExe) + '/1.txt';
end;

function TNodeUpdater.GetVersion: string;
begin
  Result := NodeVersion;
end;

function TNodeUpdater.GetVersionAsBytes: TVersionBytes;
begin
  Result[0] := GetMajorVersion;
  Result[1] := GetMinorVersion;
end;

procedure TNodeUpdater.RemoveOldUpdater;
begin
  if FileExists(FPathToBat) then
    SysUtils.DeleteFile(FPathToBat);
end;

procedure TNodeUpdater.Run;
begin
  RemoveOldUpdater;
  if FileExists(FPathToFile) then
  begin
//    FCheckVerTimer := TTimer.Create(nil);
//    FCheckVerTimer.OnTimer := CheckVersionFromFile;
//    FCheckVerTimer.Interval := VersionRequestDelay;
    CheckVersionFromFile(nil);
  end;
end;

function TNodeUpdater.GetStringVersion(const AVerBytes: TVersionBytes): string;
begin
  Result := Format('v%d.%d', [AVerBytes[0], AVerBytes[1]]);
end;

initialization
  Updater := TNodeUpdater.Create;

finalization
  Updater.Free;

end.
