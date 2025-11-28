unit Net.Peer;

interface

uses
  System.SysUtils,
  System.Types,
  System.Classes,
  System.SyncObjs,
  System.Net.Socket,
  System.Net.URLClient,
  App.Types,
  Net.List,
  Net.SocketA;

type
  TPeer = class
  private
    FServers: TSafeList<TSocketServer>;
    FClients: TSafeList<TClientConnection>;
    FServerConnections: TSafeList<TServerConnection>;
    FStarted: Boolean;
    FOnLog: TLogEvent;
    procedure DoLog(const S: string; Level: TLevel);
    procedure OnStopServer(Server: TSocketServer);
    procedure OnAcceptClient(Socket: TSocket);
    procedure OnDisconnectServerConnection(Client: TConnection);
    procedure OnDisconnectClient(Client: TConnection);
    procedure OnReceiveClient(Client: TConnection; const Bytes: TBytes);
    procedure OnReceiveServerConnection(Client: TConnection; const Bytes: TBytes);
  public
    constructor Create;
    destructor Destroy; override;
    function AddServer(Port: Word): TSocketServer;
    function AddClient(const Address: string; Port: Word): TClientConnection;
    procedure Start;
    procedure Stop;
    property Servers: TSafeList<TSocketServer> read FServers;
    property ServerConnections: TSafeList<TServerConnection> read FServerConnections;
    property Clients: TSafeList<TClientConnection> read FClients;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

implementation

constructor TPeer.Create;
begin
  FServers := TSafeList<TSocketServer>.Create;
  FServerConnections := TSafeList<TServerConnection>.Create;
  FClients := TSafeList<TClientConnection>.Create;
  FStarted := False;
end;

destructor TPeer.Destroy;
begin
  DoLog('Peer destroying', DEBUG);
  Servers.Free;
  Clients.Free;
  ServerConnections.Free;
  DoLog('Peer destroy', DEBUG);
end;

function TPeer.AddServer(Port: Word): TSocketServer;
begin
  Result := TSocketServer.Create;
  Servers.Add(Result);

  Result.Port := Port;
  Result.OnStop := OnStopServer;
  Result.OnAccept := OnAcceptClient;
  Result.OnLog := DoLog;
end;

function TPeer.AddClient(const Address: string; Port: Word): TClientConnection;
begin
  Result := TClientConnection.Create;

  Clients.Add(Result);

  Result.Address := Address;
  Result.Port := Port;
  Result.OnReceive := OnReceiveClient;
  Result.OnDisconnect := OnDisconnectClient;
  Result.OnLog := DoLog;
end;

procedure TPeer.DoLog(const S: string; Level: TLevel);
begin
  if Assigned(FOnLog) then
    FOnLog(S, Level)
  {$IFDEF CONSOLE}
  else begin
    TMonitor.Enter(Self);
    try
      Writeln(S);
    finally
      TMonitor.Exit(Self);
    end;
  end
  {$ENDIF}
  ;
end;

procedure TPeer.Start;
begin
  FStarted := True;
  DoLog('Peer started', INFO);
  for var S in Servers do S.Start;
  for var C in Clients do C.Connect;
end;

procedure TPeer.Stop;
begin
  if FStarted then begin
    FStarted := False;
    for var S in Servers do S.Stop;
    for var C in Clients do C.Disconnect;
    for var C in ServerConnections do C.Disconnect;
    DoLog('Peer stopped', INFO);
  end;
end;

{ Events }
procedure TPeer.OnStopServer(Server: TSocketServer);
begin
end;

procedure TPeer.OnAcceptClient(Socket: TSocket);
begin
  DoLog('+ServerConnection', TRACE);

  var Client := TServerConnection.Accept(Socket);
  ServerConnections.Add(Client);

  Client.OnReceive := OnReceiveServerConnection;
  Client.OnDisconnect := OnDisconnectServerConnection;
  Client.OnLog := DoLog;

  Client.BeginReceive;
end;

procedure TPeer.OnDisconnectServerConnection(Client: TConnection);
begin
  DoLog('-ServerConnection', TRACE);
  Require(Client is TServerConnection, 'Trying to disconnect non server connection!');
  ServerConnections.Remove(Client as TServerConnection);
end;

procedure TPeer.OnReceiveClient(Client: TConnection; const Bytes: TBytes);
begin
  DoLog('<' + TEncoding.ANSI.GetString(Bytes), INFO);
end;

procedure TPeer.OnReceiveServerConnection(Client: TConnection; const Bytes: TBytes);
begin
  Client.Send(Bytes); // request as answer
end;

procedure TPeer.OnDisconnectClient(Client: TConnection);
begin
end;

end.
