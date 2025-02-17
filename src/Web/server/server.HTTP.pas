unit server.HTTP;

interface

uses
  App.Exceptions,
  App.Intf,
  App.Logs,
  Classes,
  endpoints.Node,
  endpoints.Coin,
  Generics.Collections,
  JSON,
  IdContext,
  IdCustomHTTPServer,
  IdHTTPServer,
  Net.Socket,
  server.Types,
  SyncObjs,
  SysUtils;

type
  THTTPServer = class(TIdHTTPServer)
  const
    CommandDoingTimeout = 12000;
  strict private
    FNodeEndpoints: TNodeEndpoints;
    FCoinEndpoints: TCoinEndpoints;
  private
    FCommands: TDictionary<string, TEndpointFunc>;

    procedure CommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start(APort: Word = 8917);
    procedure Stop;
  end;

implementation

{ THTTPServer }

procedure THTTPServer.CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  RawBody: AnsiString;
  URI, Body: string;
  ThreadID: LongWord;
  ReqDoneEvent: TEvent;
  EndpointResponse: TEndpointResponse;
  EndpointFunc: TEndpointFunc;
begin
  URI := ARequestInfo.URI.ToLower.Trim;
  ThreadID := TThread.CurrentThread.ThreadID;
  Logs.DoLog(Format('<R%d> %s', [ThreadID, ARequestInfo.RawHTTPCommand]), CmnLvlLogs);

  try
    try
      if not FCommands.TryGetValue(URI, EndpointFunc) then
        raise ENotFoundError.Create('');

      if Assigned(ARequestInfo.PostStream) and
        (ARequestInfo.PostStream is TMemoryStream) then
        begin
          const
            MemStream = TMemoryStream(ARequestInfo.PostStream);
          SetString(RawBody, PAnsiChar(MemStream.Memory), MemStream.Size);
          Body := UTF8ToWideString(RawBody);
        end;

      ReqDoneEvent := TEvent.Create;
      try
        EndpointResponse := EndpointFunc(ReqDoneEvent, ARequestInfo.CommandType,
          ARequestInfo.Params, Body);
        if not(ReqDoneEvent.WaitFor(CommandDoingTimeout) = wrSignaled) then
          raise Exception.Create('endpoint process timeout');
      finally
        ReqDoneEvent.Free;
      end;
    except
      on E:ENotFoundError do
      begin
        EndpointResponse.Code := HTTP_NOT_FOUND;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_NOT_FOUND,
          'unknown request');
      end;
      on E:ENotSupportedError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_NOT_SUPPORTED,
          'method not supported');
      end;
      on E:EJSONParseException do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_VALID,
          'request body parsing error');
      end;
      on E:EValidError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_VALID,
          E.Message);
      end;
      on E:ERequestTimeout do
      begin
        EndpointResponse.Code := HTTP_INTERNAL_ERROR;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_REQUEST_TIMEOUT,
          'request execution time expired. Try again later');
      end;
      on E:ENoArchiversAvailableError do
      begin
        EndpointResponse.Code := HTTP_INTERNAL_ERROR;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_NO_ARCHIVERS_AVAILABLE,
          'no archivers available at the moment. Try again later');
      end;
      on E:EAddressNotExistsError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_ADDRESS_NOT_EXISTS,
          'the address does not exists');
      end;
      on E:EInsufficientFundsError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_INSUFFICIENT_FUNDS, 'insufficient funds');
      end;
      on E:ESameAddressesError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_SAME_ADDRESSES,
          E.Message);
      end;
      on E:EValidatorDidNotAnswerError do
      begin
        EndpointResponse.Code := HTTP_INTERNAL_ERROR;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_VALIDATOR_DID_NOT_ANSWER,
          'validator did not answer, try later');
      end;
      on E:EInvalidSignError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_INVALID_SIGN,
          'signature not verified');
      end;
      on E:EUnknownError do
      begin
        EndpointResponse.Code := HTTP_INTERNAL_ERROR;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_UNKNOWN,
          'unknown error with code ' + E.Message);
      end;
      on E:Exception do
      begin
        EndpointResponse.Code := HTTP_INTERNAL_ERROR;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_UNKNOWN,
          'unknown error with message:' + E.Message);
      end;
    end;
  finally
    AResponseInfo.ResponseNo := EndpointResponse.Code;
    AResponseInfo.ContentText := EndpointResponse.Response;
    AResponseInfo.ContentType := 'application/json';
    Logs.DoLog(Format('<%d> [%d] %s', [ThreadID,
      AResponseInfo.ResponseNo, AResponseInfo.ContentText]), CmnLvlLogs, ltOutgo);
  end;
