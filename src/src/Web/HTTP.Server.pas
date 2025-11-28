unit HTTP.Server;

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.DateUtils,
  System.Net.Socket,
  System.NetConsts,
  System.NetEncoding,
  HTTP.Types,
  Net.SocketA,
  App.Types;

type
  TValuePair = record
    Name: string;
    Value: string;
    constructor Create(const Name, Value: string);
  end;

  TValuePairs = TArray<TValuePair>;

  TValuePairsHelper = record helper for TValuePairs
    procedure Add(const Name, Value: string);
    procedure Assign(Strings: TStrings);
    function ValueOf(const Name: string): string;
    function ToString: string;
    function ContentType: string;
  end;

  TRequest = record
    Source: string;
    Method: string;
    Protocol: string;
    Query: string;
    Params: TValuePairs;
    Header: TValuePairs;
    Content: TBytes;
    procedure Assign(const S: string);
    function &Is(const Method, Query, ContentType: string): Boolean;
  end;

  TResponse = record
    Protocol: string;
    ResultCode: Word;
    ResultText: string;
    Header: TValuePairs;
    Content: TBytes;
    procedure ToDefault;
    procedure SetResult(const Code: Word; const Text: string);
    procedure SetContent(const ContentType: string; const Content: TBytes);
    procedure SetJsonContent(const Content: TBytes);
    function ToBytes: TBytes;
  end;

  TOnRequestEvent = procedure(const Request: TRequest; var Response: TResponse) of object;

  THTTPStream = record
  private
    FCompleted: Boolean;
    Data: TBytes;
    FDataType: (Header, Body);
  public
    Request: TRequest;
    procedure Write(const Bytes: TBytes);
    property Completed: Boolean read FCompleted;
  end;

  THTTPHandler = class
  private
    FClient: TServerConnection;
    FHTTPStream: THTTPStream;
    FOnLog: TLogEvent;
    FOnRequest: TOnRequestEvent;
    procedure DoReceive(Client: TConnection; const Bytes: TBytes);
    procedure DoRequest(const Request: TRequest; var Response: TResponse);
    procedure DoLog(const S: string; Level: TLevel);
  public
    constructor Create(Client: TServerConnection);
    destructor Destroy; override;
    property Client: TServerConnection read FClient;
    property OnLog: TLogEvent read FOnLog write FOnLog;
    property OnRequest: TOnRequestEvent read FOnRequest write FOnRequest;
  end;

  THTTPServer = class
  private
    FServer: TSocketServer;
    FHandlers: TArray<THTTPHandler>;
    FOnLog: TLogEvent;
    FOnRequest: TOnRequestEvent;
    procedure DoAccept(Socket: TSocket);
    procedure DoDisconnect(Client: TConnection);
    function GetPort: Word;
    procedure SetPort(const Value: Word);
  protected
    procedure DoLog(const S: string; Level: TLevel); virtual;
    procedure DoRequest(const Request: TRequest; var Response: TResponse); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    property Port: Word read GetPort write SetPort;
    property OnLog: TLogEvent read FOnLog write FOnLog;
    property OnRequest: TOnRequestEvent read FOnRequest write FOnRequest;
  end;

implementation

const
  CRLF = #13#10;

{ THeaderPair }

constructor TValuePair.Create(const Name, Value: string);
begin
  Self.Name := Name.Trim;
  Self.Value := Value.Trim;
end;

{ THeader }

procedure TValuePairsHelper.Add(const Name, Value: string);
begin
  Self := Self + [TValuePair.Create(Name, Value)];
end;

procedure TValuePairsHelper.Assign(Strings: TStrings);
begin
  for var S in Strings do begin
    var Index := S.IndexOf(Strings.NameValueSeparator);
    if Index <> -1 then
      Self := Self + [TValuePair.Create(S.Substring(0, Index), S.Substring(Index + 1))];
  end;
end;

function TValuePairsHelper.ToString: string;
begin
  Result :='';
  for var Pair in Self do
    Result := Result + Pair.Name + ': ' + Pair.Value + CRLF;
end;

function TValuePairsHelper.ValueOf(const Name: string): string;
begin
  Result := '';
  for var Pair in Self do
    if SameText(Pair.Name, Name) then Exit(Pair.Value);
end;

function TValuePairsHelper.ContentType: string;
begin
  Result := ValueOf(SContentType);
end;

{ TRequest }

function TRequest.&Is(const Method, Query, ContentType: string): Boolean;
begin
  Result := SameText(Self.Method, Method) and SameText(Self.Query, Query) and
    SameText(Header.ContentType, ContentType);
end;

procedure TRequest.Assign(const S: string);
begin
  var Strings := TStringList.Create;
  AddRelease(Strings);
  Strings.NameValueSeparator := ':';
  Strings.Text := S;
  Source := TNetEncoding.URL.Decode(Strings[0]);
  Strings.Delete(0);
  Header.Assign(Strings);
  var Values := Source.Split([' ']);
  Method := Values[0];
  Protocol := Values[2];
  Source := Method + ' ' + Values[1];
  Values := Values[1].Split(['?']);
  Query := Values[0];
  if Length(Values) > 1 then begin
    Strings.NameValueSeparator := '=';
    Strings.LineBreak := '&';
    Strings.Text := Values[1];
    Params.Assign(Strings);
  end;
