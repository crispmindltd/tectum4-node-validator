unit Update.Core;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  System.Classes,
  System.DateUtils,
  System.Math,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.SyncObjs,
  System.Threading,
  App.Types,
  App.Intf,
  App.Logs,
  Update.Utils;

type
  TLevel = (TRACE=0, DEBUG=1, INFO=2, ERROR=3, FATAL=4);

  TUpdateCore = class
  private
    FTask: ITask;
    FUpdatesRef: string;
    FAppPath: string;
    FAppVersion: string;
    FAppDate: TDateTime;
    FAvailableVersion: string;
    FAvailableDescription: string;
    FAvailableDate: Int64;
    FDownloadsPath: string;
    DownloadPackage: string;
    URIPackage: string;
    procedure GetAvailableUpdates;
    procedure DownloadUpdatePackage;
    procedure DoLog(const S: string; Level: TLevel);
  public
    constructor Create;
    destructor Destroy; override;
    class function RunAsUpdater: Boolean;
    procedure StartUpdate;
    property UpdatesRef: string write FUpdatesRef;
    property AppPath: string read FAppPath;
    property AppVersion: string read FAppVersion;
    property AppDate: TDateTime read FAppDate;
  end;

implementation

const
  PACKAGE_IDENTITY =
    {$IFDEF MSWINDOWS}'windows-'{$ENDIF}
    {$IFDEF ANDROID}'android-'{$ENDIF}
    {$IFDEF MACOS}{$IFDEF IOS}'ios-'{$ELSE}'macos-'{$ENDIF}{$ENDIF}
    {$IFDEF LINUX}'linux-'{$ENDIF}
    {$IFDEF CONSOLE}+'console-'{$ELSE}
      {$IFDEF MSWINDOWS}+'desktop-'{$ENDIF}
      {$IFDEF ANDROID}+'mobile-'{$ENDIF}
      {$IFDEF MACOS}{$IFDEF IOS}+'mobile-'{$ELSE}+'desktop-'{$ENDIF}{$ENDIF}
      {$IFDEF LINUX}+'desktop-'{$ENDIF}
    {$ENDIF}
    {$IFDEF CPU32BITS}+'x32'{$ELSE}+'x64'{$ENDIF};

{$SCOPEDENUMS ON}

type
  TMatches = (Low, Matches, High);

function MatchesVersion(const Version1, Version2: string): TMatches;
var V1, V2: Integer;
begin

  var Compare := 0;

  var A1 := Version1.Split(['.']);
  var A2 := Version2.Split(['.']);

  for var I := Low(A1) to Min(High(A1), High(A2)) do
  if Compare = 0 then
    if TryStrToInt(A1[I], V1) then
      if TryStrToInt(A2[I], V2) then
        Compare := V1-V2
      else Compare := CompareStr(A1[I], A2[I])
    else Compare := CompareStr(A1[I], A2[I])
  else Break;

  if Compare < 0 then Result := TMatches.Low else
  if Compare > 0 then Result := TMatches.High else
    Result := TMatches.Matches;

end;

function ToGMTTime(Date: TDateTime): string;
begin
  Result := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss "GMT"',
    TTimeZone.Local.ToUniversalTime(Date), TFormatSettings.Create('en-US'));
end;

function FromGMTTime(const GMTTime: string): TDateTime;
begin
  Result := TCookie.Create('id=; expires=' + GMTTime, TURI.Create('http://com')).Expires;
end;

function AppRunAsUpdater: Boolean;
begin

  Result := False;

  {$IF DEFINED(LINUX) OR DEFINED(MSWINDOWS)}
  Result := ParamStr(1) = 'update';
  {$ENDIF}

end;

constructor TUpdateCore.Create;
begin
  FDownloadsPath := TFolder.GetTempPath;
  FAppPath := TFolder.GetAppPath;
  FAppVersion := GetAppVersion;
  FAppDate := TFile.GetLastWriteTime(FAppPath);
  FAvailableVersion := '';
  FAvailableDescription := '';
  FAvailableDate := 0;
end;

destructor TUpdateCore.Destroy;
begin
  if Assigned(FTask) then
  if FTask.Status <> TTaskStatus.Completed then
  begin
    DoLog('Waiting for update task to complete...', INFO);
    FTask.Wait;
  end;
  inherited;
end;

