unit Web.Coin;

interface

uses
  System.SyncObjs,
  System.SysUtils,
  System.IOUtils,
  System.Math,
  System.Classes,
  System.DateUtils,
  System.JSON,
  Crypto,
  Crypto.Types,
  App.Exceptions,
  App.Intf,
  App.Types,
  Net.Data,
  Blockchain.Types,
  HTTP.Types,
  HTTP.Server,
  Web.Base;

type
  TCoinEndpoints = class(TEndpointsBase)
  public
    procedure DoCoinTransfer(const Request: TRequest; var Response: TResponse);
    procedure DoCoinSignedTransfer(const Request: TRequest; var Response: TResponse);
    procedure CreateSignedTx(const Request: TRequest; var Response: TResponse);
    procedure DoMigrate(const Request: TRequest; var Response: TResponse);
    procedure DoCoinStake(const Request: TRequest; var Response: TResponse);
    procedure DoCoinUnstake(const Request: TRequest; var Response: TResponse);
    procedure GetCoinBalance(const Request: TRequest; var Response: TResponse);
    procedure GetCoinTransferHistory(const Request: TRequest; var Response: TResponse);
    procedure GetCoinTransferInfo(const Request: TRequest; var Response: TResponse);
    procedure GetCoinTransferHistoryUser(const Request: TRequest; var Response: TResponse);
    procedure GetBlockInfo(const Request: TRequest; var Response: TResponse);
  end;

implementation

procedure TCoinEndpoints.GetCoinBalance(const Request: TRequest; var Response: TResponse);
begin
  var Address := Request.Params.ValueOf('address');
  if Address.IsEmpty then
    raise EValidError.Create('request parameters error');

  var JSON := TJSONObject.Create;
  AddRelease(JSON);

  Response.SetJsonContent(JsonToBytes(JSON.AddPair('balance', TJSONNumber.Create(AppCore.GetTokenBalance(Address, 0 {TECid})))));
end;

function TransactionToJson(const Tx: TTransactionInfo): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('block', Tx.Id);
  Result.AddPair('hash', Tx.Hash);
  Result.AddPair('type', Tx.TxType);
  Result.AddPair('no', Tx.No);
  Result.AddPair('date', Tx.DateTime.ToUnixTime);
  Result.AddPair('address_from', Tx.AddressFrom);
  Result.AddPair('address_to', Tx.AddressTo);
  Result.AddPair('amount', Tx.Amount);
  Result.AddPair('fee', Tx.Fee);
end;

function BlockToJson(const Block: TBlockInfo): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', Block.Id);
  Result.AddPair('hash', Block.Hash);
  Result.AddPair('prev_hash', Block.PrevHash);
  Result.AddPair('nonce', Block.Nonce);
  Result.AddPair('index_to', Block.IndexTo);
  Result.AddPair('date', Block.DateTime.ToUnixTime);
  Result.AddPair('miner', Block.Address);
  Result.AddPair('reward', Block.Reward);
  Result.AddPair('stake', Block.StakeAmount);
end;

procedure TCoinEndpoints.GetCoinTransferHistory(const Request: TRequest; var Response: TResponse);
begin

  var Rows := StrToIntDef(Request.Params.ValueOf('rows'), 20);
  var Skip := StrToIntDef(Request.Params.ValueOf('skip'), 0);

  var JSON := TJSONObject.Create;
  AddRelease(JSON);
  var JSONArray := TJSONArray.Create;
  JSON.AddPair('transactions', JSONArray);

  for var Tx in AppCore.GetLastTransactions(Skip,Rows) do
    JSONArray.AddElement(TransactionToJson(Tx));

  Response.SetJsonContent(JsonToBytes(JSON));

end;

procedure TCoinEndpoints.GetCoinTransferHistoryUser(const Request: TRequest; var Response: TResponse);
begin

  var Address := Request.Params.ValueOf('address');
  var Rows := StrToIntDef(Request.Params.ValueOf('rows'), 20);
  var Skip := StrToIntDef(Request.Params.ValueOf('skip'), 0);

  var JSON := TJSONObject.Create;
  AddRelease(JSON);
  var JSONArray:=TJSONArray.Create;
  JSON.AddPair('transactions', JSONArray);

  for var Tx in AppCore.GetUserLastTransactions(Address,Skip,Rows) do
    JSONArray.AddElement(TransactionToJson(Tx));

  Response.SetJsonContent(JsonToBytes(JSON));

end;

