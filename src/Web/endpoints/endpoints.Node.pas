unit endpoints.Node;

interface

uses
  System.SyncObjs,
  System.SysUtils,
  System.Classes,
  System.JSON,
  IdCustomHTTPServer,
  App.Exceptions,
  App.Intf,
  App.Types,
  Net.Intf,
  endpoints.Base,
  server.Types;

type
  TNodeEndpoints = class(TEndpointsBase)
  public
    function DoNetStats(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
    function BlocksCount(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
    function Version(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
    function DoNewKeys(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
    function DoRecoverKeys(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
  end;

implementation

function TNodeEndpoints.DoNetStats(AEvent: TEvent; AComType: THTTPCommandType;
  AParams: TStrings; ABody: string): TEndpointResponse;
begin
  try

    if (AComType <> hcGET) and (AComType <> hcPOST) then
      raise ENotSupportedError.Create('');

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

    Result.Code := HTTP_SUCCESS;
    Result.Response := JSON.ToJSON;

  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TNodeEndpoints.BlocksCount(AEvent: TEvent; AComType: THTTPCommandType;
  AParams: TStrings; ABody: string): TEndpointResponse;
var
  JSON: TJSONObject;
begin
  try
    if AComType <> hcGET then
      raise ENotSupportedError.Create('');

    JSON := TJSONObject.Create;
    try
      JSON.AddPair('blocksCount', TJSONNumber.Create(AppCore.GetBlocksCount));
      Result.Code := HTTP_SUCCESS;
      Result.Response := JSON.ToString;
    finally
      JSON.Free;
    end;
  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TNodeEndpoints.DoNewKeys(AEvent: TEvent; AComType: THTTPCommandType;
  AParams: TStrings; ABody: string): TEndpointResponse;
var
  JSON: TJSONObject;
  SeedPhrase, PrKey, PubKey, Address: string;
begin
  try
    if (AComType <> hcGET) and (AComType <> hcPOST) then
      raise ENotSupportedError.Create('');

    AppCore.GenNewKeys(SeedPhrase, PrKey, PubKey, Address);
    JSON := TJSONObject.Create;
    try
      JSON.AddPair('seed_phrase', SeedPhrase);
      JSON.AddPair('private_key', PrKey);
      JSON.AddPair('public_key', PubKey);
      JSON.AddPair('address', Address);
      Result.Code := HTTP_SUCCESS;
      Result.Response := JSON.ToString;
    finally
      JSON.Free;
    end;
  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TNodeEndpoints.DoRecoverKeys(AEvent: TEvent; AComType: THTTPCommandType;
  AParams: TStrings; ABody: string): TEndpointResponse;
var
  JSON: TJSONObject;
  PubKey, PrKey, Seed, Address, Response: string;
begin
  try
    if AComType <> hcPOST then
      raise ENotSupportedError.Create('');

    JSON := TJSONObject.ParseJSONValue(ABody, False, True) as TJSONObject;
    try
      if not JSON.TryGetValue('seed_phrase', Seed) then
        raise EValidError.Create('request parameters error');
    finally
      JSON.Free;
    end;

    Response := AppCore.DoRecoverKeys(Seed, PubKey, PrKey, Address);
    JSON := TJSONObject.Create;
    try
      JSON.AddPair('private_key', PrKey);
      JSON.AddPair('public_key', PubKey);
      JSON.AddPair('address', Address);
      Result.Code := HTTP_SUCCESS;
      Result.Response := JSON.ToString;
    finally
      JSON.Free;
    end;
  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TNodeEndpoints.Version(AEvent: TEvent; AComType: THTTPCommandType;
  AParams: TStrings; ABody: string): TEndpointResponse;
var
  JSON: TJSONObject;
begin
  try
    if AComType <> hcGET then
      raise ENotSupportedError.Create('');

    JSON := TJSONObject.Create;
    try
      JSON.AddPair('version', AppCore.GetAppVersionText);
      Result.Code := HTTP_SUCCESS;
      Result.Response := JSON.ToString;
    finally
      JSON.Free;
    end;
  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

end.
