unit Net.Server;

interface

uses
  Blockchain.Data,
  BlockChain.DataCache,
  Blockchain.Address,
  App.Logs,
  System.Classes,
  Generics.Collections,
  Net.CommandHandler,
  Net.Data,
  Net.ServerConnection,
  Net.Socket,
  System.SyncObjs,
  System.SysUtils,
  System.Types;

type
  TServerStatus = (ssStarted, ssShuttingDown, ssStoped);

  TNodeServer = class
    const
      ShutDownTimeout = 5000;
    strict private
      FAddress: string;
      FPort: Word;
    private
      FStatus: TServerStatus;
      FListeningSocket: TSocket;
      FCommandHandler: TCommandHandler;
      FClients: TObjectList<TServerConnection>;
      FLock: TCriticalSection;
      FServerStoped: TEvent;

      procedure AcceptCallback(const ASyncResult: IAsyncResult);
      procedure AcceptConnections;
      procedure OnClientDisconnected(Sender: TObject);
      procedure OnConnectionChecked(Sender: TObject);
      procedure TerminateAllClients;
    public
      function GetValidators(const [Ref] AExcludePubKey:T65Bytes):TArray<TServerConnection>;

      constructor Create;
      destructor Destroy; override;

      procedure Start(AAddress: string; APort: Word);
      procedure Stop;
  end;

implementation

{ TNodeServer }

procedure TNodeServer.AcceptCallback(const ASyncResult: IAsyncResult);
var
  FAcceptedSocket: TSocket;
  NewClient: TServerConnection;
begin
  FAcceptedSocket := FListeningSocket.EndAccept(ASyncResult);
  if Assigned(FAcceptedSocket) then
  begin
    NewClient := TServerConnection.Create(FAcceptedSocket, FCommandHandler,
      OnClientDisconnected, OnConnectionChecked);
    FListeningSocket.BeginAccept(AcceptCallback, INFINITE);
  end else
  begin
    FStatus := ssShuttingDown;
    TerminateAllClients;
  end;
end;

constructor TNodeServer.Create;
begin
  FStatus := ssStoped;
  FListeningSocket := TSocket.Create(TSocketType.TCP, TEncoding.ANSI);
  FCommandHandler := TCommandHandler.Create;
  FClients := TObjectList<TServerConnection>.Create;
  FLock := TCriticalSection.Create;
  FServerStoped := TEvent.Create;
end;

destructor TNodeServer.Destroy;
begin
  Stop;
  FLock.Free;
  FServerStoped.Free;
  FCommandHandler.Free;
  FListeningSocket.Free;
  FClients.Free;

  inherited;
end;

function TNodeServer.GetValidators(const [Ref] AExcludePubKey: T65Bytes): TArray<TServerConnection>;
const
  MinValidatorStake = _1_TET;
begin
  FLock.Enter;
  try
    for var LConnection in FClients do begin
      if AExcludePubKey = LConnection.PubKey then
        Continue;
      if DataCache.GetStakeBalance(LConnection.PubKey.Address) < MinValidatorStake then
        Continue;
      Result := Result + [LConnection];
    end;
    if Length(Result) < 3 then begin
      Result := [];
      Exit;
    end;
    while Length(Result) > 3 do
      Delete(Result, Random(Length(Result)), 1);
  finally
    FLock.Leave;
  end;
end;

procedure TNodeServer.OnClientDisconnected(Sender: TObject);
begin
  FLock.Enter;
  try
    FClients.Remove(Sender as TServerConnection);
    if (FStatus = ssShuttingDown) and FClients.IsEmpty then
      FServerStoped.SetEvent;
  finally
    FLock.Leave;
  end;
end;

procedure TNodeServer.OnConnectionChecked(Sender: TObject);
var
  i: Integer;
  NewConnect: TServerConnection;
begin
  FLock.Enter;
  try
    NewConnect := Sender as TServerConnection;
    for i := 0 to FClients.Count - 1 do
      if FClients.Items[i].PubKey = NewConnect.PubKey then
      begin
        NewConnect.Status := KeyAlreadyUsesErrorCode;
        NewConnect.Free;
        exit;
      end;
    FClients.Add(NewConnect);
  finally
    FLock.Leave;
  end;
end;

procedure TNodeServer.AcceptConnections;
begin
  FListeningSocket.Listen(FAddress, '', FPort);
  FListeningSocket.BeginAccept(AcceptCallback, INFINITE);
end;

procedure TNodeServer.Start(AAddress: string; APort: Word);
begin
  if FStatus <> ssStoped then
    exit;

  FAddress := AAddress;
  FPort := APort;

  AcceptConnections;
  FServerStoped.ResetEvent;
  FStatus := ssStarted;
end;

procedure TNodeServer.Stop;
begin
  if FStatus <> ssStarted then 
    exit;

  if TSocketState.Connected in FListeningSocket.State then
  {$IFDEF MSWINDOWS}
    FListeningSocket.Close(True);
  {$ELSE IFDEF LINUX}
    FListeningSocket.Close;
  {$ENDIF}

  if FServerStoped.WaitFor(ShutDownTimeout) <> wrSignaled then
    Logs.DoLog('Server shutdown timeout', ltError);
  FStatus := ssStoped;
end;

procedure TNodeServer.TerminateAllClients;
var
  i: Integer;
begin
  if FClients.IsEmpty then
  begin
    FServerStoped.SetEvent;
    exit;
  end;

  FLock.Enter;
  try
    for i := 0 to FClients.Count - 1 do
      FClients.Items[i].Stop;
  finally
    FLock.Leave;
  end;
end;

end.
