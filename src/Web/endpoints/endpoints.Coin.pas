unit endpoints.Coin;

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
  App.Types,
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
  TCoinEndpoints = class(TEndpointsBase)
  private
//    function GetTokensList(AParams: TStrings): TEndpointResponse;
//    function DoNewToken(AReqID: string; ABody: string): TEndpointResponse;
  public
    constructor Create;
    destructor Destroy; override;

//    function Tokens(AReqID: string; AEvent: TEvent; AComType: THTTPCommandType;
//      AParams: TStrings; ABody: string): TEndpointResponse;
    function GetNewCoinFee(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
    function DoCoinTransfer(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
    function DoMigrate(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
    function DoCoinStake(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
    function GetCoinTransferFee(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
    function GetCoinBalance(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
//    function GetTokenBalanceWithTicker(AReqID: string; AEvent: TEvent;
//      AComType: THTTPCommandType; AParams: TStrings; ABody: string)
//      : TEndpointResponse;
    function GetCoinTransferHistory(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
    function GetCoinTransferHistoryUser(AEvent: TEvent; AComType: THTTPCommandType;
      AParams: TStrings; ABody: string): TEndpointResponse;
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

{ TCoinEndpoints }

constructor TCoinEndpoints.Create;
begin
  inherited;
end;

destructor TCoinEndpoints.Destroy;
begin

  inherited;
end;


procedure CheckMethod(AComType,Method: THTTPCommandType);
begin
  if AComType <> Method then raise ENotSupportedError.Create('');
end;

function GetStrParameter(Params: TStrings; const Name: string): string;
begin
  Result := Params.Values[Name];
  if Result.IsEmpty then
    raise EValidError.Create('request parameters error');
end;

function GetIntParameter(Params: TStrings; const Name: string; DefValue: Int64): Int64;
begin
  if Params.Values[Name].IsEmpty then
    Result := DefValue
  else if not TryStrToInt64(Params.Values[Name], Result) then
      raise EValidError.Create('request parameters error');
end;

function TCoinEndpoints.GetCoinBalance(AEvent: TEvent; AComType: THTTPCommandType;
  AParams: TStrings; ABody: string): TEndpointResponse;
var
  AFloatSize: Byte;
begin
  try
    CheckMethod(AComType, hcGET);
    var Address := AParams.Values['address'];

    if Address.IsEmpty then
      raise EValidError.Create('request parameters error');

    var JSON := TJSONObject.Create;

    AddRelease(JSON);

    JSON.AddPair('balance', TJSONNumber.Create(AppCore.GetTokenBalance(Address)));

    Result.Code := HTTP_SUCCESS;
    Result.Response := JSON.ToString;

  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;

end;

function TCoinEndpoints.GetCoinTransferFee(AEvent: TEvent; AComType: THTTPCommandType;
  AParams: TStrings; ABody: string): TEndpointResponse;
var
  JSON: TJSONObject;
begin
  try
    CheckMethod(AComType, hcGET);
    JSON := TJSONObject.Create;
    try
      // while fee = 0, there`s no need to get correct float size
      JSON.AddPair('fee', TJSONDecimal.Create(0, 8));
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

function TCoinEndpoints.GetNewCoinFee(AEvent: TEvent; AComType: THTTPCommandType;
  AParams: TStrings; ABody: string): TEndpointResponse;
var
  JSON: TJSONObject;
  Params: TStringList;
  Response: Integer;
begin
  Params := TStringList.Create(dupIgnore, True, False);
  try
    CheckMethod(AComType, hcGET);

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

function TCoinEndpoints.GetCoinTransferHistory(AEvent: TEvent;
  AComType: THTTPCommandType; AParams: TStrings; ABody: string): TEndpointResponse;
var
  JSON, JSONNestedObject: TJSONObject;
  JSONArray: TJSONArray;
  Params: TStringList;
  i, Rows, Skip: Integer;
begin
  Params := TStringList.Create(dupIgnore, True, False);
  try
    CheckMethod(AComType, hcGET);
    Params.AddStrings(AParams);

    Rows := GetIntParameter(Params, 'rows', 20);
    Skip := GetIntParameter(Params, 'skip', 0);

    JSON := TJSONObject.Create;
    AddRelease(JSON);
    JSONArray:=TJSONArray.Create;
    JSON.AddPair('transactions', JSONArray);

    for var Tx in AppCore.GetLastTransactions(Skip,Rows) do
    begin
      var Item:=TJSONObject.Create;
      Item.AddPair('block',Tx.TxId);
      Item.AddPair('hash',Tx.Hash);
      Item.AddPair('type',Tx.TxType);
      Item.AddPair('date',DateTimeToUnix(Tx.DateTime));
      Item.AddPair('address_from',Tx.AddressFrom);
      Item.AddPair('address_to',Tx.AddressTo);
      Item.AddPair('amount',Tx.Amount);
      Item.AddPair('fee',Tx.Fee);
      JSONArray.AddElement(Item);
    end;

    Result.Code := HTTP_SUCCESS;
    Result.Response := JSON.ToString;

  finally
    Params.Free;
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TCoinEndpoints.GetCoinTransferHistoryUser(AEvent: TEvent;
  AComType: THTTPCommandType; AParams: TStrings; ABody: string): TEndpointResponse;
var
  Params: TStringList;
begin
  Params := TStringList.Create(dupIgnore, True, False);
  try
    CheckMethod(AComType, hcGET);

    Params.AddStrings(AParams);

    var Address := GetStrParameter(Params, 'address');
    var Rows := GetIntParameter(Params, 'rows', 20);
    var Skip := GetIntParameter(Params, 'skip', 0);

    var JSON := TJSONObject.Create;
    AddRelease(JSON);
    var JSONArray:=TJSONArray.Create;
    JSON.AddPair('transactions', JSONArray);

    for var Tx in AppCore.GetUserLastTransactions(Address,Skip,Rows) do
    begin
      var Item:=TJSONObject.Create;
      Item.AddPair('block',Tx.TxId);
      Item.AddPair('hash',Tx.Hash);
      Item.AddPair('type',Tx.TxType);
      Item.AddPair('date',DateTimeToUnix(Tx.DateTime));
      Item.AddPair('address_from',Tx.AddressFrom);
      Item.AddPair('address_to',Tx.AddressTo);
      Item.AddPair('amount',Tx.Amount);
      Item.AddPair('fee',Tx.Fee);
      JSONArray.AddElement(Item);
    end;

    Result.Code := HTTP_SUCCESS;
    Result.Response := JSON.ToString;

  finally
    Params.Free;
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TCoinEndpoints.DoCoinStake(AEvent: TEvent; AComType: THTTPCommandType;
  AParams: TStrings; ABody: string): TEndpointResponse;
var
  Response: string;
  Addr, PrKey: string;
  TokensAmount: UInt64;
begin
  try
    CheckMethod(AComType, hcPOST);
    const JSON = TJSONObject.ParseJSONValue(ABody, False, True);
    try
      if not (//
        JSON.TryGetValue('address', Addr)//
        and JSON.TryGetValue('amount', TokensAmount)//
        and JSON.TryGetValue('private_key', PrKey)//
        ) then
        raise EValidError.Create('request parameters error');
    finally
      JSON.Free;
    end;

    Response := AppCore.DoTokenStake(Addr, TokensAmount, PrKey);

    Result.Code := HTTP_SUCCESS;
    Result.Response := '{"hash":"' + Response + '"}';

  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TCoinEndpoints.DoMigrate(AEvent: TEvent; AComType: THTTPCommandType; AParams: TStrings;
  ABody: string): TEndpointResponse;
var
  AddrFrom, AddrTo, PrKey: string;
  TokensAmount: UInt64;
begin
  try
    const JSON = TJSONObject.ParseJSONValue(ABody, False, True);
    try
      if not (//
        JSON.TryGetValue('from', AddrFrom)//
        and JSON.TryGetValue('to', AddrTo)//
        and JSON.TryGetValue('amount', TokensAmount)//
        and JSON.TryGetValue('private_key', PrKey)//
        ) then
        raise EValidError.Create('request parameters error');
    finally
      JSON.Free;
    end;
    const Response = AppCore.DoTokenMigrate(AddrFrom, AddrTo, TokensAmount, PrKey);

    Result.Code := HTTP_SUCCESS;
    Result.Response := '{"hash":"' + Response + '"}';

  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

function TCoinEndpoints.DoCoinTransfer(AEvent: TEvent; AComType: THTTPCommandType;
  AParams: TStrings; ABody: string): TEndpointResponse;
var
  Response: string;
  TransFrom, TransTo, PrKey: string;
  TokensAmount: UInt64;
begin
  try
    CheckMethod(AComType, hcPOST);
    const JSON = TJSONObject.ParseJSONValue(ABody, False, True);
    try
      if not (//
        JSON.TryGetValue('from', TransFrom)//
        and JSON.TryGetValue('to', TransTo)//
        and JSON.TryGetValue('amount', TokensAmount)//
        and JSON.TryGetValue('private_key', PrKey)//
        ) then
        raise EValidError.Create('request parameters error');

    finally
      JSON.Free;
    end;

    Response := AppCore.DoTokenTransfer(TransFrom, TransTo, TokensAmount, PrKey);

    Result.Code := HTTP_SUCCESS;
    Result.Response := '{"hash":"' + Response + '"}';
  finally
    if Assigned(AEvent) then
      AEvent.SetEvent;
  end;
end;

end.
