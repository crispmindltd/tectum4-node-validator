unit Net.SocketA;

interface

uses
  System.Types,
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Threading,
  System.Net.Socket,
  Net.Types;

type
  TSameClient = class;
  TServerClient = class;
  TClient = class;
  TServer = class;

  TSameClientEvent = procedure (Client: TSameClient) of object;
  TReceiveEvent = procedure (Client: TSameClient; const Bytes: TBytes) of object;
  TClientEvent = procedure (Client: TClient) of object;
  TServerClientEvent = procedure (Client: TServerClient) of object;
  TServerEvent = procedure (Server: TServer) of object;
  TAcceptEvent = procedure (Socket: TSocket) of object;
  TLogEvent = procedure(const S: string; Level: TLevel) of object;

  TSameSocket = class abstract
  private
    FName: string;
    FSocket: TSocket;
    FCompleted: TEvent;
    FOnLog: TLogEvent;
    FAsyncThread: TThreadID;
  protected
    procedure CompleteReset;
    procedure CompleteSignal;
    procedure CompleteWait;
    procedure DoException(E: Exception);
    function GetName: string; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DoLog(const S: string; Level: TLevel);
    property Name: string read FName write FName;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

  TSameClient = class abstract (TSameSocket)
  private
    class var FClientCounter: UInt64;
  private
    FOnReceive: TReceiveEvent;
    procedure DoComplete; virtual;
    function GetRemoteAddress: string;
    function GenClienId: UInt64;
    procedure SetKeepAlive;
  protected
    procedure DoDisconnect; virtual; abstract;
    procedure DoReceive(const B: TBytes); virtual;
    procedure BeginReceive;
  public
    constructor Create(Socket: TSocket);
    destructor Destroy; override;
    procedure Send(const B: TBytes); overload;
    procedure Close;
    procedure Disconnect; virtual;
    function Connected: Boolean;
    property RemoteAddress: string read GetRemoteAddress;
    property OnReceive: TReceiveEvent read FOnReceive write FOnReceive;
  end;

  TClient = class(TSameClient)
  private
    FAddress: string;
    FPort: Word;
    FDisconnect: Boolean;
    FReconnect: TEvent;
    FReconnectInterval: Cardinal;
    FOnConnected: TClientEvent;
    FOnDisconnect: TClientEvent;
    procedure DoComplete; override;
    function GetName: string; override;
  protected
    procedure DoConnected; virtual;
    procedure DoDisconnect; override;
    procedure DoReconnect; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Connect;
    procedure Disconnect; override;
    property Address: string read FAddress write FAddress;
    property Port: Word read FPort write FPort;
    property OnConnected: TClientEvent read FOnConnected write FOnConnected;
    property OnDisconnect: TClientEvent read FOnDisconnect write FOnDisconnect;
  end;

  TServerClient = class(TSameClient)
  private
    FOnDisconnect: TServerClientEvent;
  protected
    procedure DoDisconnect; override;
  public
    constructor Accept(Socket: TSocket);
    destructor Destroy; override;
    procedure BeginReceive;
    property OnDisconnect: TServerClientEvent read FOnDisconnect write FOnDisconnect;
  end;

  TServer = class(TSameSocket)
  private
    FPort: Word;
    FOnStart: TServerEvent;
    FOnStop: TServerEvent;
    FOnAccept: TAcceptEvent;
    procedure Close;
    procedure DoComplete;
  protected
    procedure DoStart; virtual;
    procedure DoStop; virtual;
    procedure DoAccept(Socket: TSocket); virtual;
    function Started: Boolean;
    procedure BeginAccept;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    property Port: Word read FPort write FPort;
    property OnStart: TServerEvent read FOnStart write FOnStart;
    property OnStop: TServerEvent read FOnStop write FOnStop;
    property OnAccept: TAcceptEvent read FOnAccept write FOnAccept;
  end;

implementation

{ TSameSocket }

constructor TSameSocket.Create;
begin
  FCompleted := TEvent.Create;
end;

destructor TSameSocket.Destroy;
begin
  FSocket.Free;
  FCompleted.Free;
  DoLog('destroy',DEBUG);
end;

function TSameSocket.GetName: string;
begin
  Result := Name;
end;

procedure TSameSocket.DoException(E: Exception);
begin
  DoLog(E.ClassName + ': ' + E.Message, ERROR);
end;

procedure TSameSocket.DoLog(const S: string; Level: TLevel);
begin
  if Assigned(FOnLog) then FOnLog(GetName + ' ' + S, Level);
