unit endpoints.Token;

interface

uses
  Blockchain.Data,
  Blockchain.Validation,
  Blockchain.Reward,
  Blockchain.Txn,
  Blockchain.Address,
  Crypto,

  App.Exceptions,
  App.Intf,
  System.Classes,
  System.DateUtils,
  endpoints.Base,
  System.JSON,
  IdCustomHTTPServer,
  System.IOUtils,
  System.Math,
  Net.Data,
  server.Types,
  System.SyncObjs,
  System.SysUtils;

type
  TTokenEndpoints = class(TEndpointsBase)
  private
//    function GetTokensList(AParams: TStrings): TEndpointResponse;
//    function DoNewToken(AReqID: string; ABody: string): TEndpointResponse;
  public
    constructor Create;
    destructor Destroy; override;

//    function Tokens(AReqID: string; AEvent: TEvent; AComType: THTTPCommandType;
//      AParams: TStrings; ABody: string): TEndpointResponse;
    function GetNewTokenFee(AReqID: string; AEvent: TEvent;
      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
      : TEndpointResponse;
    function DoTokenTransfer(AReqID: string; AEvent: TEvent;
      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
      : TEndpointResponse;
    function DoTokenStake(AReqID: string; AEvent: TEvent;
      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
      : TEndpointResponse;
    function GetTokenTransferFee(AReqID: string; AEvent: TEvent;
      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
      : TEndpointResponse;
    function GetTokenBalance(AReqID: string; AEvent: TEvent;
      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
      : TEndpointResponse;
//    function GetTokenBalanceWithTicker(AReqID: string; AEvent: TEvent;
//      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
//      : TEndpointResponse;
    function GetTokensTransferHistory(AReqID: string; AEvent: TEvent;
      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
      : TEndpointResponse;
//    function GetAddressByID(AReqID: string; AEvent: TEvent;
//      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
//      : TEndpointResponse;
//    function GetAddressByTicker(AReqID: string; AEvent: TEvent;
//      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
//      : TEndpointResponse;
  end;

  TJSONDecimal = class(TJSONString)
    constructor Create(Value: Double; DecimalsCount:Integer);
    procedure ToChars(Builder: TStringBuilder; Options: TJSONAncestor.TJSONOutputOptions); override;
  end;

implementation

{ TJSONDecimal }

constructor TJSONDecimal.Create(Value: Double; DecimalsCount:Integer);
begin
  Assert(DecimalsCount in [1 .. 18], 'Incorrect decimals count');
  var fs:TFormatSettings := FormatSettings;
  fs.DecimalSeparator := '.';
  const FormatStr = '0.' + String.Create('#', DecimalsCount);
  inherited Create(FormatFloat(FormatStr, Value, fs));
end;

procedure TJSONDecimal.ToChars(Builder: TStringBuilder; Options: TJSONAncestor.TJSONOutputOptions);
begin
  Builder.Append(FValue);
end;

// calculates digits after decimal separator
function DecimalsCount(const AValue: string): Integer;
begin
  var LValue:string := AValue //
    .Trim //
    .Replace('.', FormatSettings.DecimalSeparator) //
    .Replace(',', FormatSettings.DecimalSeparator) //
    .ToUpper;

  var Exponent:Integer := 0;
  const ExponentPos = Pos('E', LValue);

  if ExponentPos > 0 then begin
    Exponent := StrToInt(Copy(LValue, ExponentPos + 1));
    LValue := Copy(LValue, 1, ExponentPos - 1);
  end;

  const DecimalPos = Pos(FormatSettings.DecimalSeparator, LValue);

  if DecimalPos = 0 then
    Result := -Exponent
  else
    Result := Length(LValue) - DecimalPos - Exponent;

  if Result < 0 then Result := 0;
end;

{ TTokenEndpoints }

constructor TTokenEndpoints.Create;
begin
  inherited;
end;

destructor TTokenEndpoints.Destroy;
begin

  inherited;
end;


function TTokenEndpoints.GetTokenBalance(AReqID: string; AEvent: TEvent;
  AComType: THTTPCommandType; AParams: TStrings; ABody: string): TEndpointResponse;
var
  JSON: TJSONObject;
  Params: TStringList;
  Value: Double;
  FloatSize: Byte;
begin
  Result.ReqID := AReqID;
  Params := TStringList.Create(dupIgnore, True, False);
  try
    if AComType <> hcGET then
      raise ENotSupportedError.Create('');

    Params.AddStrings(AParams);
//    const TokenAddress = Params.Values['smart_address'];
    const Address = Params.Values['address'];

    if Address.IsEmpty then //or TokenAddress.IsEmpty
      raise EValidError.Create('request parameters error');

    Value := AppCore.GetTokenBalance(Address, FloatSize);
    JSON := TJSONObject.Create;
    try
      JSON.AddPair('balance', TJSONDecimal.Create(Value, FloatSize));
      Result.Code := HTTP_SUCCESS;
      Result.Response := JSON.ToString;
    finally
      JSON.Free;
    end;
  finally
    Params.Free;
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TTokenEndpoints.GetTokenTransferFee(AReqID: string; AEvent: TEvent;
  AComType: THTTPCommandType; AParams: TStrings; ABody: string): TEndpointResponse;
var
  JSON: TJSONObject;
begin
  Result.ReqID := AReqID;
  try
    if AComType <> hcGET then
      raise ENotSupportedError.Create('');

    JSON := TJSONObject.Create;
    try
      // while fee = 0, there`s no need to get correct float size
      JSON.AddPair('fee', TJSONDecimal.Create(0, 8 {Token.FloatSize}));
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

function TTokenEndpoints.GetNewTokenFee(AReqID: string; AEvent: TEvent;
  AComType: THTTPCommandType; AParams: TStrings; ABody: string): TEndpointResponse;
var
  JSON: TJSONObject;
  Params: TStringList;
  Response: Integer;
begin
  Result.ReqID := AReqID;
  Params := TStringList.Create(dupIgnore, True, False);
  try
    if AComType <> hcGET then
      raise ENotSupportedError.Create('');

    Params.AddStrings(AParams);
    const DecimalsStr = Params.Values['decimals'];
    const TokenAmountStr = Params.Values['token_amount'];
    if TokenAmountStr.IsEmpty or DecimalsStr.IsEmpty then
      raise EValidError.Create('request parameters error');

    const Decimals = DecimalsStr.ToInteger;
    const TokenAmount = TokenAmountStr.ToInt64;
    Response := AppCore.GetNewTokenFee(TokenAmount, Decimals);

    JSON := TJSONObject.Create;
    try
      JSON.AddPair('fee', TJSONDecimal.Create(Response, Decimals));
      Result.Code := HTTP_SUCCESS;
      Result.Response := JSON.ToString;
    finally
      JSON.Free;
    end;
  finally
    Params.Free;
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;


function TTokenEndpoints.GetTokensTransferHistory(AReqID: string;
  AEvent: TEvent; AComType: THTTPCommandType; AParams: TStrings; ABody: string)
  : TEndpointResponse;
var
  JSON, JSONNestedObject: TJSONObject;
  JSONArray: TJSONArray;
  Params: TStringList;
  i, Rows, Skip: Integer;
begin
  Result.ReqID := AReqID;
  Params := TStringList.Create(dupIgnore, True, False);
  try
    if AComType <> hcGET then
      raise ENotSupportedError.Create('');

    Params.AddStrings(AParams);
    const Ticker = Params.Values['ticker'].ToUpper;
    if Ticker.IsEmpty then
      raise EValidError.Create('request parameters error');
    if Params.Values['rows'].IsEmpty then
      Rows := 20
    else if not TryStrToInt(Params.Values['rows'], Rows) then
      raise EValidError.Create('request parameters error');
    if Params.Values['skip'].IsEmpty then
      Skip := 0
    else if not TryStrToInt(Params.Values['skip'], Skip) then
      raise EValidError.Create('request parameters error');

    JSON := TJSONObject.Create;
    try

      JSON.AddPair('transactions', JSONArray);

      Result.Code := HTTP_SUCCESS;
      Result.Response := JSON.ToString;
    finally
      JSON.Free;
    end;
  finally
    Params.Free;
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TTokenEndpoints.DoTokenStake(AReqID: string; AEvent: TEvent;
  AComType: THTTPCommandType; AParams: TStrings; ABody: string): TEndpointResponse;
var
  Response: string;
  Addr, PrKey, PubKey: string;
  TokensAmount: UInt64;

begin
  Result.ReqID := AReqID;
  try
    if AComType <> hcPOST then
      raise ENotSupportedError.Create('');

    const JSON = TJSONObject.ParseJSONValue(ABody, False, True);
    try
      if not (//
        JSON.TryGetValue('address', Addr)//
        and JSON.TryGetValue('amount', TokensAmount)//
        and JSON.TryGetValue('private_key', PrKey)//
        and JSON.TryGetValue('public_key', PubKey)//
        ) then
        raise EValidError.Create('request parameters error');
    finally
      JSON.Free;
    end;

    Response := AppCore.DoTokenStake(Addr, TokensAmount, PrKey, PubKey);

    Result.Code := HTTP_SUCCESS;
    Result.Response := '{"hash":"' + Response + '"}';

  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TTokenEndpoints.DoTokenTransfer(AReqID: string; AEvent: TEvent;
  AComType: THTTPCommandType; AParams: TStrings; ABody: string): TEndpointResponse;
var
  Response: string;
  TransFrom, TransTo, PrKey, PubKey: string;
  TokensAmount: UInt64;
begin
  Result.ReqID := AReqID;
  try
    if AComType <> hcPOST then
      raise ENotSupportedError.Create('');

    const JSON = TJSONObject.ParseJSONValue(ABody, False, True);
    try
      if not (//
        JSON.TryGetValue('from', TransFrom)//
        and JSON.TryGetValue('to', TransTo)//
        and JSON.TryGetValue('amount', TokensAmount)//
        and JSON.TryGetValue('private_key', PrKey)//
        and JSON.TryGetValue('public_key', PubKey)//
        ) then
        raise EValidError.Create('request parameters error');

    finally
      JSON.Free;
    end;

    Response := AppCore.DoTokenTransfer(TransFrom, TransTo, TokensAmount, PrKey, PubKey);

    Result.Code := HTTP_SUCCESS;
    Result.Response := '{"hash":"' + Response + '"}';
  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

end.
