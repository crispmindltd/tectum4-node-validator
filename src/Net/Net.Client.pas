unit Net.Client;

interface

uses
  App.Exceptions,
  App.Logs,
  Generics.Collections,
  Net.CommandHandler,
  Net.ClientConnection,
  Net.Socket,
  Net.Data,
  SyncObjs,
  SysUtils,
  Threading;

type
  TClientStatus = (csStarted, csShuttingDown, csStoped);

  TNodeClient = class
  const
    ShutDownTimeout = 10000;
  private
    FStatus: TClientStatus;
    FServers: TObjectList<TClientConnection>;
    FServForSync: TClientConnection;
    FCommandHandler: TCommandHandler;
    FListLock: TCriticalSection;
    FClientStoped: TEvent;

    procedure EstablishConnection(const AAddress: string);
    procedure OnConnectionChecked(Sender: TObject);
    procedure OnDisconnectedFromServer(Sender: TObject);
    procedure OnConnectionLost(Sender: TObject);
    function GetCheckedConnection: TClientConnection;
    procedure ChooseConnectionForSync;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start;
    function DoRequestToArchiver(ACommandCode: Byte;
      const ARequest: TBytes): TBytes;
    procedure Stop;
end;

implementation

{ TNodeClient }

procedure TNodeClient.ChooseConnectionForSync;
var
  Connection: TClientConnection;
begin
  if FServers.IsEmpty or Assigned(FServForSync) or (FStatus <> csStarted) then
    exit;

  Connection := GetCheckedConnection;
  if Assigned(Connection) then
  begin
    Connection.IsForSync := True;
    FServForSync := Connection;
    Logs.DoLog(Format('%s for sync', [Connection.Address]), AdvLvlLogs, ltNone);
  end;
end;

constructor TNodeClient.Create;
begin
  inherited Create;

  FStatus := csStoped;
  FListLock := TCriticalSection.Create;
  FCommandHandler := TCommandHandler.Create;
  FClientStoped := TEvent.Create;
  FClientStoped.ResetEvent;
  FServers := TObjectList<TClientConnection>.Create;
  FServForSync := nil;
end;

destructor TNodeClient.Destroy;
begin
  Stop;
  FServers.Free;
  FClientStoped.Free;
  FCommandHandler.Free;
  FListLock.Free;

  inherited;
end;

procedure TNodeClient.EstablishConnection(const AAddress: string);
var
  Splitted: TArray<string>;
  NewConnection: TClientConnection;
begin
  NewConnection := TClientConnection.Create(TSocket.Create(TSocketType.TCP,
    TEncoding.ANSI), FCommandHandler, OnDisconnectedFromServer,
    OnConnectionChecked, OnConnectionLost);
  Splitted := AAddress.Split([':']);

  FListLock.Enter;
  try
    FServers.Add(NewConnection);
  finally
    FListLock.Leave;
  end;

  NewConnection.Connect(Splitted[0], Splitted[1].ToInteger);
  if not NewConnection.IsConnected then
    OnDisconnectedFromServer(NewConnection);
end;

function TNodeClient.GetCheckedConnection: TClientConnection;
var
  Connections: TList<TClientConnection>;
begin
  Result := nil;
  Connections := TList<TClientConnection>.Create(FServers.ToArray);
  try
    repeat
      if Connections.IsEmpty then
        Exit(nil);

      Result := Connections[Random(Connections.Count)];
      Connections.Remove(Result);
    until Result.IsChecked and (not Result.IsConnecting);
  finally
    Connections.Free;
  end;
end;

procedure TNodeClient.OnDisconnectedFromServer(Sender: TObject);
begin
  FListLock.Enter;
  try
    FServers.Remove(Sender as TClientConnection);
    if (FStatus = csShuttingDown) and FServers.IsEmpty then
      FClientStoped.SetEvent;
  finally
    FListLock.Leave;
  end;
end;

procedure TNodeClient.OnConnectionChecked(Sender: TObject);
var
  Connection: TClientConnection;
begin
  if not Assigned(FServForSync) and (FStatus = csStarted) then
  begin
    Connection := Sender as TClientConnection;
    FServForSync := Connection;
    Connection.IsForSync := True;
    Logs.DoLog(Format('%s for sync', [Connection.Address]), AdvLvlLogs, ltNone);
  end;
end;

procedure TNodeClient.OnConnectionLost(Sender: TObject);
var
  Connection: TClientConnection;
begin
  Connection := Sender as TClientConnection;
  const WasForSync = Connection.Equals(FServForSync);
  if WasForSync and (FStatus = csStarted) then
  begin
    Connection.IsForSync := False;
    FServForSync := nil;
    ChooseConnectionForSync;
  end;
end;

function TNodeClient.DoRequestToArchiver(ACommandCode: Byte;
  const ARequest: TBytes): TBytes;
var
  Connection: TClientConnection;
begin
  Connection := GetCheckedConnection;
  if Assigned(Connection) then
  begin
    Logs.DoLog(Format('Selected server: %s. Servers count: %d',
      [Connection.Address, FServers.Count]), DbgLvlLogs, TLogType.ltNone);

    Result := Connection.DoRequest(ACommandCode, ARequest);
  end else
    raise ENoArchiversAvailableError.Create('');
end;

procedure TNodeClient.Start;
var
  Node: string;

  procedure Connect(AAddress: string);
  begin
    TTask.Run(procedure
    begin
      EstablishConnection(AAddress);
    end);
  end;

begin
  if FStatus <> csStoped then
    exit;

  FClientStoped.ResetEvent;
  FServers.Clear;

//  Node := Nodes.GetNodeToConnect;
//  while not Node.IsEmpty do
//  begin
//    Connect(Node);
//    Node := Nodes.GetNodeToConnect;
//  end;

  FStatus := csStarted;
end;

procedure TNodeClient.Stop;

  procedure Disconnect(AConnection: TClientConnection);
  begin
    TTask.Run(procedure
    begin
      AConnection.Stop;
    end);
  end;

begin
  if FStatus <> csStarted then
    exit;

  try
    FStatus := csShuttingDown;

    if FServers.Count = 0 then
    begin
      FClientStoped.SetEvent;
      exit;
    end;

    FListLock.Enter;
    try
      for var Connection in FServers do
        Disconnect(Connection);
    finally
      FListLock.Leave;
    end;
  finally
    if FClientStoped.WaitFor(ShutDownTimeout) <> wrSignaled then
      Logs.DoLog('Client shutdown timeout', CmnLvlLogs, ltError);

    FStatus := csStoped;
  end;
end;

end.
