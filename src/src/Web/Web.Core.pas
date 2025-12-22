unit Web.Core;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  App.Types,
  App.Logs,
  App.Intf,
  App.Exceptions,
  HTTP.Types,
  HTTP.Server,
  Web.Base,
  Web.Node,
  Web.Token,
  Web.Coin;

type
  TWebCore = class
  private
    FServer: THTTPServer;
    FNodeEndpoints: TNodeEndpoints;
    FCoinEndpoints: TCoinEndpoints;
    FTokenEndpoints: TTokenEndpoints;
    FEndpoints: TDictionary<string, TEndpointProc>;
    procedure DoLog(const S: string; Level: TLevel);
    procedure DoRequest(const Request: TRequest; var Response: TResponse);
    procedure DoException(E: Exception; var Response: TResponse);
    function RequestToEndpoint(const Method, Query: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start(Port: Word);
    procedure Stop;
  end;

implementation

{ TWebCore }

constructor TWebCore.Create;
begin

  FServer := THTTPServer.Create;
  FServer.OnLog := DoLog;
  FServer.OnRequest := DoRequest;
  FNodeEndpoints := TNodeEndpoints.Create;
  FCoinEndpoints := TCoinEndpoints.Create;
  FEndpoints := TDictionary<string, TEndpointProc>.Create(100);

  FEndpoints.Add(RequestToEndpoint('get','/net'), FNodeEndpoints.DoNetStats);
  FEndpoints.Add(RequestToEndpoint('get','/version'), FNodeEndpoints.Version);
  FEndpoints.Add(RequestToEndpoint('get','/keys/new'), FNodeEndpoints.DoNewKeys);
  FEndpoints.Add(RequestToEndpoint('post','/keys/recover'), FNodeEndpoints.DoRecoverKeys);
  FEndpoints.Add(RequestToEndpoint('get','/blockscount'), FNodeEndpoints.BlocksCount);

  FEndpoints.Add(RequestToEndpoint('get','/coins/transfer'), FCoinEndpoints.GetCoinTransferInfo);
  FEndpoints.Add(RequestToEndpoint('post','/coins/transfer'), FCoinEndpoints.DoCoinTransfer);
  FEndpoints.Add(RequestToEndpoint('post','/coins/stake'), FCoinEndpoints.DoCoinStake);
  FEndpoints.Add(RequestToEndpoint('get','/coins/stake'), FCoinEndpoints.GetCoinStake);
  FEndpoints.Add(RequestToEndpoint('post','/coins/unstake'), FCoinEndpoints.DoCoinUnstake);
  FEndpoints.Add(RequestToEndpoint('post','/coins/migrate'), FCoinEndpoints.DoMigrate);
  FEndpoints.Add(RequestToEndpoint('get','/coins/balance/byaddress'),FCoinEndpoints.GetCoinBalance);
  FEndpoints.Add(RequestToEndpoint('post','/coins/transfer/create-sign'), FCoinEndpoints.CreateSignedTx);
  FEndpoints.Add(RequestToEndpoint('post','/coins/transfer/sign'), FCoinEndpoints.DoCoinSignedTransfer);
  FEndpoints.Add(RequestToEndpoint('get','/coins/transfers'), FCoinEndpoints.GetCoinTransferHistory);
  FEndpoints.Add(RequestToEndpoint('get','/coins/transfers/user'), FCoinEndpoints.GetCoinTransferHistoryUser);
  FEndpoints.Add(RequestToEndpoint('get','/blocks'), FCoinEndpoints.GetBlockInfo);

  FEndpoints.Add(RequestToEndpoint('post','/token/mint'), FTokenEndpoints.DoTokenMint);
  FEndpoints.Add(RequestToEndpoint('post','/token/burn'), FTokenEndpoints.DoTokenBurn);
  FEndpoints.Add(RequestToEndpoint('post','/token/transfer'),FTokenEndpoints.DoTokenTransfer);
  FEndpoints.Add(RequestToEndpoint('get','/token/balance/byaddress'),FTokenEndpoints.GetTokenBalance);
  FEndpoints.Add(RequestToEndpoint('get','/token/info'),FTokenEndpoints.GetTokenInfo);
end;

destructor TWebCore.Destroy;
begin
  FServer.Free;
  FNodeEndpoints.Free;
  FCoinEndpoints.Free;
  FEndpoints.Free;
  inherited;
end;

procedure TWebCore.Start(Port: Word);
begin
  FServer.Port := Port;
  FServer.Start;
end;

procedure TWebCore.Stop;
begin
  FServer.Stop;
end;

procedure TWebCore.DoLog(const S: string; Level: TLevel);
begin
  Logs.DoLog(S, Level);
end;

function TWebCore.RequestToEndpoint(const Method, Query: string): string;
begin
  Result := (Method + ' ' + Query).ToLower;
end;

procedure TWebCore.DoRequest(const Request: TRequest; var Response: TResponse);
begin

  DoLog('HTTP Request: ' + Request.Source, INFO);

  Response.Header.Add('Access-Control-Allow-Origin', '*');
  Response.Header.Add('Access-Control-Allow-Methods', 'GET, POST');

  try

    if not (TAppState.Synchronized in AppCore.States) then
      raise EServiceUnavailable.Create('Not synchronized');

    var P: TEndpointProc;

    if not FEndpoints.TryGetValue(RequestToEndpoint(Request.Method, Request.Query), P) then
      raise ENotSupportedException.Create('Not supported');

    P(Request, Response);

  except on E: Exception do
    DoException(E, Response);
  end;

  DoLog('HTTP Response: ' + Response.ResultCode.ToString + ' ' + Response.ResultText, INFO);

end;

procedure TWebCore.DoException(E: Exception; var Response: TResponse);
begin

  DoLog(E.ClassName + ': ' + E.Message, ERROR);

  if E is EServiceUnavailable then
  begin
    Response.SetResult(HTTP_SERVICE_UNAVAILABLE, 'Service Unavailable');
    Response.SetJsonContent(GetJsonErrorAsBytes('SERVICE_UNAVAILABLE', E.Message));
  end else

  if E is ENotSupportedException then
  begin
    Response.SetResult(HTTP_BAD_REQUEST, 'Bad Request');
    Response.SetJsonContent(GetJsonErrorAsBytes('NOT_SUPPORTED', E.Message));
  end else

  if E is ENotFoundError then
  begin
    Response.SetResult(HTTP_NOT_FOUND, 'Not Found');
    Response.SetJsonContent(GetJsonErrorAsBytes('NOT_FOUND', E.Message));
  end else

  if E is ERequireException then
  begin
    Response.SetResult(HTTP_INTERNAL_ERROR, 'Internal Server Error');
    Response.SetJsonContent(GetJsonErrorAsBytes('ERROR_VALID', E.Message));
  end else

  if E is ERequestTimeout then
  begin
    Response.SetResult(HTTP_REQUEST_TIMEOUT, 'Request Timeout');
    Response.SetJsonContent(GetJsonErrorAsBytes('REQUEST_TIMEOUT', E.Message));
  end else

  begin
    Response.SetResult(HTTP_INTERNAL_ERROR, 'Internal Server Error');
    Response.SetJsonContent(GetJsonErrorAsBytes('INTERNAL_ERROR', E.Message));
  end;

end;

end.