end;

constructor THTTPServer.Create;
begin
  inherited;

  FCommands := TDictionary<string, TEndpointFunc>.Create;
  FNodeEndpoints := TNodeEndpoints.Create;
  FCommands.Add('/version', FNodeEndpoints.Version);
  FCommands.Add('/keys/new', FNodeEndpoints.DoNewKeys);
  FCommands.Add('/keys/recover', FNodeEndpoints.DoRecoverKeys);
//  FCommands.Add('/blockscountl', FNodeEndpoints.BlocksCountLocal);
  FCommands.Add('/blockscount', FNodeEndpoints.BlocksCount);
//  FCommands.Add('/version', FNodeEndpoints.Version);
//  FCommands.Add('/keys/new', FMainEndpoints.DoNewKeys);
//  FCommands.Add('/keys/recover', FMainEndpoints.DoRecoverKeys);
//  FCommands.Add('/keys/public/byuserid', FMainEndpoints.GetPublicKeyByAccID);
//  FCommands.Add('/keys/public/byskey', FMainEndpoints.GetPublicKeyBySessionKey);
  FCoinEndpoints := TCoinEndpoints.Create;
  FCommands.Add('/coins/transfer', FCoinEndpoints.DoCoinTransfer);
  FCommands.Add('/coins/stake', FCoinEndpoints.DoCoinStake);
  FCommands.Add('/coins/migrate', FCoinEndpoints.DoMigrate);
  FCommands.Add('/coins/balance/byaddress',FCoinEndpoints.GetCoinBalance);
//  FCommands.Add('/coins/transfer', FTokenEndpoints.DoCoinTransfer);
//  FCommands.Add('/coins/transfer/fee', FTokenEndpoints.GetCoinTransferFee);
//  FCommands.Add('/coins/balances', FTokenEndpoints.GetCoinsBalances);
  FCommands.Add('/coins/transfers', FCoinEndpoints.GetCoinTransferHistory);
  FCommands.Add('/coins/transfers/user', FCoinEndpoints.GetCoinTransferHistoryUser);
//  FCommands.Add('/tokens', FTokenEndpoints.Tokens);
//  FCommands.Add('/tokens/fee', FTokenEndpoints.GetNewTokenFee);
//  FCommands.Add('/tokens/transfer', FTokenEndpoints.DoTokenTransfer);
//  FCommands.Add('/tokens/stake', FTokenEndpoints.DoTokenStake);
//  FCommands.Add('/tokens/transfer/fee', FTokenEndpoints.GetTokenTransferFee);
//  FCommands.Add('/tokens/balance/byaddress',
//    FTokenEndpoints.GetTokenBalanceWithAddress);
//  FCommands.Add('/tokens/balance/byticker',
//    FTokenEndpoints.GetTokenBalanceWithTicker);
//  FCommands.Add('/tokens/transfers', FTokenEndpoints.GetTokensTransferHistory);
//  FCommands.Add('/tokens/address/byid', FTokenEndpoints.GetAddressByID);
//  FCommands.Add('/tokens/address/byticker', FTokenEndpoints.GetAddressByTicker);
  OnCommandGet := CommandGet;
end;

destructor THTTPServer.Destroy;
begin
  FCoinEndpoints.Free;
  FNodeEndpoints.Free;
  FCommands.Free;

  inherited;
end;

procedure THTTPServer.Start(APort: Word);
begin
  DefaultPort := APort;
  Active := True;
  Logs.DoLog('HTTP server started at port: ' + APort.ToString, CmnLvlLogs, ltNone);
end;

procedure THTTPServer.Stop;
begin
  Active := False;
  Logs.DoLog('HTTP server stoped', CmnLvlLogs, ltNone);
end;

end.
