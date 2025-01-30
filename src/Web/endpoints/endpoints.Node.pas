unit endpoints.Node;

interface

uses
  App.Exceptions,
  App.Intf,
  Update.Core,
  Classes,
  endpoints.Base,
  JSON,
  IdCustomHTTPServer,
  server.Types,
  SyncObjs,
  SysUtils;

type
  TNodeEndpoints = class(TEndpointsBase)
  public
    constructor Create;
    destructor Destroy; override;

//    function BlocksCountLocal(AReqID: string; AEvent: TEvent;
//      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
//      : TEndpointResponse;
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

//function TNodeEndpoints.BlocksCountLocal(AReqID: string; AEvent: TEvent;
//  AComType: THTTPCommandType; AParams: TStrings; ABody: string): TEndpointResponse;
//var
//  JSON: TJSONObject;
//begin
//  Result.ReqID := AReqID;
//  try
//    JSON := TJSONObject.Create;
//    if AComType <> hcGET then
//      raise ENotSupportedError.Create('');
//    try
//      JSON.AddPair('blocksCount',
//        TJSONNumber.Create(AppCore.GetTETChainBlocksCount));
//      Result.Code := HTTP_SUCCESS;
//      Result.Response := JSON.ToString;
//    finally
//      JSON.Free;
//    end;
//  finally
//    if Assigned(AEvent) then
//      AEvent.SetEvent;
//  end;
//end;

constructor TNodeEndpoints.Create;
begin
  inherited;
end;

destructor TNodeEndpoints.Destroy;
begin

  inherited;
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
