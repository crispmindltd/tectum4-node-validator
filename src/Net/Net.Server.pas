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
  Net.ServerConnection,
  Net.Socket,
  System.SyncObjs,
  System.SysUtils,
  System.Types;

type
  TServerStatus = (ssStarted, ssShuttingDown, ssStoped);

  TNodeServer = class
    const
      ShutDownTimeout = 10000;
    strict private
      FAddress: string;
      FPort: Word;
    private
      FStatus: TServerStatus;
      FListeningSocket: TSocket;
      FCommandHandler: TCommandHandler;
      FClients: TObjectList<TServerConnection>;
      FListLock: TCriticalSection;
      FServerStoped: TEvent;

      procedure AcceptCallback(const ASyncResult: IAsyncResult);
      procedure AcceptConnections;
      procedure OnClientDisconnected(Sender: TObject);
      function OnConnectionChecked(Sender: TObject): Boolean;
      procedure TerminateAllClients;
    public
      function GetValidators(const [Ref] AExcludePubKey: T65Bytes): TArray<TServerConnection>;

      constructor Create;
      destructor Destroy; override;

      procedure Start(AAddress: string; APort: Word);
      procedure Stop;
      procedure WaitFor;

  end;

implementation

{ TNodeServer }

procedure TNodeServer.AcceptCallback(const ASyncResult: IAsyncResult);
var
  FAcceptedSocket: TSocket;
  NewClient: TServerConnection;
begin
  try
    try
      FAcceptedSocket := FListeningSocket.EndAccept(ASyncResult);
      if Assigned(FAcceptedSocket) then
      begin
        NewClient := TServerConnection.Create(FAcceptedSocket, FCommandHandler,
          OnClientDisconnected, OnConnectionChecked);
        FListLock.Enter;
        try
          FClients.Add(NewClient);
          Logs.DoLog('Connection accepted: ' + NewClient.Address + //
          ' (' + NewClient.shortAddr + ')' + ' Total clients ' + FClients.Count.ToString,
            CmnLvlLogs, ltNone);
        finally
          FListLock.Leave;
        end;
      end
    finally
      if FStatus = ssStarted then
      begin
        Logs.DoLog('Listen socket begin accept', DbgLvlLogs, ltNone);
        FListeningSocket.BeginAccept(AcceptCallback, INFINITE)
      end else if FStatus = ssShuttingDown then
      begin
        Logs.DoLog('Listen socket closed', AdvLvlLogs, ltNone);
        TerminateAllClients;
      end;
    end;
  except on E:Exception do
    Logs.DoLog(E.Message + ' exception in AcceptCallback', CmnLvlLogs, TLogType.ltError);
  end;
end;

constructor TNodeServer.Create;
begin
  FStatus := ssStoped;
  FListeningSocket := TSocket.Create(TSocketType.TCP, TEncoding.ANSI);
  FCommandHandler := TCommandHandler.Create;
  FClients := TObjectList<TServerConnection>.Create;
  FListLock := TCriticalSection.Create;
  FServerStoped := TEvent.Create;
end;

destructor TNodeServer.Destroy;
begin
  Stop;
  FClients.Free;
  FListLock.Free;
  FServerStoped.Free;
  FCommandHandler.Free;
  FListeningSocket.Free;

  inherited;
end;

function TNodeServer.GetValidators(const [Ref] AExcludePubKey: T65Bytes): TArray<TServerConnection>;
const
  MinValidatorStake = _1_TET;
begin
  Logs.DoLog('get validators', DbgLvlLogs, ltNone);
  FListLock.Enter;
  try
   var logStr:string;
    for var LConnection in FClients do begin
      try
        if not LConnection.isChecked then Continue;

        logStr := LConnection.shortAddr + ' (' + LConnection.Address + ') ';
        if AExcludePubKey = LConnection.PubKey then begin
          logStr := logStr + ' - self!';
          Continue;
        end;
        const staked = DataCache.GetStakeBalance(LConnection.PubKey.Address);

        if staked < MinValidatorStake then begin
          logStr := logStr + ' ' + staked.ToString +' < MinValidatorStake !';
          Continue;
        end;
        Result := Result + [LConnection];
      finally
        Logs.DoLog(logStr, DbgLvlLogs, ltNone);
      end;
    end;
    if Length(Result) < 3 then begin
      Result := [];
      Exit;
    end;
    while Length(Result) > 3 do
      Delete(Result, Random(Length(Result)), 1);
  finally
    FListLock.Leave;
  end;
end;

procedure TNodeServer.OnClientDisconnected(Sender: TObject);
begin
  FListLock.Enter;
  try
    FClients.Remove(Sender as TServerConnection);
    if (FStatus = ssShuttingDown) and FClients.IsEmpty then
      FServerStoped.SetEvent;
  finally
    FListLock.Leave;
  end;
end;

function TNodeServer.OnConnectionChecked(Sender: TObject): Boolean;
var
  i: Integer;
  Connect: TServerConnection;
begin
  Connect := Sender as TServerConnection;
  FListLock.Enter;
  try
    for i := 0 to FClients.Count - 1 do
      if (FClients.Items[i].PubKey = Connect.PubKey) and
         not FClients.Items[i].Equals(Sender) then
        Exit(False);

    Result := True;
  finally
    FListLock.Leave;
  end;
end;

procedure TNodeServer.AcceptConnections;
begin
  FListeningSocket.Listen(FAddress, '', FPort);
  FListeningSocket.BeginAccept(AcceptCallback, INFINITE);
  Logs.DoLog('Listen socket begin accept', AdvLvlLogs, ltNone);
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

  FStatus := ssShuttingDown;

  if TSocketState.Connected in FListeningSocket.State then
  {$IFDEF MSWINDOWS}
    FListeningSocket.Close(True);
  {$ELSE IFDEF LINUX}
    FListeningSocket.Close;
  {$ENDIF}

  WaitFor;

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

  FListLock.Enter;
  try
    for i := 0 to FClients.Count - 1 do
      FClients.Items[i].Stop;
  finally
    FListLock.Leave;
  end;
end;

procedure TNodeServer.WaitFor;
begin
  if FServerStoped.WaitFor(ShutDownTimeout) <> wrSignaled then
  begin
    Logs.DoLog('Server shutdown timeout', CmnLvlLogs, ltError);
  end;
end;

end.
