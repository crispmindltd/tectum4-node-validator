unit Net.Core;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Threading,
  System.Net.Socket,
  App.Types,
  App.Intf,
  App.Logs,
  App.Settings,
  Crypto.Types,
  Net.Data,
  Net.Intf,
  Net.SocketA,
  Net.Peer,
  Net.CustomHandler,
  Net.ClientHandler,
  Net.ServerHandler;

type
  TNetCore = class(TNoRefCountObject, INetCore)
  private
    FSettings: TSettings;
    FPeer: TPeer;
    FClientHandlers: TArray<TClientHandler>;
    FServerHandlers: TArray<TServerHandler>;
    FTimer: TEvent;
    procedure DoTimer;
    procedure OnConnectedClient(Client: TClientConnection);
    procedure OnDisconnectedClient(Client: TConnection);
    procedure DoLog(const S: string; Level: TLevel);
    procedure DoAcceptClient(Socket: TSocket);
    procedure DoDisconnectServerConnection(Client: TConnection);
    function GetConnectedClients: TArray<TClientHandler>;
  public
    constructor Create(Settings: TSettings);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function GetServerStats: TArray<TNetNode>;
    function GetClientsStats: TArray<TNetNode>;
    function ServerConnectionExists(const PubKey: TPublicKey): Boolean;
    function SendRequestToAnyServer(PacketType: TNetPacketType; Body: TBytes): TBytes;
    function GetValidators(const IgnorePubKey: TPublicKey): TArray<IConnection>;
    function GetAnyServer(Required: Boolean = True): IConnection;
  end;

  TClientHandlerClass = class of TClientHandler;
  TServerHandlerClass = class of TServerHandler;

var
  ClientHandlerClass: TClientHandlerClass = TClientHandler;
  ServerHandlerClass: TServerHandlerClass = TServerHandler;

implementation

constructor TNetCore.Create(Settings: TSettings);
begin
  FSettings := Settings;
  FPeer := TPeer.Create;
  FPeer.OnLog := DoLog;
  FTimer := TEvent.Create;
end;

destructor TNetCore.Destroy;
begin
  Stop;
  FPeer.Free;
  FTimer.Free;
end;

procedure TNetCore.DoLog(const S: string; Level: TLevel);
begin
  Logs.DoLog(S, Level);
end;

procedure TNetCore.Start;
begin
  var Nodes := FSettings.Nodes;

  TCode.Shuffle<string>(Nodes);

  for var Node in Nodes do begin
    var S := Node.Split([':']);
    var C := FPeer.AddClient(S[0], S[1].ToInteger);
    C.OnConnected := OnConnectedClient;
    C.OnDisconnect := OnDisconnectedClient;
    C.OnLog := DoLog;
  end;

  for var Server in FSettings.Servers do begin
    var V := Server.Split([':']);
    var S := FPeer.AddServer(V[1].ToInteger);
    S.OnAccept := DoAcceptClient;
    S.OnLog := DoLog;
  end;

  if FPeer.Clients.Count = 0 then
    // There will be no new blocks, immediately call UI to update
    UI.DataChange;

  FPeer.Start;
  FTimer.ResetEvent;

  TTask.Run(procedure
  begin
    while FTimer.WaitFor(100) = wrTimeout do DoTimer;
  end);
end;

procedure TNetCore.Stop;
begin
  FTimer.SetEvent;

  begin
    Lock(Self);
    for var Handler in FClientHandlers do Handler.Client.OnReceive := nil;
    for var Handler in FServerHandlers do Handler.Client.OnReceive := nil;
  end;

  FPeer.Stop;
  FPeer.Clients.Clear;
  FPeer.Servers.Clear;

  begin
    Lock(Self);
    for var Handler in FClientHandlers do Handler.Free;
    FClientHandlers := nil;
    for var Handler in FServerHandlers do Handler.Free;
    FServerHandlers := nil;
  end;
end;

