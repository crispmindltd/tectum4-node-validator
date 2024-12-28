unit server.Types;

interface

uses
  Classes,
  JSON,
  IdCustomHTTPServer,
  SyncObjs,
  SysUtils;

const
  LOGIN_POSTFIX = '@softnote.com';

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
  ERROR_ACCOUNT_EXISTS = 5;
  ERROR_AUTH = 6;
  ERROR_KEY_EXPIRED = 7;
  ERROR_ADDRESS_NOT_EXISTS = 8;
  ERROR_INSUFFICIENT_FUNDS = 9;
  ERROR_TOKEN_EXISTS = 10;
  ERROR_SAME_ADDRESSES = 11;
  ERROR_SMART_NOT_EXISTS = 12;
  ERROR_NO_INFO_FOR_SMART = 13;
  ERROR_VALIDATOR_DID_NOT_ANSWER = 14;
  ERROR_NO_INFO_FOR_ACCOUNT = 15;
  ERROR_DOWNLOADING_NOT_FINISHED = 16;
  ERROR_INVALID_SIGN = 17;
  ERROR_REQUEST_IN_PROGRESS = 18;
  ERROR_TICKER_IS_PROHIBITED = 19;

type
  TEndpointResponse = record
    ReqID: String;
    Code: Integer;
    Response: String;
  end;

  TEndpointFunc = function(AReqID: String; AEvent: TEvent; AComType: THTTPCommandType;
    AParams: TStrings; ABody: String): TEndpointResponse of object;

function GetJSONErrorAsString(ACode:Byte; AReason: String): String;

implementation

function GetStringErrorByCode(ACode: Byte): String;
begin
  case ACode of
    ERROR_UNKNOWN: Result := 'UNKNOWN_ERROR';
    ERROR_NOT_FOUND: Result := 'UNKNOWN_REQUEST';
    ERROR_NOT_SUPPORTED: Result := 'NOT_SUPPORTED';
    ERROR_NO_RESPONSE: Result := 'SERVER_DID_NOT_RESPOND';
    ERROR_VALID: Result := 'VALIDATION_FAILED';
    ERROR_ACCOUNT_EXISTS: Result := 'ACCOUNT_ALREADY_EXISTS';
    ERROR_AUTH: Result := 'AUTHORIZATION_FAILED';
    ERROR_KEY_EXPIRED: Result := 'KEY_EXPIRED';
    ERROR_ADDRESS_NOT_EXISTS: Result := 'ADDRESS_NOT_EXISTS';
    ERROR_INSUFFICIENT_FUNDS: Result := 'INSUFFICIENT_FUNDS';
    ERROR_TOKEN_EXISTS: Result := 'TOKEN_ALREADY_EXISTS';
    ERROR_SAME_ADDRESSES: Result := 'SAME_ADDRESSES';
    ERROR_SMART_NOT_EXISTS: Result := 'SMARTCONTRACT_NOT_EXISTS';
    ERROR_NO_INFO_FOR_SMART: Result := 'NO_INFO_FOR_THIS_SMARTCONTRACT';
    ERROR_VALIDATOR_DID_NOT_ANSWER: Result := 'VALIDATOR_DID_NOT_ANSWER';
    ERROR_NO_INFO_FOR_ACCOUNT: Result := 'NO_INFO_FOR_THIS_ACCOUNT';
    ERROR_DOWNLOADING_NOT_FINISHED: Result := 'LOADING_OF_BLOCKS_IS_NOT_FINISHED';
    ERROR_INVALID_SIGN: Result := 'INVALID_SIGN';
    ERROR_REQUEST_IN_PROGRESS: Result := 'TRANSACTION_IN_PROGRESS';
    ERROR_TICKER_IS_PROHIBITED: Result := 'TICKER_IS_PROHIBITED';
  end;
end;

function GetJSONErrorAsString(ACode:Byte; AReason: String): String;
var
  JSON: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('error',GetStringErrorByCode(ACode));
    JSON.AddPair('message',AReason);
    Result := JSON.ToString;
  finally
    JSON.Free;
  end;
end;

end.