end;

procedure TSameSocket.CompleteSignal;
begin
  DoLog('CompleteSignal', DEBUG);
  FCompleted.SetEvent;
end;

procedure TSameSocket.CompleteReset;
begin
  DoLog('CompleteReset', DEBUG);
  TMonitor.Enter(FCompleted);
  try
    FCompleted.ResetEvent;
  finally
    TMonitor.Exit(FCompleted);
  end;
end;

procedure TSameSocket.CompleteWait;
begin
  DoLog('CompleteWait... enter', DEBUG);
  TMonitor.Enter(FCompleted);
  try
    if FAsyncThread <> TThread.CurrentThread.ThreadID then
      FCompleted.WaitFor;
  finally
    TMonitor.Exit(FCompleted);
  end;
  DoLog('CompleteWait... leave', DEBUG);
end;

{ TSameClient }

constructor TSameClient.Create(Socket: TSocket);
begin
  inherited Create;
  FSocket := Socket;
  FSocket.ReceiveTimeout := -1;
end;

destructor TSameClient.Destroy;
begin
  Disconnect;
  inherited;
end;

function TSameClient.GetRemoteAddress: string;
begin
  Result := ''; // FSocket.RemoteAddress; // linux build freezes on GetRemoteAddress
end;

function TSameClient.GenClienId: UInt64;
begin
  Inc(FClientCounter);
  Result := FClientCounter;
end;

procedure TSameClient.SetKeepAlive;
begin
  if FSocket.Handle = InvalidSocket then
    raise ESocketError.Create('Invalid socket handle');
  DoLog('set KeepAlive: ' + BoolToStr(System.Net.Socket.SetKeepAlive(FSocket.Handle, 3000, 1000), True), INFO);
end;

procedure TSameClient.Disconnect;
begin
  DoLog('Disconnect... enter', DEBUG);
  try
    Close;
    CompleteWait;
  finally
    DoLog('Disconnect... leave', DEBUG);
  end;
end;

procedure TSameClient.DoReceive(const B: TBytes);
begin
  if Assigned(OnReceive) then OnReceive(Self, B);
end;

function TSameClient.Connected: Boolean;
begin
  Result := TSocketState.Connected in FSocket.State;
end;

procedure TSameClient.Close;
begin
  TMonitor.Enter(Self);
  try
    if Connected then
    begin
      FSocket.Close;
      DoLog('closed', INFO);
    end;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TSameClient.DoComplete;
begin
  DoLog('DoComplete', DEBUG);
  Close;
  CompleteSignal;
  DoDisconnect;
end;

procedure TSameClient.Send(const B: TBytes);
begin

  DoLog('send ' + Length(B).ToString + ' bytes', TRACE);

  try
    if FSocket.Send(B) = -1 then
      raise ESocketError.Create('Unable to send data when connection is closed');
  except on E: Exception do
    DoException(E);
  end;

end;

procedure TSameClient.BeginReceive;
begin

  FSocket.BeginReceive(procedure (const ASyncResult: IAsyncResult)
  begin

    FAsyncThread := TThread.CurrentThread.ThreadID;

    try

      var B := FSocket.EndReceiveBytes(ASyncResult);
      var ReceiveLength := Length(B);

      if ReceiveLength > 0 then
      begin
        DoLog('received ' + ReceiveLength.ToString + ' bytes', TRACE);
        DoReceive(B);
        if FSocket.Handle <> InvalidSocket then
        begin
          BeginReceive;
          Exit;
        end;
      end else
        DoLog('received ' + ReceiveLength.ToString + ' bytes (closed)', DEBUG);

    except on E: Exception do
      DoException(E);
    end;

    DoComplete;

  end);

  // The calling thread must not be the same thread on which the asynchronous function will be called.
  // Therefore, the current thread must be delayed until the asynchronous thread starts.
  // Otherwise, exceptions are not handled.

  Sleep(10);

end;

{ TClient }

constructor TClient.Create;
begin
  inherited Create(TSocket.Create(TSocketType.TCP, TEncoding.ANSI));
  Name := 'Client_' + GenClienId.ToString;
  FDisconnect := False;
  FReconnectInterval := 1000;
  FReconnect := TEvent.Create;
  CompleteSignal;
end;

destructor TClient.Destroy;
begin
  inherited;
  FReconnect.Free;
end;

function TClient.GetName: string;
begin
  Result := inherited + '/' + Address;
