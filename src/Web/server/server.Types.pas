unit server.Types;

interface

uses
  Classes,
  JSON,
  IdCustomHTTPServer,
  SyncObjs,
  SysUtils;

const
  HTTP_SUCCESS = 200;
  HTTP_BAD_REQUEST = 400;
  HTTP_UNAUTHORIZED = 401;
  HTTP_NOT_FOUND = 404;
  HTTP_INTERNAL_ERROR = 500;
  HTTP_SERVICE_UNAVAILABLE = 503;

  ERROR_UNKNOWN = 0;
  ERROR_NOT_FOUND = 1;
  ERROR_NOT_SUPPORTED = 2;
  ERROR_NO_RESPONSE = 3;
  ERROR_VALID = 4;
  ERROR_ADDRESS_NOT_EXISTS = 5;
  ERROR_INSUFFICIENT_FUNDS = 6;
  ERROR_SAME_ADDRESSES = 7;
  ERROR_VALIDATOR_DID_NOT_ANSWER = 8;
  ERROR_INVALID_SIGN = 9;
  ERROR_NO_ARCHIVERS_AVAILABLE = 10;
  ERROR_REQUEST_TIMEOUT = 11;

type
  TEndpointResponse = record
    Code: Integer;
    Response: string;
  end;

  TEndpointFunc = function(AEvent: TEvent; AComType: THTTPCommandType;
    AParams: TStrings; ABody: string): TEndpointResponse of object;

function GetJSONErrorAsString(ACode: Byte; AReason: string): string;

implementation

function GetStringErrorByCode(ACode: Byte): string;
begin
  case ACode of
    ERROR_UNKNOWN: Result := 'UNKNOWN_ERROR';
    ERROR_NOT_FOUND: Result := 'UNKNOWN_REQUEST';
    ERROR_NOT_SUPPORTED: Result := 'NOT_SUPPORTED';
    ERROR_NO_RESPONSE: Result := 'SERVER_DID_NOT_RESPOND';
    ERROR_VALID: Result := 'VALIDATION_FAILED';
    ERROR_ADDRESS_NOT_EXISTS: Result := 'ADDRESS_NOT_EXISTS';
    ERROR_INSUFFICIENT_FUNDS: Result := 'INSUFFICIENT_FUNDS';
    ERROR_SAME_ADDRESSES: Result := 'SAME_ADDRESSES';
    ERROR_VALIDATOR_DID_NOT_ANSWER: Result := 'VALIDATOR_DID_NOT_ANSWER';
    ERROR_INVALID_SIGN: Result := 'INVALID_SIGN';
    ERROR_NO_ARCHIVERS_AVAILABLE: Result := 'NO_ARCHIVERS_AVAILABLE';
    ERROR_REQUEST_TIMEOUT: Result := 'REQUEST_TIMEOUT';
  end;
end;

function GetJSONErrorAsString(ACode:Byte; AReason: string): string;
var
  JSON: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('error', GetStringErrorByCode(ACode));
    JSON.AddPair('message', AReason);
    Result := JSON.ToJSON;
  finally
    JSON.Free;
  end;
end;

end.
