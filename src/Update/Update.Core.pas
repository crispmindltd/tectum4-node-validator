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
  App.Types,
  Update.Utils,
  App.Logs;

type
  TUpdateCore = class
  private
    FStarted: Boolean;
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
    FThread: TThread;
    FEvent: TEvent;
    procedure OnThreadTerminate(Sender: TObject);
    procedure GetAvailableUpdates;
    procedure DownloadUpdatePackage;
  public
    constructor Create;
    destructor Destroy; override;
    class function RunAsUpdater: Boolean;
    procedure StartUpdate;
    procedure StopUpdate;
    property UpdatesRef: string write FUpdatesRef;
    property AppPath: string read FAppPath;
    property AppVersion: string read FAppVersion;
    property AppDate: TDateTime read FAppDate;
  end;

implementation

uses
  App.Intf;

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

procedure ToLog(const S: string);
begin
  Logs.DoLog(S, CmnLvlLogs);
end;

function CompareVersion(const Version1,Version2: string): Integer;

// Version1>Version2 --> Result>0
// Version1<Version2 --> Result<0
// Version1=Version2 --> Result=0

var V1,V2: Int64;
begin

  Result:=0;

  var A1:=Version1.Split(['.']);
  var A2:=Version2.Split(['.']);

  for var I:=Low(A1) to Min(High(A1),High(A2)) do
  if Result=0 then
    if TryStrToInt64(A1[I],V1) then
      if TryStrToInt64(A2[I],V2) then
        Result:=V1-V2
      else Result:=CompareStr(A1[I],A2[I])
    else Result:=CompareStr(A1[I],A2[I])
  else Exit;

end;

function ToGMTTime(Date: TDateTime): string;
begin
  Result:=FormatDateTime('ddd, dd mmm yyyy hh:nn:ss "GMT"',
    TTimeZone.Local.ToUniversalTime(Date),TFormatSettings.Create('en-US'));
end;

function FromGMTTime(const GMTTime: string): TDateTime;
begin
  Result:=TCookie.Create('id=; expires='+GMTTime,TURI.Create('http://com')).Expires;
end;

function AppRunAsUpdater: Boolean;
begin

  Result:=False;

  {$IF DEFINED(LINUX) OR DEFINED(MSWINDOWS)}
  Result:=ParamStr(1)='update';
  {$ENDIF}

end;

constructor TUpdateCore.Create;
begin

  FStarted:=False;

  FDownloadsPath:=TFolder.GetTempPath;
  FAppPath:=TFolder.GetAppPath;
  FAppVersion:=GetAppVersion;
  FAppDate:=TFile.GetLastWriteTime(FAppPath);
  FAvailableVersion:='';
  FAvailableDescription:='';
  FAvailableDate:=0;

  FEvent:=TEvent.Create;
  FEvent.ResetEvent;

end;

destructor TUpdateCore.Destroy;
begin
  StopUpdate;
  FEvent.Free;
end;

procedure CheckResponse(R: IHTTPResponse);
begin
  if R.StatusCode<>200 then
  if R.StatusText.IsEmpty then
    Stop(R.StatusCode.ToString+' No Reason Phrase')
  else
    Stop(R.StatusText);
end;

procedure TUpdateCore.GetAvailableUpdates;
var JSONUpdates,JSONPackage: TJSONValue;
begin

  ToLog('Download update info');

  var ResponseContent:=TMemoryStream.Create;

  AddRelease(ResponseContent);

  var Client:=THTTPClient.Create;

  AddRelease(Client);

  try

    var Response:=Client.Get(FUpdatesRef,ResponseContent);

    CheckResponse(Response);

    JSONUpdates:=TJSONObject.ParseJSONValue(TEncoding.ANSI.GetString(BytesOf(ResponseContent.Memory,ResponseContent.Size)),False,True);

    AddRelease(JSONUpdates);

    Require(JSONUpdates.TryGetValue(PACKAGE_IDENTITY,JSONPackage),'unknown package "'+PACKAGE_IDENTITY+'"');
    Require(JSONPackage.TryGetValue('path',URIPackage),'package path is not defined');
    Require(JSONPackage.TryGetValue('version',FAvailableVersion),'unknown version');
    Require(JSONPackage.TryGetValue('timestamp',FAvailableDate),'unknown version date');

    FAvailableDescription:=JSONPackage.GetValue('description','');

  except on E: Exception do
    raise ENetHTTPException.Create('impossible to get updates: '+E.Message);
  end;

  ToLog('Available version: '+FAvailableVersion+' '+DateTimeToStr(UnixToDateTime(FAvailableDate,False)));

end;

procedure TUpdateCore.DownloadUpdatePackage;
begin

  var ResponseContent:=TMemoryStream.Create;

  AddRelease(ResponseContent);

  var Client:=THTTPClient.Create;

  AddRelease(Client);

  ToLog('Download package: '+URIPackage);

  try

    DownloadPackage:=TPath.Combine(FDownloadsPath,URIPackage.Substring(URIPackage.LastIndexOf('/')+1));

    if TFile.Exists(DownloadPackage) then
      Client.CustomHeaders['If-Modified-Since']:=ToGMTTime(TFile.GetLastWriteTime(DownloadPackage));

    var Response:=Client.Get(URIPackage,ResponseContent);

    case Response.StatusCode of
    304: {nothing} ;
    200: begin
         ResponseContent.SaveToFile(DownloadPackage);
         TFile.SetLastWriteTime(DownloadPackage,FromGMTTime(Response.HeaderValue['Expires'])); //? Expires Last-Modified
         end;
    else
      CheckResponse(Response);
    end;

  except on E: Exception do
    raise ENetHTTPException.Create('impossible to download update: '+E.Message);
  end;

end;

class function TUpdateCore.RunAsUpdater: Boolean;
begin

  Result:=AppRunAsUpdater;

  if Result then
    UpdatePackage(ParamStr(2),ParamStr(3));

end;

procedure TUpdateCore.StartUpdate;
begin

  if FUpdatesRef.IsEmpty then Exit;

  if FStarted then

    FEvent.SetEvent

  else begin

    FStarted:=True;

    FThread:=TThread.CreateAnonymousThread(procedure
    begin

      repeat

        FEvent.ResetEvent;

        GetAvailableUpdates;

        if not FStarted then Break;

        var C:=CompareVersion(FAppVersion,FAvailableVersion);

        if C<0 then
        begin

          DownloadUpdatePackage;

          if not FStarted then Break;

          ToLog(Format('Update current version %s to %s',[FAppVersion,FAvailableVersion]));

          ToLog('Install package: '+DownloadPackage);

          UI.DoTerminate;
          AppCore.WaitForStop;

          if InstallPackage(DownloadPackage) then
            Break
          else
            ToLog('Package not installed');

        end;

      until (FEvent.WaitFor(INFINITE)=wrError) or not FStarted;

    end);

    FThread.FreeOnTerminate:=False;
    FThread.OnTerminate:=OnThreadTerminate;
    FThread.Start;

  end;

end;

procedure TUpdateCore.OnThreadTerminate(Sender: TObject);
begin

  FStarted:=False;

  var E:=TThread(Sender).FatalException as Exception;

  if Assigned(E) then ToLog('Update Exception: '+E.Message);

end;

procedure TUpdateCore.StopUpdate;
begin

  FStarted:=False;

  FEvent.SetEvent;

  if Assigned(FThread) then FThread.WaitFor;

  FThread.Free;
  FThread:=nil;

end;

end.