end;

procedure TClient.DoComplete;
begin
  FReconnect.ResetEvent;
  inherited;
  FDisconnect := False;
end;

procedure TClient.Disconnect;
begin
  FDisconnect := True;
  inherited;
  FReconnect.SetEvent;
end;

procedure TClient.DoConnected;
begin
  if Assigned(FOnConnected) then FOnConnected(Self);
end;

procedure TClient.DoDisconnect;
begin
  DoLog('DoDisconnect', DEBUG);
  if Assigned(FOnDisconnect) then FOnDisconnect(Self);
  DoReconnect;
end;

procedure TClient.DoReconnect;
begin
  if not FDisconnect then
  if Assigned(FReconnect) then
  if FReconnect.WaitFor(FReconnectInterval) = wrTimeout then
    Connect;
end;

procedure TClient.Connect;
begin

  CompleteReset;

  DoLog('connecting to... ' + Address, INFO);

  FSocket.BeginConnect(procedure (const ASyncResult: IAsyncResult)
  begin

    FAsyncThread := TThread.CurrentThread.ThreadID;

    try

      FSocket.EndConnect(ASyncResult);

      if not Connected then // TODO: fix
        raise ESocketError.Create('Unhandled connection error');

      DoLog('connected to ' + Address, INFO);

      SetKeepAlive;
      DoConnected;
      BeginReceive;

      Exit;

    except on E: Exception do
      DoException(E);
    end;

    DoComplete;

  end,

  Address,'','',Port);

  Sleep(100);

end;

{ TServerClient }

constructor TServerClient.Accept(Socket: TSocket);
begin
  Create(Socket);
  FSocket.Encoding := TEncoding.ANSI;
  Name := 'ServerClient_' + GenClienId.ToString + '/' + RemoteAddress;
end;

destructor TServerClient.Destroy;
begin
  inherited;
end;

procedure TServerClient.DoDisconnect;
begin
  DoLog('DoDisconnect', DEBUG);
  if Assigned(FOnDisconnect) then FOnDisconnect(Self);
end;

procedure TServerClient.BeginReceive;
begin
  DoLog('accepted from ' + RemoteAddress, DEBUG);
  SetKeepAlive;
  CompleteReset;
  inherited BeginReceive;
end;

{ TServer }

constructor TServer.Create;
begin
  inherited;
  FName := 'Server';
  FSocket := TSocket.Create(TSocketType.TCP, TEncoding.ANSI);
  FSocket.ReceiveTimeout := -1;
  CompleteSignal;
end;

destructor TServer.Destroy;
begin
  Stop;
  inherited;
end;

procedure TServer.Close;
begin
  if Started then
  begin
    DoLog('stopping...', DEBUG);
    FSocket.Close{$IFDEF MSWINDOWS}(True){$ENDIF};
  end;
end;

procedure TServer.Start;
begin
  FSocket.Listen('', '', Port); // raised exception if listen already in use
  DoLog('started at port: ' + Port.ToString, INFO);
  CompleteReset;
  BeginAccept;
end;

procedure TServer.BeginAccept;
begin

  FSocket.BeginAccept(procedure (const ASyncResult: IAsyncResult)
  begin

    FAsyncThread := TThread.CurrentThread.ThreadID;

    try

      var Socket:=FSocket.EndAccept(ASyncResult);

      if Assigned(Socket) then
      begin
        DoAccept(Socket);
        BeginAccept;
        Exit;
      end;

    except on E: Exception do
      DoException(E);
    end;

    DoComplete;

  end);

  Sleep(10);

end;

function TServer.Started: Boolean;
begin
  Result := TSocketState.Connected in FSocket.State;
end;

procedure TServer.Stop;
begin
  if Started then
  begin
    Close;
    CompleteWait;
    DoLog('stopped', INFO);
  end;
end;

procedure TServer.DoAccept(Socket: TSocket);
begin
  DoLog('accept client', INFO);
  if Assigned(FOnAccept) then FOnAccept(Socket);
end;

procedure TServer.DoStart;
begin
  if Assigned(FOnStart) then FOnStart(Self);
end;

procedure TServer.DoStop;
begin
  DoLog('DoStop', DEBUG);
  if Assigned(FOnStop) then FOnStop(Self);
end;

procedure TServer.DoComplete;
begin
  DoLog('DoComplete', DEBUG);
  Close;
  CompleteSignal;
  DoStop;
end;

end.