procedure TUpdateCore.DoLog(const S: string; Level: TLevel);
begin
  case Level of
  TRACE: Logs.DoLog(S, DbgLvlLogs, ltNone);
  DEBUG: Logs.DoLog(S, DbgLvlLogs, ltNone);
  INFO: Logs.DoLog(S, CmnLvlLogs, ltNone);
  ERROR: Logs.DoLog(S, CmnLvlLogs, ltError);
  FATAL: Logs.DoLog(S, CmnLvlLogs, ltError);
  end;
end;

procedure CheckResponse(R: IHTTPResponse);
begin
  if R.StatusCode <> 200 then
  if R.StatusText.IsEmpty then
    Stop(R.StatusCode.ToString + ' No Reason Phrase')
  else
    Stop(R.StatusText);
end;

procedure TUpdateCore.GetAvailableUpdates;
var JSONUpdates, JSONPackage: TJSONValue;
begin

  DoLog('Download update info', INFO);

  var ResponseContent := TMemoryStream.Create;

  AddRelease(ResponseContent);

  var Client := THTTPClient.Create;

  AddRelease(Client);

  try

    var Response := Client.Get(FUpdatesRef, ResponseContent);

    CheckResponse(Response);

    JSONUpdates := TJSONObject.ParseJSONValue(TEncoding.ANSI.GetString(BytesOf(ResponseContent.Memory, ResponseContent.Size)), False, True);

    AddRelease(JSONUpdates);

    Require(JSONUpdates.TryGetValue(PACKAGE_IDENTITY, JSONPackage),'unknown package "' + PACKAGE_IDENTITY + '"');
    Require(JSONPackage.TryGetValue('path', URIPackage), 'package path is not defined');
    Require(JSONPackage.TryGetValue('version', FAvailableVersion), 'unknown version');
    Require(JSONPackage.TryGetValue('timestamp', FAvailableDate), 'unknown version date');

    FAvailableDescription := JSONPackage.GetValue('description','');

  except on E: Exception do
    raise ENetHTTPException.Create('impossible to get updates: ' + E.Message);
  end;

  DoLog('Available version: ' + FAvailableVersion + ' ' + DateTimeToStr(UnixToDateTime(FAvailableDate, False)), INFO);

end;

procedure TUpdateCore.DownloadUpdatePackage;
begin

  var ResponseContent := TMemoryStream.Create;

  AddRelease(ResponseContent);

  var Client := THTTPClient.Create;

  AddRelease(Client);

  DoLog('Download package: ' + URIPackage, INFO);

  try

    DownloadPackage := TPath.Combine(FDownloadsPath, URIPackage.Substring(URIPackage.LastIndexOf('/') + 1));

    if TFile.Exists(DownloadPackage) then
      Client.CustomHeaders['If-Modified-Since'] := ToGMTTime(TFile.GetLastWriteTime(DownloadPackage));

    var Response := Client.Get(URIPackage, ResponseContent);

    case Response.StatusCode of
    304: {nothing} ;
    200: begin
         ResponseContent.SaveToFile(DownloadPackage);
         TFile.SetLastWriteTime(DownloadPackage, FromGMTTime(Response.HeaderValue['Expires'])); //? Expires Last-Modified
         end;
    else
      CheckResponse(Response);
    end;

  except on E: Exception do
    raise ENetHTTPException.Create('impossible to download update: ' + E.Message);
  end;

end;

class function TUpdateCore.RunAsUpdater: Boolean;
begin

  Result := AppRunAsUpdater;

  if Result then
    UpdatePackage(ParamStr(2), ParamStr(3));

end;

procedure TUpdateCore.StartUpdate;
begin

  Require(not FUpdatesRef.IsEmpty, 'Undefinite ref update');

  if not Assigned(FTask) or (FTask.Status = TTaskStatus.Completed) then

  FTask := TTask.Run(procedure
  begin

    try

      GetAvailableUpdates;

      if MatchesVersion(FAppVersion, FAvailableVersion) = TMatches.Low then
      begin

        DownloadUpdatePackage;

        DoLog(Format('Update current version %s to %s', [FAppVersion, FAvailableVersion]), INFO);

        DoLog('Install package: ' + DownloadPackage, INFO);

        AppCore.Stop;
        UI.DoTerminate;

        Require(InstallPackage(DownloadPackage), 'Package not installed');

      end;

    except on E: Exception do
      DoLog('Update Exception: ' + E.Message, ERROR);
    end;

  end);

end;

end.
