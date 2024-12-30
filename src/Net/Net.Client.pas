unit Net.Client;

interface

uses
  App.Intf,
  App.Logs,
  Classes,
  Crypto,
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
    ShutDownTimeout = 5000;
  private
    FStatus: TClientStatus;
    FServers: TObjectList<TClientConnection>;
    FServForSync: TClientConnection;
    FCommandHandler: TCommandHandler;
    FLock: TCriticalSection;
    FClientStoped: TEvent;

    procedure EstablishConnection(const AAddress: string);
    procedure OnServerIsNotAvailable(Sender: TObject);
    procedure OnDisconnectedFromServer(Sender: TObject);
    function OnCheckIfNeedSync(Sender: TObject): Boolean;
    procedure ChooseConnectionForChainsSync;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start;
    function DoRequestToArchiever(ACommandCode: Byte;
      const ARequest: TBytes): TBytes;
    procedure Stop;
end;

implementation

{ TNodeClient }

procedure TNodeClient.ChooseConnectionForChainsSync;
var
  Ind: Integer;
begin
  if not FServers.IsEmpty and not Assigned(FServForSync) then
  begin
    Ind := Random(FServers.Count);
    if not FServers[Ind].IsReconnecting then
    begin
      FServers[Ind].IsForSync := True;
      FServForSync := FServers[Ind];
    end;
  end;
end;

constructor TNodeClient.Create;
begin
  inherited Create;

  FStatus := csStoped;
  FLock := TCriticalSection.Create;
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
  FLock.Free;

  inherited;
end;

procedure TNodeClient.EstablishConnection(const AAddress: string);
var
  Splitted: TArray<string>;
  NewConnection: TClientConnection;
begin
  NewConnection := TClientConnection.Create(TSocket.Create(TSocketType.TCP,
    TEncoding.ANSI), FCommandHandler, OnDisconnectedFromServer,
    OnServerIsNotAvailable, OnCheckIfNeedSync);
  Splitted := AAddress.Split([':']);

  if NewConnection.Connect(Splitted[0], Splitted[1].ToInteger) then
  begin
    FLock.Enter;
    try
      FServers.Add(NewConnection);
    finally
      FLock.Leave;
    end;
  end else
  begin
    UI.DoMessage(Format('%s is not responding', [AAddress]));
    NewConnection.Free;
  end;
end;

function TNodeClient.OnCheckIfNeedSync(Sender: TObject): Boolean;
begin
  Result := not Assigned(FServForSync);
  if Result then
    FServForSync := Sender as TClientConnection;
end;

procedure TNodeClient.OnDisconnectedFromServer(Sender: TObject);
begin
  FLock.Enter;
  try
    FServers.Remove(Sender as TClientConnection);
    if FServers.IsEmpty and (FStatus = csShuttingDown) then
      FClientStoped.SetEvent;
  finally
    FLock.Leave;
  end;
end;

procedure TNodeClient.OnServerIsNotAvailable(Sender: TObject);
begin
  const WasSyncServ = (Sender as TClientConnection).Equals(FServForSync);
  if WasSyncServ and (FStatus = csStarted) then
  begin
    FServForSync := nil;
    ChooseConnectionForChainsSync;
  end;
end;

function TNodeClient.DoRequestToArchiever(ACommandCode: Byte;
  const ARequest: TBytes): TBytes;
var
  ConInd, Pos: Integer;
  ReqWithoutKey: string;
  ToSend: TBytes;
begin
  ConInd := Random(FServers.Count);

  Result := FServers[ConInd].DoRequest(ACommandCode, ARequest);
//  Logs.DoLog(Format('<From %s>[%d]: %s', [FServers[ConInd].Address, ACommandCode,
//    Result]), INCOM, tcp);
end;

procedure TNodeClient.Start;
var
  i: Integer;
  Tasks: array of ITask;
  procedure Connect(Anum:Integer);
  begin
    Tasks[Anum] := TTask.Run(procedure
    begin
      EstablishConnection(Nodes.GetNodesArray[Anum]);
    end);
  end;
begin
  FClientStoped.ResetEvent;
  FServers.Clear;

  SetLength(Tasks, Length(Nodes.GetNodesArray));
  for i := 0 to Length(Tasks) - 1 do
    Connect(i);

  TTask.WaitForAll(Tasks, 2000);
  Sleep(500);
  if FStatus = csStoped then
  begin
    ChooseConnectionForChainsSync;
    FStatus := csStarted;
  end;
end;

procedure TNodeClient.Stop;
var
  i: Integer;
begin
  if FStatus <> csStarted then
    exit;

  FStatus := csShuttingDown;
  if FServers.Count = 0 then
  begin
    FClientStoped.SetEvent;
    exit;
  end;
  for i := 0 to FServers.Count - 1 do
    FServers[i].Stop;

  if FClientStoped.WaitFor(ShutDownTimeout) <> wrSignaled then
    Logs.DoLog('Client shutdown timeout', ltError);
  FStatus := csStoped;
end;

end.
