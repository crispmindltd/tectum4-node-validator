unit Web.Base;

interface

uses
  System.SysUtils,
  System.JSON,
  App.Types,
  HTTP.Server;

type
  TEndpointProc = procedure(const Request: TRequest; var Response: TResponse) of object;

  TEndpointsBase = class
  protected
    function ParseJSONObject(const Content: TBytes): TJSONObject;
  end;

function GetJsonBytes(const Key, Value: string): TBytes;
function GetHashJson(const Hash: string): TBytes;
function JsonToBytes(Json: TJsonValue): TBytes;
function GetJsonErrorAsBytes(const Error, Message: string): TBytes;

implementation

function TEndpointsBase.ParseJSONObject(const Content: TBytes): TJSONObject;
begin
  Result := TJSONObject.ParseJSONValue(Content, 0, [TJSONObject.TJSONParseOption.RaiseExc]) as TJSONObject;
end;

function GetJsonBytes(const Key, Value: string): TBytes;
begin
  var Json := TJSONObject.Create;
  AddRelease(Json);
  Json.AddPair(Key, Value);
  Result := JsonToBytes(Json);
end;

function GetHashJson(const Hash: string): TBytes;
begin
  Result := GetJsonBytes('hash', Hash);
end;

function JsonToBytes(Json: TJsonValue): TBytes;
begin
  Result := TEncoding.ANSI.GetBytes(Json.ToJSON);
end;

function GetJsonErrorAsBytes(const Error, Message: string): TBytes;
begin
  var JSON := TJSONObject.Create;
  AddRelease(JSON);
  JSON.AddPair('error', Error).AddPair('message', Message);
  Result := JsonToBytes(JSON);
end;

end.
