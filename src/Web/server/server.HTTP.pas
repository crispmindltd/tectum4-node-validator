unit server.HTTP;

interface

uses
  App.Exceptions,
  App.Intf,
  App.Logs,
  Classes,
  endpoints.Node,
  endpoints.Token,
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
    FTokenEndpoints: TTokenEndpoints;
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
  Logs.DoLog(Format('<R%d> %s', [ThreadID, ARequestInfo.RawHTTPCommand]));

  try
    try
      if not FCommands.TryGetValue(URI, EndpointFunc) then
        raise ENotFoundError.Create('');
//      else if not AppCore.BlocksSyncDone then
//        raise EDownloadingNotFinished.Create('');

      if Assigned(ARequestInfo.PostStream) then
      begin
        if (ARequestInfo.PostStream is TMemoryStream) then
        begin
          const
            MemStream = TMemoryStream(ARequestInfo.PostStream);
          SetString(RawBody, PAnsiChar(MemStream.Memory), MemStream.Size);
          Body := UTF8ToWideString(RawBody);
        end;
      end;

      ReqDoneEvent := TEvent.Create;
      try
        EndpointResponse := EndpointFunc('R' + ThreadID.ToString, ReqDoneEvent,
          ARequestInfo.CommandType, ARequestInfo.Params, Body);
        if not(ReqDoneEvent.WaitFor(CommandDoingTimeout) = wrSignaled) then
          raise ESocketError.Create('');
      finally
        ReqDoneEvent.Free;
      end;
    except
      on E: ENotFoundError do
      begin
        EndpointResponse.Code := HTTP_NOT_FOUND;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_NOT_FOUND,
          'unknown request');
      end;
      on E: EDownloadingNotFinished do
      begin
        EndpointResponse.Code := HTTP_SERVICE_UNAVAILABLE;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_DOWNLOADING_NOT_FINISHED,
          'please wait until the blocks are loaded');
      end;
      on E: ENotSupportedError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_NOT_SUPPORTED,
          'method not supported');
      end;
      on E: EJSONParseException do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_VALID,
          'request body parsing error');
      end;
      on E: EValidError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_VALID,
          E.Message);
      end;
      on E: EAuthError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_AUTH,
          'incorrect login or password');
      end;
      on E: EKeyExpiredError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_KEY_EXPIRED,
          'key expired');
      end;
      on E: EAccAlreadyExistsError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_ACCOUNT_EXISTS,
          'account already exists');
      end;
      on E: EAddressNotExistsError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_ADDRESS_NOT_EXISTS,
          'the address does not exists');
      end;
      on E: EInsufficientFundsError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_INSUFFICIENT_FUNDS, 'insufficient funds');
      end;
      on E: ETokenAlreadyExists do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_TOKEN_EXISTS,
          'account already exists');
      end;
      on E: ESameAddressesError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_SAME_ADDRESSES,
          E.Message);
      end;
      on E: EValidatorDidNotAnswerError do
      begin
        EndpointResponse.Code := HTTP_INTERNAL_ERROR;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_VALIDATOR_DID_NOT_ANSWER,
          'validator did not answer, try later');
      end;
      on E: ESmartNotExistsError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_SMART_NOT_EXISTS,
          'smart contract does not exists');
      end;
      on E: ENoInfoForThisSmartError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_NO_INFO_FOR_SMART,
          'this smartcontract does not have the requested information');
      end;
      on E: ENoInfoForThisAccountError do
      begin
        EndpointResponse.Code := HTTP_INTERNAL_ERROR;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_NO_INFO_FOR_ACCOUNT,
          'this account does not have the requested information');
      end;
      on E: ESocketError do
      begin
        EndpointResponse.Code := HTTP_INTERNAL_ERROR;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_NO_RESPONSE,
          'server did not respond, try later');
      end;
      on E: EInvalidSignError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_INVALID_SIGN,
          'signature not verified');
      end;
      on E: ERequestInProgressError do
      begin
        EndpointResponse.Code := HTTP_BAD_REQUEST;
        EndpointResponse.Response :=
          GetJSONErrorAsString(ERROR_REQUEST_IN_PROGRESS,
          'the previous transaction has not yet been processed');
      end;
      on E: EUnknownError do
      begin
        EndpointResponse.Code := HTTP_INTERNAL_ERROR;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_UNKNOWN,
          'unknown error with code ' + E.Message);
      end;
      on E: Exception do
      begin
        EndpointResponse.Code := HTTP_INTERNAL_ERROR;
        EndpointResponse.Response := GetJSONErrorAsString(ERROR_UNKNOWN,
          'unknown error with message:' + E.Message);
      end;
    end;
  finally
    AResponseInfo.ResponseNo := EndpointResponse.Code;
    AResponseInfo.ContentText := EndpointResponse.Response;
    Logs.DoLog(Format('<%s> [%d] %s', [EndpointResponse.ReqID,
      AResponseInfo.ResponseNo, AResponseInfo.ContentText]), ltOutgo);
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
//  FCommands.Add('/blockscount', FNodeEndpoints.BlocksCount);
//  FCommands.Add('/version', FNodeEndpoints.Version);
//  FCommands.Add('/user/registration', FMainEndpoints.DoReg);
//  FCommands.Add('/user/auth', FMainEndpoints.DoAuth);
//  FCommands.Add('/keys/new', FMainEndpoints.DoNewKeys);
//  FCommands.Add('/keys/recover', FMainEndpoints.DoRecoverKeys);
//  FCommands.Add('/keys/public/byuserid', FMainEndpoints.GetPublicKeyByAccID);
//  FCommands.Add('/keys/public/byskey', FMainEndpoints.GetPublicKeyBySessionKey);
  FTokenEndpoints := TTokenEndpoints.Create;
//  FCommands.Add('/coins/transfer', FTokenEndpoints.DoCoinTransfer);
//  FCommands.Add('/coins/transfer/fee', FTokenEndpoints.GetCoinTransferFee);
//  FCommands.Add('/coins/balances', FTokenEndpoints.GetCoinsBalances);
//  FCommands.Add('/coins/transfers', FTokenEndpoints.GetCoinsTransferHistory);
//  FCommands.Add('/coins/transfers/user',
//    FTokenEndpoints.GetCoinsTransferHistoryUser);
//  FCommands.Add('/tokens', FTokenEndpoints.Tokens);
//  FCommands.Add('/tokens/fee', FTokenEndpoints.GetNewTokenFee);
  FCommands.Add('/tokens/transfer', FTokenEndpoints.DoTokenTransfer);
  FCommands.Add('/tokens/stake', FTokenEndpoints.DoTokenStake);
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
  FTokenEndpoints.Free;
  FNodeEndpoints.Free;
  FCommands.Free;

  inherited;
end;

procedure THTTPServer.Start(APort: Word);
begin
  DefaultPort := APort;
  Active := True;
  Logs.DoLog('HTTP server started', ltNone);
end;

procedure THTTPServer.Stop;
begin
  Active := False;
  Logs.DoLog('HTTP server stoped', ltNone);
end;

end.