end;

{ TResponse }

function DateToHttp(Date: TDateTime): string;
begin
  Result := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss "GMT"',
    TTimeZone.Local.ToUniversalTime(Date), TFormatSettings.Create('en-US'));
end;

procedure TResponse.ToDefault;
begin
  Protocol := 'HTTP/1.1';
  SetResult(200, 'OK');
  Header.Add('Server', 'nginx');
  Header.Add('Date', DateToHttp(Now));
end;

procedure TResponse.SetResult(const Code: Word; const Text: string);
begin
  ResultCode := Code;
  ResultText := Text;
end;

procedure TResponse.SetContent(const ContentType: string; const Content: TBytes);
begin
  Header.Add(SContentType, ContentType);
  Self.Content := Content;
end;

procedure TResponse.SetJsonContent(const Content: TBytes);
begin
  SetContent(CONTENTTYPE_APPLICATION_JSON, Content);
end;

function TResponse.ToBytes: TBytes;
begin
  Result := TEncoding.ANSI.GetBytes(
    Protocol + ' ' + ResultCode.ToString + ' ' + ResultText + CRLF +
    Header.ToString + CRLF) + Content;
end;

{ THTTPStream }

procedure THTTPStream.Write(const Bytes: TBytes);
const
  EndHeader: TBytes = [13, 10, 13, 10];
begin
  FCompleted := False;
  Data := Data + Bytes;
  var Offset := Integer(0);

  while (FDataType = Header) and (Offset < Length(Data) - Length(EndHeader) + 1) do
    if CompareMem(@Data[Offset], @EndHeader[0], Length(EndHeader)) then begin
      Request := Default(TRequest);
      Request.Assign(TEncoding.ANSI.GetString(Data, 0, Offset));
      Delete(Data, 0, Offset + Length(EndHeader));
      FDataType := Body;
    end
    else
      Inc(Offset);

  if FDataType = Body then begin
    var ContentLength := StrToIntDef(Request.Header.ValueOf(SContentLength), 0);
    FCompleted := Length(Data) >= ContentLength;
    if not FCompleted then Exit;
    Request.Content := Copy(Data, 0, ContentLength);
    Delete(Data, 0, ContentLength);
    FDataType := Header;
  end;

end;

{ THTTPHandler }

constructor THTTPHandler.Create(Client: TServerConnection);
begin
  FHTTPStream := Default(THTTPStream);
  FClient := Client;
  FClient.OnReceive := DoReceive;
  FClient.OnLog := DoLog;
end;

destructor THTTPHandler.Destroy;
begin
  Client.OnDisconnect := nil;
  Client.Free;
  inherited;
end;

procedure THTTPHandler.DoLog(const S: string; Level: TLevel);
begin
  if Assigned(FOnLog) then FOnLog(S, Level);
end;

procedure THTTPHandler.DoReceive(Client: TConnection; const Bytes: TBytes);
begin
  FHTTPStream.Write(Bytes);

  if FHTTPStream.Completed then begin
    var Response: TResponse;
    Response.ToDefault;
    DoRequest(FHTTPStream.Request, Response);
    Response.Header.Add(SContentLength, Length(Response.Content).ToString);
    Client.Send(Response.ToBytes);
  end;
end;

procedure THTTPHandler.DoRequest(const Request: TRequest; var Response: TResponse);
begin
  if Assigned(FOnRequest) then FOnRequest(Request, Response);
end;

{ THTTPServer }

constructor THTTPServer.Create;
begin
  FServer := TSocketServer.Create;
  FServer.Name := 'HTTP Server';
  FServer.OnAccept := DoAccept;
  FServer.OnLog := DoLog;
end;

destructor THTTPServer.Destroy;
begin
  Stop;
  FServer.Free;
  inherited;
end;

procedure THTTPServer.DoAccept(Socket: TSocket);
begin
  var Client := TServerConnection.Accept(Socket);
  Client.Name := 'HTTP ' + Client.Name;
  Client.OnDisconnect := DoDisconnect;
  var Handler := THTTPHandler.Create(Client);
  Handler.OnRequest := DoRequest;
  Lock(Self);
  begin
    FHandlers := FHandlers + [Handler];
  end;
  Client.BeginReceive;
end;

function THTTPServer.GetPort: Word;
begin
  Result := FServer.Port;
end;

procedure THTTPServer.SetPort(const Value: Word);
begin
  FServer.Port := Value;
end;

procedure THTTPServer.Start;
begin
  FServer.Start;
end;

procedure THTTPServer.Stop;
begin
  FServer.Stop;
  Lock(Self);
  for var Handler in FHandlers do Handler.Free;
  FHandlers := nil;
end;

procedure THTTPServer.DoDisconnect(Client: TConnection);
begin
  Lock(Self);
  for var I := 0 to High(FHandlers) do
    if FHandlers[I].Client = Client then begin
      var Handler := FHandlers[I];
      Delete(FHandlers, I, 1);
      Handler.Free;
      Break;
    end;
end;

procedure THTTPServer.DoLog(const S: string; Level: TLevel);
begin
  if Assigned(FOnLog) then FOnLog(S, Level);
end;

procedure THTTPServer.DoRequest(const Request: TRequest; var Response: TResponse);
begin
  if Assigned(FOnRequest) then FOnRequest(Request, Response);
end;

end.
