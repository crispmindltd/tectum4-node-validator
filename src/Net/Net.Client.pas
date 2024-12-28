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
  SysUtils;

type
  TNodeClient = class
  const
    ShutDownTimeout = 5000;
  private
    FServers: TObjectList<TClientConnection>;
    FCommandHandler: TCommandHandler;
    FLock: TCriticalSection;
    FClientStoped: TEvent;

    procedure EstablishConnection(const ASocket: TSocket; const AAddress: string);
    procedure OnDisconnectedFromServer(Sender: TObject);
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
begin
  if not FServers.IsEmpty then
    FServers[Random(FServers.Count)].IsForSync := True;
end;

constructor TNodeClient.Create;
begin
  inherited Create;

  FLock := TCriticalSection.Create;
  FCommandHandler := TCommandHandler.Create;
  FClientStoped := TEvent.Create;
  FServers := TObjectList<TClientConnection>.Create;
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

procedure TNodeClient.EstablishConnection(const ASocket: TSocket;
  const AAddress: string);
var
  Splitted: TArray<string>;
  NewConnection: TClientConnection;
begin
  NewConnection := TClientConnection.Create(ASocket, FCommandHandler,
    OnDisconnectedFromServer);
  Splitted := AAddress.Split([':']);
  if NewConnection.Connect(Splitted[0], Splitted[1].ToInteger) then
  begin
    FLock.Enter;
    try
      FServers.Add(NewConnection);
      FClientStoped.ResetEvent;
    finally
      FLock.Leave;
    end;
  end else
  begin
    UI.DoMessage(Format('%s is not responding', [AAddress]));
    NewConnection.Free;
  end;
end;

procedure TNodeClient.OnDisconnectedFromServer(Sender: TObject);
begin
  FLock.Enter;
  try
    FServers.Remove(Sender as TClientConnection);
    if FServers.IsEmpty then
      FClientStoped.SetEvent;
  finally
    FLock.Leave;
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
begin
  FClientStoped.ResetEvent;
  FServers.Clear;
  for i := 0 to Length(Nodes.GetNodesArray) - 1 do
    EstablishConnection(TSocket.Create(TSocketType.TCP, TEncoding.ANSI),
      Nodes.GetNodesArray[i]);
  ChooseConnectionForChainsSync;
end;

procedure TNodeClient.Stop;
var
  i: Integer;
begin
  if FServers.Count = 0 then
    FClientStoped.SetEvent;
  for i := 0 to FServers.Count - 1 do
    FServers[i].Stop;

  if FClientStoped.WaitFor(ShutDownTimeout) <> wrSignaled then
    Logs.DoLog('Client shutdown timeout', ltError);
end;

end.
