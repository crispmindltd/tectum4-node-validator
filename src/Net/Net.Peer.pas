unit Net.Peer;

interface

uses
  System.SysUtils,
  System.Types,
  System.Classes,
  System.SyncObjs,
  System.Net.Socket,
  System.Net.URLClient,
  Net.Types,
  Net.List,
  Net.SocketA;

type
  TPeer = class
  private
    FServers: TSafeList<TServer>;
    FClients: TSafeList<TClient>;
    FServerClients: TSafeList<TServerClient>;
    FOnLog: TLogEvent;
    procedure DoLog(const S: string; Level: TLevel);
    procedure OnStopServer(Server: TServer);
    procedure OnAcceptClient(Socket: TSocket);
    procedure OnDisconnectServerClient(Client: TServerClient);
    procedure OnDisconnectClient(Client: TClient);
    procedure OnReceiveClient(Client: TSameClient; const Bytes: TBytes);
    procedure OnReceiveServerClient(Client: TSameClient; const Bytes: TBytes);
  public
    constructor Create;
    destructor Destroy; override;
    function AddServer(Port: Word): TServer;
    function AddClient(const Address: string; Port: Word): TClient;
    procedure Start;
    procedure Stop;
    property Servers: TSafeList<TServer> read FServers;
    property ServerClients: TSafeList<TServerClient> read FServerClients;
    property Clients: TSafeList<TClient> read FClients;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

implementation

constructor TPeer.Create;
begin
  Fservers := TSafeList<TServer>.Create;
  FServerClients := TSafeList<TServerClient>.Create;
  FClients := TSafeList<TClient>.Create;
end;

destructor TPeer.Destroy;
begin
  DoLog('Peer destroying', DEBUG);
  Servers.Free;
  Clients.Free;
  ServerClients.Free;
  DoLog('Peer destroy', DEBUG);
end;

function TPeer.AddServer(Port: Word): TServer;
begin

  Result := TServer.Create;

  Servers.Add(Result);

  Result.Port := Port;
  Result.OnStop := OnStopServer;
  Result.OnAccept := OnAcceptClient;
  Result.OnLog := DoLog;

end;

function TPeer.AddClient(const Address: string; Port: Word): TClient;
begin

  Result := TClient.Create;

  Clients.Add(Result);

  Result.Address := Address;
  Result.Port := Port;
  Result.OnReceive := OnReceiveClient;
  Result.OnDisconnect := OnDisconnectClient;
  Result.OnLog := DoLog;

end;

procedure TPeer.DoLog(const S: string; Level: TLevel);
begin
  if Assigned(FOnLog) then FOnLog(S, Level)
  {$IFDEF CONSOLE}
  else begin
    TMonitor.Enter(Self);
    try
      Writeln(S);
    finally
      TMonitor.Exit(Self);
    end;
  end;
  {$ENDIF}
end;

procedure TPeer.Start;
begin
  DoLog('Peer started', INFO);
  for var S in Servers do S.Start;
  for var C in Clients do C.Connect;
end;

procedure TPeer.Stop;
begin
  for var S in Servers do S.Stop;
  for var C in Clients do C.Disconnect;
  for var C in ServerClients do C.Disconnect;
  DoLog('Peer stopped', INFO);
end;

{ Events }

procedure TPeer.OnStopServer(Server: TServer);
begin
end;

procedure TPeer.OnAcceptClient(Socket: TSocket);
begin

  DoLog('+ServerClient', TRACE);

  var Client:=TServerClient.Accept(Socket);

  ServerClients.Add(Client);

  Client.OnReceive := OnReceiveServerClient;
  Client.OnDisconnect := OnDisconnectServerClient;
  Client.OnLog := DoLog;

  Client.BeginReceive;

end;

procedure TPeer.OnDisconnectServerClient(Client: TServerClient);
begin
  DoLog('-ServerClient', TRACE);
  ServerClients.Remove(Client);
end;

procedure TPeer.OnReceiveClient(Client: TSameClient; const Bytes: TBytes);
begin
  DoLog('<' + TEncoding.ANSI.GetString(Bytes), INFO);
end;

procedure TPeer.OnReceiveServerClient(Client: TSameClient; const Bytes: TBytes);
begin
  Client.Send(Bytes); // request as answer
end;

procedure TPeer.OnDisconnectClient(Client: TClient);
begin
end;

end.
