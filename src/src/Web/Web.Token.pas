unit Web.Token;

interface

uses
  App.Exceptions,
  App.Types,
  App.Intf,
  Blockchain.Types,
  Crypto,
  System.SysUtils,
  System.JSON,
  HTTP.Server,
  Web.Base;

type
  TTokenEndpoints = class(TEndpointsBase)
  public
    procedure DoTokenMint(const Request: TRequest; var Response: TResponse);
    procedure GetTokenBalance(const Request: TRequest; var Response: TResponse);
    procedure GetTokenInfo(const Request: TRequest; var Response: TResponse);
    procedure DoTokenTransfer(const Request: TRequest; var Response: TResponse);
  end;

implementation

procedure TTokenEndpoints.DoTokenMint(const Request: TRequest;
  var Response: TResponse);
begin
  const JSON = ParseJSONObject(Request.Content);
  AddRelease(JSON);

  Response.SetJsonContent(GetHashJson(AppCore.DoTokenMint(
    JSON.GetValue<string>('name'),
    JSON.GetValue<string>('ticker'),
    JSON.GetValue<string>('description'),
    JSON.GetValue<Byte>('decimals'),
    JSON.GetValue<TAmount>('amount'),
    HexToBytes(JSON.GetValue<string>('icon', '')),
    JSON.GetValue<string>('private_key'))));
end;

procedure TTokenEndpoints.DoTokenTransfer(const Request: TRequest; var Response: TResponse);
begin
  const JSON = ParseJSONObject(Request.Content);
  AddRelease(JSON);

  const senderAddr      = JSON.GetValue<string>('from');
  const receiverAddress = JSON.GetValue<string>('to');
  const privateKey      = JSON.GetValue<string>('private_key');
  const amount          = JSON.GetValue<TAmount>('amount');

  const ticker          = JSON.GetValue<string>('ticker').ToUpper;
  const tokenId = AppCore.GetTokenData(Ticker).Id;

  Response.SetJsonContent(GetHashJson(AppCore.DoTokenTransfer(senderAddr, receiverAddress, amount, privateKey, tokenId)));
end;

procedure TTokenEndpoints.GetTokenBalance(const Request: TRequest; var Response: TResponse);
begin
  const Address = Request.Params.ValueOf('address');
  if Address.IsEmpty then raise EValidError.Create('request parameters error');

  const Ticker = Request.Params.ValueOf('ticker').ToUpper;
  const tokenId = AppCore.GetTokenData(Ticker).Id;

  var JSON := TJSONObject.Create;
  AddRelease(JSON);

  Response.SetJsonContent(JsonToBytes(JSON.AddPair('balance', TJSONNumber.Create(AppCore.GetTokenBalance(Address, tokenId)))));
end;

procedure TTokenEndpoints.GetTokenInfo(const Request: TRequest; var Response: TResponse);
begin
  const Ticker = Request.Params.ValueOf('ticker').ToUpper;
  const tokenInfo = AppCore.GetTokenData(Ticker);

  var JSON := TJSONObject.Create;
  AddRelease(JSON);

  Response.SetJsonContent(
    JsonToBytes(
      JSON.AddPair('id', TJSONNumber.Create(tokenInfo.Id))
      .AddPair('name', TJSONString.Create(tokenInfo.Name))
      .AddPair('ticker', TJSONString.Create(tokenInfo.Ticker))
      .AddPair('description', TJSONString.Create(tokenInfo.Description))
      .AddPair('iconURL', TJSONString.Create(tokenInfo.IconURL))
      .AddPair('ownerAddress', TJSONString.Create(tokenInfo.AddressOwner))
      .AddPair('decimals', TJSONNumber.Create(tokenInfo.Digits))
    )
  );

end;

end.
