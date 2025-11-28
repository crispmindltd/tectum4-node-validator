unit Net.SocketA;

interface

uses
  System.Types,
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Threading,
  System.Net.Socket,
  App.Types;

type
  TConnection = class;
  TServerConnection = class;
  TClientConnection = class;
  TSocketServer = class;

  TConnectionDisconnectEvent = procedure (Client: TConnection) of object;
  TReceiveEvent = procedure (Client: TConnection; const Bytes: TBytes) of object;
  TClientEvent = procedure (Client: TClientConnection) of object;
  TServerEvent = procedure (Server: TSocketServer) of object;
  TAcceptEvent = procedure (Socket: TSocket) of object;
  TLogEvent = procedure(const S: string; Level: TLevel) of object;

  TAbstractSocket = class abstract
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

    procedure DoLogException(E: Exception);
    function GetName: string; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DoLog(const S: string; Level: TLevel);
    property Name: string read FName write FName;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

  TConnection = class abstract (TAbstractSocket)
  private
    class var FClientCounter: UInt64;
  private
    FOnReceive: TReceiveEvent;
    FOnDisconnect: TConnectionDisconnectEvent;
    procedure DoComplete; virtual;
    function GetRemoteAddress: string;
    function GenClienId: UInt64;
    procedure SetKeepAlive;
  protected
    procedure DoDisconnect; virtual;
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
    property OnDisconnect: TConnectionDisconnectEvent read FOnDisconnect write FOnDisconnect;
  end;

  TClientConnection = class(TConnection)
  private
    FAddress: string;
    FPort: Word;
    FDisconnect: Boolean;
    FReconnect: TEvent;
    FReconnectInterval: Cardinal;
    FOnConnected: TClientEvent;
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
  end;

  TServerConnection = class(TConnection)
  public
    constructor Accept(Socket: TSocket);
    procedure BeginReceive;
  end;

  TSocketServer = class(TAbstractSocket)
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

constructor TAbstractSocket.Create;
begin
  FCompleted := TEvent.Create;
end;

destructor TAbstractSocket.Destroy;
begin
  FSocket.Free;
  FCompleted.Free;
  DoLog('destroy',DEBUG);
end;

function TAbstractSocket.GetName: string;
begin
  Result := Name;
end;

procedure TAbstractSocket.DoLogException(E: Exception);
begin
  DoLog(E.ClassName + ': ' + E.Message, ERROR);
end;

procedure TAbstractSocket.DoLog(const S: string; Level: TLevel);
begin
  if Assigned(FOnLog) then FOnLog(GetName + ' ' + S, Level);
end;

procedure TAbstractSocket.CompleteSignal;
begin
  DoLog('CompleteSignal', DEBUG);
  FCompleted.SetEvent;
end;

procedure TAbstractSocket.CompleteReset;
begin
  DoLog('CompleteReset', DEBUG);
  Lock(FCompleted);
  FCompleted.ResetEvent;
end;

procedure TAbstractSocket.CompleteWait;
begin
  DoLog('CompleteWait... enter', DEBUG);
  Lock(FCompleted);
  if FAsyncThread <> TThread.CurrentThread.ThreadID then
    FCompleted.WaitFor;
  DoLog('CompleteWait... leave', DEBUG);
end;

{ TSameClient }

constructor TConnection.Create(Socket: TSocket);
begin
  inherited Create;
  FSocket := Socket;
  FSocket.ReceiveTimeout := -1;
end;

destructor TConnection.Destroy;
begin
  Disconnect;
  inherited;
end;

procedure TConnection.DoDisconnect;
begin
  DoLog('DoDisconnect', DEBUG);
  if Assigned(FOnDisconnect) then FOnDisconnect(Self);
end;

function TConnection.GetRemoteAddress: string;
begin
  Result := ''; // FSocket.RemoteAddress; // linux build freezes on GetRemoteAddress
end;

function TConnection.GenClienId: UInt64;
begin
  Inc(FClientCounter);
  Result := FClientCounter;
end;

procedure TConnection.SetKeepAlive;
begin
  if FSocket.Handle = InvalidSocket then
    raise ESocketError.Create('Invalid socket handle');
  DoLog('set KeepAlive: ' + BoolToStr(System.Net.Socket.SetKeepAlive(FSocket.Handle, 3000, 1000), True), DEBUG);
end;

procedure TConnection.Disconnect;
begin
  DoLog('Disconnect... enter', DEBUG);
  try
    Close;
    CompleteWait;
  finally
    DoLog('Disconnect... leave', DEBUG);
  end;
end;

procedure TConnection.DoReceive(const B: TBytes);
begin
  if Assigned(OnReceive) then OnReceive(Self, B);
end;

function TConnection.Connected: Boolean;
begin
  Result := TSocketState.Connected in FSocket.State;
end;

procedure TConnection.Close;
begin
  Lock(Self);
  if Connected then begin
    FSocket.Close;
    DoLog('closed', INFO);
  end;
end;

procedure TConnection.DoComplete;
begin
  DoLog('DoComplete', DEBUG);
  Close;
  CompleteSignal;
  DoDisconnect;
end;

procedure TConnection.Send(const B: TBytes);
begin
  DoLog('send ' + Length(B).ToString + ' bytes', TRACE);
  Lock(FSocket);
  try
    if FSocket.Send(B) = -1 then
      raise ESocketError.Create('Unable to send data when connection is closed');
  except on E: Exception do
    DoLogException(E);
  end;
end;