procedure TNetCore.DoAcceptClient(Socket: TSocket);
begin
  var Client := TServerConnection.Accept(Socket);
  Client.OnDisconnect := DoDisconnectServerConnection;
  Client.OnLog := DoLog;

  var Handler := ServerHandlerClass.Create(Client, Self);
  Handler.OnLog := DoLog;

  Client.BeginReceive;
  Handler.Start;

  Lock(Self);

  FServerHandlers := FServerHandlers + [Handler];
  DoLog('ServerHandlers: ' + Length(FServerHandlers).ToString, INFO);
end;

procedure TNetCore.DoDisconnectServerConnection(Client: TConnection);
begin
  if not Assigned(AppCore) then Exit;
  Lock(Self);
  for var I := 0 to High(FServerHandlers) do
    if FServerHandlers[I].Client = Client then begin
      var Handler := FServerHandlers[I];
      Delete(FServerHandlers, I, 1);
      Handler.Free;
      DoLog('ServerHandlers: ' + Length(FServerHandlers).ToString, INFO);
      Break;
    end;
end;

procedure TNetCore.OnConnectedClient(Client: TClientConnection);
begin
  var Handler := ClientHandlerClass.Create(Client, Self);
  Handler.OnLog := DoLog;

  Lock(Self);

  FClientHandlers := FClientHandlers + [Handler];
end;

procedure TNetCore.OnDisconnectedClient(Client: TConnection);
begin
  UI.DoConnectionFailed(TClientConnection(Client).Address);
end;

procedure TNetCore.DoTimer;
begin
  Lock(Self);
  for var Handler in FClientHandlers do Handler.DoQueue;
  for var Handler in FServerHandlers do Handler.DoQueue;
end;

function TNetCore.GetConnectedClients: TArray<TClientHandler>;
begin
  Lock(Self);
  Result := nil;
  for var Handler in FClientHandlers do
    if Handler.State = TConnectionState.Passed then
      Result := Result + [Handler];
end;

function TNetCore.GetAnyServer(Required: Boolean = True): IConnection;
begin
  var Handlers := GetConnectedClients;
  if Length(Handlers) = 0 then
    if Required then
      raise Exception.Create('No connected clients')
    else
      Result := nil
  else
    Result := Handlers[Random(Length(Handlers))];
end;

function TNetCore.SendRequestToAnyServer(PacketType: TNetPacketType; Body: TBytes): TBytes;
begin
  var Server := GetAnyServer;
  DoLog('Send transaction to ' + Server.ReceiverName, INFO);
  Result := Server.DoRequest(PacketType, Body);
end;

function TNetCore.ServerConnectionExists(const PubKey: TPublicKey): Boolean;
begin
  Lock(Self);
  Result := False;
  for var Handler in FServerHandlers do
    if Handler.PubKey = PubKey then begin
      Handler.Ping;
      Exit(True);
    end;
end;

function TNetCore.GetValidators(const IgnorePubKey: TPublicKey): TArray<IConnection>;
begin
  Lock(Self);
  Result := nil;
  var logStr: string;
  for var Handler in FServerHandlers do begin
    if Handler.PubKey.IsEmpty then Continue;
    if Handler.PubKey = IgnorePubKey then Continue;
    if Handler.State <> TConnectionState.Passed then Continue;

    Result := Result + [Handler];
    logStr := logStr + ' ' + Handler.ShortAddress;
  end;
  DoLog('Validators list:' + logStr, INFO);
  TCode.Shuffle<IConnection>(Result); // shuffle validators for random sending requests
end;

function TNetCore.GetServerStats: TArray<TNetNode>;
begin
  Lock(Self);
  Result := nil;
  for var Handler in FClientHandlers do begin
    var N: TNetNode;
    N.Name := Handler.ReceiverName;
    N.State := Handler.State;
    Result := Result + [N];
  end;
end;

function TNetCore.GetClientsStats: TArray<TNetNode>;
begin
  Lock(Self);
  Result := nil;
  for var Handler in FServerHandlers do begin
    var N: TNetNode;
    N.Name := Handler.ReceiverName;
    N.State := Handler.State;
    Result := Result + [N];
  end;
end;

end.