procedure TCoinEndpoints.GetCoinTransferInfo(const Request: TRequest; var Response: TResponse);
begin

  var Tx: TTransactionInfo;
  var Id := Request.Params.ValueOf('id');
  var Hash := Request.Params.ValueOf('hash');
  if Hash <> '' then
    Tx := AppCore.GetTransactionInfo(Hash)
  else
    Tx := AppCore.GetTransactionInfo(StrToInt64(Id));

  var JSON := TransactionToJson(Tx);
  AddRelease(JSON);

  Response.SetJsonContent(JsonToBytes(JSON));

end;

procedure TCoinEndpoints.CreateSignedTx(const Request: TRequest; var Response: TResponse);
begin

  const JSON = ParseJSONObject(Request.Content);
  AddRelease(JSON);

  Response.SetJsonContent(GetJsonBytes('signed_tx',
    AppCore.DoSignedTransfer(
      JSON.GetValue<string>('from'),
      JSON.GetValue<string>('to'),
      JSON.GetValue<TAmount>('amount'),
      JSON.GetValue<string>('private_key'))));

end;

procedure TCoinEndpoints.DoCoinSignedTransfer(const Request: TRequest; var Response: TResponse);
begin

  const JSON = ParseJSONObject(Request.Content);
  AddRelease(JSON);

  Response.SetJsonContent(GetHashJson(AppCore.DoSendRawTransaction(
    JSON.GetValue<string>('signed_tx'))));

end;

procedure TCoinEndpoints.DoCoinStake(const Request: TRequest; var Response: TResponse);
begin

  const JSON = ParseJSONObject(Request.Content);
  AddRelease(JSON);

  Response.SetJsonContent(GetHashJson(AppCore.DoTokenStake(
    JSON.GetValue<string>('address'),
    JSON.GetValue<TAmount>('amount'),
    JSON.GetValue<string>('private_key'))));

end;

procedure TCoinEndpoints.DoMigrate(const Request: TRequest; var Response: TResponse);
begin

  const JSON = ParseJSONObject(Request.Content);
  AddRelease(JSON);

  Response.SetJsonContent(GetHashJson(AppCore.DoTokenMigrate(
    JSON.GetValue<string>('from'),
    JSON.GetValue<string>('to'),
    JSON.GetValue<TAmount>('amount'),
    JSON.GetValue<string>('private_key'))));

end;

procedure TCoinEndpoints.DoCoinTransfer(const Request: TRequest; var Response: TResponse);
begin
  const JSON = ParseJSONObject(Request.Content);
  AddRelease(JSON);

  var ToValue := JSON.GetValue<TJSONValue>('to');
  if ToValue.ClassType = TJSONArray then begin
    var ATo: TArray<TTransferTo>;
    for var Item in ToValue.AsType<TJSONArray> do begin
      var A: TTransferTo;
      A.Address := Item.GetValue('address', A.Address);
      A.Amount := Item.GetValue('amount', A.Amount);
      ATo := ATo + [A];
    end;
    Response.SetJsonContent(GetHashJson(AppCore.DoTokenTransfers(
      JSON.GetValue<string>('from'),
      ATo,
      JSON.GetValue<string>('private_key'))));
  end else begin
    Response.SetJsonContent(GetHashJson(AppCore.DoTokenTransfer(
      JSON.GetValue<string>('from'),
      ToValue.AsType<string>,
      JSON.GetValue<TAmount>('amount'),
      JSON.GetValue<string>('private_key'), 0 {TEC id})));
  end;
end;

procedure TCoinEndpoints.DoCoinUnstake(const Request: TRequest; var Response: TResponse);
begin

  const JSON = ParseJSONObject(Request.Content);
  AddRelease(JSON);

  Response.SetJsonContent(GetHashJson(AppCore.DoTokenUnstake(
    JSON.GetValue<string>('address'),
    JSON.GetValue<TAmount>('amount'),
    JSON.GetValue<string>('private_key'))));

end;

procedure TCoinEndpoints.GetBlockInfo(const Request: TRequest; var Response: TResponse);
begin

  var Hash := Request.Params.ValueOf('hash');

  if not Hash.IsEmpty then
  begin

    var Block := AppCore.GetBlockInfo(Hash);

    var JSON := BlockToJson(Block);
    AddRelease(JSON);

    Response.SetJsonContent(JsonToBytes(JSON));

  end else
  begin

    var Rows := StrToIntDef(Request.Params.ValueOf('rows'), 20);
    var Skip := StrToIntDef(Request.Params.ValueOf('skip'), 0);

    var JSON := TJSONObject.Create;
    AddRelease(JSON);
    var JSONArray:=TJSONArray.Create;
    JSON.AddPair('blocks', JSONArray);

    for var Block in AppCore.GetLastBlocksInfo(Skip, Rows) do
      JSONArray.AddElement(BlockToJson(Block));

    Response.SetJsonContent(JsonToBytes(JSON));

  end;

end;

end.
