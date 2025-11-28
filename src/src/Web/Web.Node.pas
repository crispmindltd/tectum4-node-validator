unit Web.Node;

interface

uses
  System.SyncObjs,
  System.SysUtils,
  System.Classes,
  System.JSON,
  App.Exceptions,
  App.Intf,
  App.Types,
  Net.Intf,
  HTTP.Types,
  HTTP.Server,
  Web.Base;

type
  TNodeEndpoints = class(TEndpointsBase)
  public
    procedure DoNetStats(const Request: TRequest; var Response: TResponse);
    procedure BlocksCount(const Request: TRequest; var Response: TResponse);
    procedure Version(const Request: TRequest; var Response: TResponse);
    procedure DoNewKeys(const Request: TRequest; var Response: TResponse);
    procedure DoRecoverKeys(const Request: TRequest; var Response: TResponse);
  end;

implementation

procedure TNodeEndpoints.DoNetStats(const Request: TRequest; var Response: TResponse);
begin

  var JSON := TJSONObject.Create;
  AddRelease(JSON);

  var Servers := TJSONArray.Create;
  var Clients := TJSONArray.Create;

  JSON.AddPair('servers', Servers);
  JSON.AddPair('clients', Clients);

  var Stats := AppCore.GetNetStats;

  for var Server in Stats.Servers do
  begin
    var V := TJSONObject.Create;
    Servers.AddElement(V);
    V.AddPair('name', Server.Name);
    V.AddPair('state', ConnectionStateNames[Server.State]);
  end;

  for var Client in Stats.Clients do
  begin
    var V := TJSONObject.Create;
    Clients.AddElement(V);
    V.AddPair('name', Client.Name);
    V.AddPair('state', ConnectionStateNames[Client.State]);
  end;

  Response.SetJsonContent(JsonToBytes(JSON));

end;

procedure TNodeEndpoints.BlocksCount(const Request: TRequest; var Response: TResponse);
begin

  var JSON := TJSONObject.Create;
  AddRelease(JSON);

  JSON.AddPair('blocksCount', TJSONNumber.Create(AppCore.RecordsCount));

  Response.SetJsonContent(JsonToBytes(JSON));

end;

procedure TNodeEndpoints.DoNewKeys(const Request: TRequest; var Response: TResponse);
var
  SeedPhrase, PrKey, PubKey, Address: string;
begin

  AppCore.GenNewKeys(SeedPhrase, PrKey, PubKey, Address);
  var JSON := TJSONObject.Create;
  AddRelease(JSON);

  JSON.AddPair('seed_phrase', SeedPhrase);
  JSON.AddPair('private_key', PrKey);
  JSON.AddPair('public_key', PubKey);
  JSON.AddPair('address', Address);

  Response.SetJsonContent(JsonToBytes(JSON));

end;

procedure TNodeEndpoints.DoRecoverKeys(const Request: TRequest; var Response: TResponse);
var
  PubKey, PrKey, Address: string;
begin

  begin
    var JSON := ParseJSONObject(Request.Content);
    AddRelease(JSON);
    AppCore.DoRecoverKeys(JSON.GetValue<string>('seed_phrase'), PubKey, PrKey, Address);
  end;

  var JSON := TJSONObject.Create;
  AddRelease(JSON);

  JSON.AddPair('private_key', PrKey);
  JSON.AddPair('public_key', PubKey);
  JSON.AddPair('address', Address);

  Response.SetJsonContent(JsonToBytes(JSON));

end;

procedure TNodeEndpoints.Version(const Request: TRequest; var Response: TResponse);
begin
  Response.SetJsonContent(GetJsonBytes('version', AppCore.GetAppVersionText));
end;

end.