procedure TConnection.BeginReceive;
begin
  FSocket.BeginReceive(procedure (const ASyncResult: IAsyncResult)
  begin
    FAsyncThread := TThread.CurrentThread.ThreadID;
    try
      var B := FSocket.EndReceiveBytes(ASyncResult);
      var ReceiveLength := Length(B);
      if ReceiveLength > 0 then begin
        DoLog('received ' + ReceiveLength.ToString + ' bytes', TRACE);
        DoReceive(B);
        if FSocket.Handle <> InvalidSocket then begin
          BeginReceive;
          Exit;
        end;
      end else
        DoLog('received ' + ReceiveLength.ToString + ' bytes (closed)', DEBUG);
    except on E: Exception do
      DoLogException(E);
    end;
    DoComplete;
  end);
  // The calling thread must not be the same thread on which the asynchronous function will be called.
  // Therefore, the current thread must be delayed until the asynchronous thread starts.
  // Otherwise, exceptions are not handled.
  Sleep(10);
end;

{ TClient }

constructor TClientConnection.Create;
begin
  inherited Create(TSocket.Create(TSocketType.TCP, TEncoding.ANSI));
  Name := 'Client_' + GenClienId.ToString;
  FDisconnect := False;
  FReconnectInterval := 1000;
  FReconnect := TEvent.Create;
  CompleteSignal;
end;

destructor TClientConnection.Destroy;
begin
  inherited;
  FReconnect.Free;
end;

function TClientConnection.GetName: string;
begin
  Result := inherited + '/' + Address;
end;

procedure TClientConnection.DoComplete;
begin
  FReconnect.ResetEvent;
  inherited;
  FDisconnect := False;
end;

procedure TClientConnection.Disconnect;
begin
  FDisconnect := True;
  inherited;
  FReconnect.SetEvent;
end;

procedure TClientConnection.DoConnected;
begin
  if Assigned(FOnConnected) then FOnConnected(Self);
end;

procedure TClientConnection.DoDisconnect;
begin
  inherited;
  DoReconnect;
end;

procedure TClientConnection.DoReconnect;
begin
  if not FDisconnect then
  if Assigned(FReconnect) then
  if FReconnect.WaitFor(FReconnectInterval) = wrTimeout then
    Connect;
end;

procedure TClientConnection.Connect;
begin
  if FDisconnect then Exit;
  CompleteReset;
  DoLog('connecting...', INFO);
  FSocket.BeginConnect(procedure (const ASyncResult: IAsyncResult)
  begin
    FAsyncThread := TThread.CurrentThread.ThreadID;
    try
      FSocket.EndConnect(ASyncResult);
      if not Connected then // TODO: fix
        raise ESocketError.Create('Unhandled connection error');
      DoLog('connected', INFO);
      if not FDisconnect then begin
        SetKeepAlive;
        DoConnected;
        BeginReceive;
        Exit;
      end;
    except on E: Exception do
      DoLogException(E);
    end;
    DoComplete;
  end,
  Address, '', '', Port);
  Sleep(100);
end;

constructor TServerConnection.Accept(Socket: TSocket);
begin
  Create(Socket);
  FSocket.Encoding := TEncoding.ANSI;
  Name := 'ServerConnection_' + GenClienId.ToString;
  var Address := RemoteAddress;
  if not Address.IsEmpty then
    Name := Name + '/' + Address;
end;

procedure TServerConnection.BeginReceive;
begin
  DoLog('accepted from ' + RemoteAddress, DEBUG);
  SetKeepAlive;
  CompleteReset;
  inherited BeginReceive;
end;

constructor TSocketServer.Create;
begin
  inherited;
  FName := 'Server';
  FSocket := TSocket.Create(TSocketType.TCP, TEncoding.ANSI);
  FSocket.ReceiveTimeout := -1;
  CompleteSignal;
end;

destructor TSocketServer.Destroy;
begin
  Stop;
  inherited;
end;

procedure TSocketServer.Close;
begin
  Lock(Self);
  if Started then begin
    DoLog('stopping...', DEBUG);
    FSocket.Close{$IFDEF MSWINDOWS}(True){$ENDIF};
  end;
end;

procedure TSocketServer.Start;
begin
  FSocket.Listen('', '', Port); // raised exception if listen already in use
  DoLog('started at port: ' + Port.ToString, INFO);
  CompleteReset;
  BeginAccept;
end;

procedure TSocketServer.BeginAccept;
begin
  FSocket.BeginAccept(procedure (const ASyncResult: IAsyncResult)
  begin
    FAsyncThread := TThread.CurrentThread.ThreadID;
    try
      var Socket := FSocket.EndAccept(ASyncResult);
      if Assigned(Socket) then begin
        DoAccept(Socket);
        BeginAccept;
        Exit;
      end;
    except on E: Exception do
      DoLogException(E);
    end;
    DoComplete;
  end);
  Sleep(10);
end;

function TSocketServer.Started: Boolean;
begin
  Result := TSocketState.Connected in FSocket.State;
end;

procedure TSocketServer.Stop;
begin
  if Started then begin
    Close;
    CompleteWait;
    DoLog('stopped', INFO);
  end;
end;

procedure TSocketServer.DoAccept(Socket: TSocket);
begin
  DoLog('accept client', DEBUG);
  if Assigned(FOnAccept) then FOnAccept(Socket);
end;

procedure TSocketServer.DoStart;
begin
  if Assigned(FOnStart) then FOnStart(Self);
end;

procedure TSocketServer.DoStop;
begin
  DoLog('DoStop', DEBUG);
  if Assigned(FOnStop) then FOnStop(Self);
end;

procedure TSocketServer.DoComplete;
begin
  DoLog('DoComplete', DEBUG);
  Close;
  CompleteSignal;
  DoStop;
end;

end.
