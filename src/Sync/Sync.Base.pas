unit Sync.Base;

interface

uses
  App.Exceptions,
  App.Intf,
  App.Logs,
  App.Updater,
  Classes,
  Crypto,
  Math,
  Net.Data,
  Net.Socket,
  SysUtils;

type
  TSyncChain = class(TThread)
    const
      RequestDelay = 500;
      ReceiveTimeout = 5000;
      ReconnectAttempts = 2;
    private
      FConnectStatus: Byte;
      FIsUpgrading: Boolean;
      FOnDoTerminate: TNotifyEvent;

      function Connect: Boolean;
      procedure Disconnect;
      function GetNodeAddress: string;
    protected
      FBytesRequest: array[0..8] of Byte;
      FSocket: TSocket;
      FAddress: string;
      FPort: Word;

      procedure Execute; override;
      function GetResponse(Amount:Integer):TBytes;
      procedure BreakableSleep(ADelayDuration: Integer);
      function DoTryReconnect: Boolean;
      procedure DoCantReconnect;
      procedure DoTerminate; override;
      function InitConnect: Boolean;
      procedure GetVersionInfo;
    public
      constructor Create(AAddress: string; APort: Word);
      destructor Destroy; override;

      property Status: Byte read FConnectStatus;
      property UpdateInProgress: Boolean read FIsUpgrading;
      property Address: string read GetNodeAddress;
      property OnDoTerminate: TNotifyEvent write FOnDoTerminate;
  end;

implementation

{ TSyncChain }

procedure TSyncChain.BreakableSleep(ADelayDuration: Integer);
var
  DelayValue: Integer;
begin
  repeat
    DelayValue := Min(ADelayDuration, 500);
    Sleep(DelayValue);
    Dec(ADelayDuration, DelayValue);
  until Terminated or (ADelayDuration = 0);
end;

function TSyncChain.Connect: Boolean;
var
  Endpoint: TNetEndpoint;
begin
  Result := True;
  try
    FSocket.Connect('', FAddress, '', FPort);
  except
    try
      Endpoint := TNetEndpoint.Create(TIPAddress.LookupName(FAddress), FPort);
      FSocket.Connect(Endpoint);
    except
      Result := False;
    end;
  end;
  if Result then
  begin
    Result := InitConnect;
    if not Result then
    begin
      Logs.DoLog('Error initializing connection', ERROR);
      FConnectStatus := 3;
    end;
  end else
  begin
    Logs.DoLog(Format('Cant connect to %s', [Address]), ERROR);
    FConnectStatus := 1;
  end;
end;

constructor TSyncChain.Create(AAddress: string; APort: Word);
begin
  inherited Create(True);

  FreeOnTerminate := True;
  FSocket := TSocket.Create(TSocketType.TCP, TEncoding.ANSI);
  FAddress := AAddress;
  FPort := APort;
  FIsUpgrading := False;
end;

destructor TSyncChain.Destroy;
begin
  Disconnect;
  FSocket.Free;

  inherited;
end;

procedure TSyncChain.Disconnect;
begin
  if TSocketState.Connected in FSocket.State then
  {$IFDEF MSWINDOWS}
    FSocket.Close(True);
  {$ELSE IFDEF LINUX}
    FSocket.Close;
  {$ENDIF}
end;

procedure TSyncChain.DoCantReconnect;
begin
  Logs.DoLog('Reconnect', ERROR);
  FConnectStatus := 2;
end;

procedure TSyncChain.DoTerminate;
begin
  inherited;

  FOnDoTerminate(Self);
end;

function TSyncChain.DoTryReconnect: Boolean;
var
  i: Integer;
begin
  Disconnect;
  i := 0;
  repeat
    BreakableSleep(50 * i);
    if Terminated then
      exit(True);

    Result := Connect;
    Inc(i);
  until Result or (i = ReconnectAttempts);
end;

procedure TSyncChain.Execute;
begin
  inherited;

  if not Connect then
  begin
    BreakableSleep(1000);
    exit;
  end;

  FConnectStatus := 0;
  Logs.DoLog(Format('Connected to %s', [Address]), NONE);
  UI.DoMessage(Format('Connected to %s', [Address]));
end;

function TSyncChain.GetNodeAddress: string;
begin
  Result := Format('%s:%d', [FAddress, FPort]);
end;

function TSyncChain.GetResponse(Amount:Integer):TBytes;
var
  StartTime: Cardinal;
  ToReceive, ReceivedPart, ReceivedTotal: Integer;
begin
  StartTime := GetTickCount;
  ReceivedTotal := 0;
  ToReceive := Amount;
  SetLength(Result, Amount);

  while ToReceive > 0 do
  begin
    while FSocket.ReceiveLength <= 0 do
    begin
      if Terminated then
        exit;
      if IsTimeout(StartTime, ReceiveTimeout) then
        raise EReceiveTimeout.Create('');
      Sleep(50);
    end;

    ReceivedPart := Min(ToReceive, FSocket.ReceiveLength);
    FSocket.Receive(Result, ReceivedTotal, ReceivedPart, [TSocketFlag.WAITALL]);
    Dec(ToReceive, ReceivedPart);
    Inc(ReceivedTotal, ReceivedPart);
  end;
end;

procedure TSyncChain.GetVersionInfo;
var
  VersionIncom: TVersionBytes;
  Status: Byte;
  IncomCountBytes: array[0..3] of Byte;
  IncomCount: Integer absolute IncomCountBytes;
  LinkBytes: TBytes;
begin
  FSocket.Receive(VersionIncom, 0, 2, [TSocketFlag.WAITALL]);
  FSocket.Receive(Status, 0, 1);
  FSocket.Receive(IncomCountBytes, 0, 4, [TSocketFlag.WAITALL]);

  LinkBytes := GetResponse(IncomCount);

  FIsUpgrading := Updater.CheckAndUpdate(VersionIncom, Status,
    TEncoding.ANSI.GetString(LinkBytes));
end;

function TSyncChain.InitConnect: Boolean;
var
  Answer: Byte;
  Bytes: TBytes;
  TextToSign, Sign: string;
begin
  try
    FSocket.Send([InitConnectCode]);
    Bytes := GetResponse(32);
    TextToSign := TEncoding.ANSI.GetString(Bytes);
    ECDSASignText(TextToSign, HexToBytes(AppCore.PrKey), Sign);
    Bytes := TEncoding.ANSI.GetBytes(Format('%s %s', [Sign, AppCore.PubKey]));
    const Len = Length(Bytes);
    FSocket.Send(BytesOf(@Len, 4) + Bytes);
    FSocket.Receive(Answer, 0, 1, [TSocketFlag.WAITALL]);
    Result := Answer = SuccessCode;
  except
    Result := False;
  end;
end;

end.

