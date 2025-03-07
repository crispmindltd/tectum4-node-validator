unit Net.Connection;

interface

uses
  App.Exceptions,
  App.Logs,
  App.Types,
  Crypto,
  DateUtils,
  System.Classes,
  Generics.Collections,
  Net.CommandHandler,
  Net.Data,
  Net.Socket,
  System.Types,
  System.SyncObjs,
  System.SysUtils,
  System.Threading;

type
  TConnection = class abstract
    const
      DebugMultiplier = 2;
      ReceiveTimeout = 1000 * DebugMultiplier;
      ResponseWaitingTimeout = 1000 * DebugMultiplier;
      ShutDownTimeout = 1200 * DebugMultiplier;
    private
      FOutgoRequests: TDictionary<UInt64, TOutgoRequestData>;
      FIncomRequestsCount: Integer;
      FCommandHandler: TCommandHandler;
      FOutgoReqListLock: TCriticalSection;
      FReadyToStopEvent: TEvent;
      FRequestID: UInt64;
      FBufferBytes: TBytes;
      FLeftToReceive: Integer;

      procedure SendResponse(const AReqID: UInt64; const ACommandCode: Byte;
        const ABytes: TBytes; ALogLvl: Byte);
      function GetResponse(const AReqID: UInt64): TBytes;
      function IsSocketConnected: Boolean;
    protected
      FSocket: TSocket;
      FIsShuttingDown: Boolean;
      FIsChecked: Boolean;
      FStatus: Byte;
      FDiscMsg: string;
      FOnDisconnected: TNotifyEvent;

      procedure WaitForReceive(const ANeedTimeOut: Boolean = False); inline;
      procedure ReceiveCallBack(const ASyncResult: IAsyncResult);
      procedure SendRequest(const ACommandByte: Byte; const AReqBytes: TBytes);
      procedure ProcessIncomRequest(const ARequest: TResponseData);
      procedure WriteResponseData(AResponse: TResponseData);
      procedure CheckForStop;
      procedure Disconnect;

      procedure DoDisconnect(const AReason: string = ''); virtual;
      function GetRemoteAddress: string; virtual; abstract;
      procedure ProcessCommand(const AIncomData: TResponseData); virtual; abstract;
      procedure ProcessResponse(const AResponse: TResponseData); virtual; abstract;
      function GetDisconnectMessage: string; virtual; abstract;
    public
      constructor Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
        AOnDisconnected: TNotifyEvent);
      destructor Destroy; override;

      function DoRequest(const ACommandByte: Byte;
        const AReqBytes: TBytes): TBytes;
      procedure Stop;

      property IsConnected: Boolean read IsSocketConnected;
      property IsChecked: Boolean read FIsChecked;
  end;

implementation

uses
 App.Intf;

{ TConnection }

constructor TConnection.Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
  AOnDisconnected: TNotifyEvent);
begin
  FSocket := ASocket;
  FCommandHandler := ACommandHandler;
  FOnDisconnected := AOnDisconnected;
  FIsShuttingDown := False;
  FOutgoReqListLock := TCriticalSection.Create;
  FReadyToStopEvent := TEvent.Create;
  FReadyToStopEvent.ResetEvent;
  FDiscMsg := '';
  FStatus := 0;
  FOutgoRequests := TDictionary<UInt64, TOutgoRequestData>.Create(10);
  FIncomRequestsCount := 0;
  FRequestID := 0;
  FBufferBytes := [];
  FLeftToReceive := -1;
end;

destructor TConnection.Destroy;
begin
  Disconnect;
  FOutgoRequests.Free;
  FSocket.Free;
  FReadyToStopEvent.Free;
  FOutgoReqListLock.Free;

  inherited;
end;

procedure TConnection.Disconnect;
begin
  if IsSocketConnected then
  begin
    if FStatus <> 0 then
    begin
      SendRequest(FStatus, []);
      Sleep(100);
    end;

    FOutgoReqListLock.Enter;
    try
      FOutgoRequests.Clear;
    finally
      FOutgoReqListLock.Leave;
    end;

    FIncomRequestsCount := 0;
    FIsChecked := False;
    FStatus := 0;
    FDiscMsg := '';
    FBufferBytes := [];
    FLeftToReceive := -1;

    Logs.DoLog(GetDisconnectMessage, CmnLvlLogs, ltNone);

    {$IFDEF MSWINDOWS}
      FSocket.Close(True);
    {$ELSE IFDEF POSIX}
      FSocket.Close;
    {$ENDIF}
  end;
end;

procedure TConnection.DoDisconnect(const AReason: string);
begin
  if not AReason.IsEmpty then
    FDiscMsg := AReason;
end;

function TConnection.DoRequest(const ACommandByte: Byte;
  const AReqBytes: TBytes): TBytes;
var
  RequestData: TOutgoRequestData;
  NewRequestID: UInt64;
  DoneEvent: TEvent;
begin
  if FIsShuttingDown then
    exit;

  DoneEvent := TEvent.Create;
  try
    TMonitor.Enter(FSocket);
    try
      RequestData.Code := ACommandByte;
      AtomicIncrement(FRequestID);
      NewRequestID := FRequestID;
      Logs.DoLog(Format('<%s>[my][%d ID %d]: %s', [GetRemoteAddress, ACommandByte,
        NewRequestID, BytesToHex(AReqBytes)]), CmnLvlLogs, ltOutgo);
      RequestData.DoneEvent := DoneEvent;

      FOutgoReqListLock.Enter;
      try
        FOutgoRequests.Add(NewRequestID, RequestData);
      finally
        FOutgoReqListLock.Leave;
      end;

      const Len = Length(AReqBytes) + 9;
      FSocket.Send(BytesOf(@Len, 4) + BytesOf(@NewRequestID, 8) +
        [ACommandByte] + AReqBytes);
    finally
      TMonitor.Exit(FSocket);
    end;

    Logs.DoLog(GetRemoteAddress, ACommandByte, NewRequestID, AReqBytes, True,
      ltOutgo);

    if DoneEvent.WaitFor(ResponseWaitingTimeout) = wrSignaled then
      Result := GetResponse(NewRequestID)
    else begin
      GetResponse(NewRequestID);
      raise ERequestTimeout.Create('');
    end;
  finally
    DoneEvent.Free;
  end;
end;

procedure TConnection.SendRequest(const ACommandByte: Byte; const AReqBytes: TBytes);
var
  RequestData: TOutgoRequestData;
  NewRequestID: UInt64;
  LogLvl: Byte;
begin
  TMonitor.Enter(FSocket);
  try
    RequestData.Code := ACommandByte;
    AtomicIncrement(FRequestID);
    NewRequestID := FRequestID;
    RequestData.DoneEvent := nil;

    if not ((ACommandByte in NoAnswerNeedCodes) or FIsShuttingDown) then
    begin
      FOutgoReqListLock.Enter;
      try
        FOutgoRequests.Add(NewRequestID, RequestData);
      finally
        FOutgoReqListLock.Leave;
      end;
    end;

    const Len = Length(AReqBytes) + 9;
    FSocket.Send(BytesOf(@Len, 4) + BytesOf(@NewRequestID, 8) +
      [ACommandByte] + AReqBytes);
  finally
    TMonitor.Exit(FSocket);
  end;

  Logs.DoLog(GetRemoteAddress, ACommandByte, NewRequestID, AReqBytes, True,
    ltOutgo);
end;

procedure TConnection.SendResponse(const AReqID: UInt64; const ACommandCode: Byte;
  const ABytes: TBytes; ALogLvl: Byte);
begin
  TMonitor.Enter(FSocket);
  try
    const Len = Length(ABytes) + 9;
    FSocket.Send(BytesOf(@Len, 4) + BytesOf(@AReqID, 8) + [ResponseCode] + ABytes);
  finally
    TMonitor.Exit(FSocket);
  end;

  Logs.DoLog(GetRemoteAddress, ACommandCode, AReqID, ABytes, False, ltOutgo);
end;

procedure TConnection.Stop;
begin
  FIsShuttingDown := True;
  try
    CheckForStop;
    if FReadyToStopEvent.WaitFor(ShutDownTimeout) <> wrSignaled then
      Logs.DoLog('timeout connection terminating', CmnLvlLogs, ltError);
  finally
    Sleep(500);
    Disconnect;
  end;
end;

procedure TConnection.ProcessIncomRequest(const ARequest: TResponseData);
var
  LogLvl: Byte;
begin
  if FIsShuttingDown then
    exit;

  Logs.DoLog(GetRemoteAddress, ARequest.Code, ARequest.ID, ARequest.Data,
    False, ltIncom);

  AtomicIncrement(FIncomRequestsCount);
  try
    if (ARequest.Code in NoAnswerNeedCodes) and (ARequest.Code <> CheckVersionCommandCode) then
      ProcessCommand(ARequest)
    else begin
      const ResBytes = FCommandHandler.ProcessCommand(ARequest, Self);

      if ARequest.Code <> CheckVersionCommandCode then
        SendResponse(ARequest.ID, ARequest.Code, ResBytes, LogLvl);
    end;
  finally
    AtomicDecrement(FIncomRequestsCount);
  end;
end;

procedure TConnection.WriteResponseData(AResponse: TResponseData);
var
  ReqData: TOutgoRequestData;
  Found, NeedProcess: Boolean;
begin
  FOutgoReqListLock.Enter;
  try
    Found := FOutgoRequests.TryGetValue(AResponse.ID, ReqData);
    if Found then
    begin
      Logs.DoLog(GetRemoteAddress, ReqData.Code, AResponse.ID,
        AResponse.Data, True, ltIncom);

      ReqData.Data := AResponse.Data;
      NeedProcess := not Assigned(ReqData.DoneEvent);
      if not NeedProcess then
      begin
        FOutgoRequests[AResponse.ID] := ReqData;
        ReqData.DoneEvent.SetEvent;
      end else
      begin
        FOutgoRequests.Remove(AResponse.ID);
        AResponse.Code := ReqData.Code;
      end;
    end;
  finally
    FOutgoReqListLock.Leave;

    if Found and NeedProcess then
      ProcessResponse(AResponse);
  end;
end;

function TConnection.GetResponse(const AReqID: UInt64): TBytes;
var
  ReqData: TOutgoRequestData;
begin
  FOutgoReqListLock.Enter;
  try
    if FOutgoRequests.TryGetValue(AReqID, ReqData) then
    begin
      Result := ReqData.Data;
      FOutgoRequests.Remove(AReqID);
    end else
      Result := [];
  finally
    FOutgoReqListLock.Leave;
  end;
end;

function TConnection.IsSocketConnected: Boolean;
begin
  Result := TSocketState.Connected in FSocket.State;
end;

procedure TConnection.ReceiveCallBack(const ASyncResult: IAsyncResult);
var
  DataToProcess: TResponseData;
  ToProcess: TArray<TResponseData>;
begin
  try
    const IncomBytes = FSocket.EndReceiveBytes(ASyncResult);

    if Assigned(IncomBytes) then
    begin
      WaitForReceive;

      TMonitor.Enter(Self);
      try
        ToProcess := [];
        FBufferBytes := FBufferBytes + IncomBytes;
        while Length(FBufferBytes) >= 4 do
        begin
          FLeftToReceive := PInteger(@FBufferBytes[0])^;
          if Length(FBufferBytes) - 4 >= FLeftToReceive then
          begin
            DataToProcess.ID := PUInt64(@FBufferBytes[4])^;
            DataToProcess.Code := FBufferBytes[12];
            DataToProcess.Data := Copy(FBufferBytes, 13, FLeftToReceive - 9);
            FBufferBytes := Copy(FBufferBytes, FLeftToReceive + 4, Length(FBufferBytes));
            ToProcess := ToProcess + [DataToProcess];
          end else
            break;
        end;
      finally
        TMonitor.Exit(Self);
      end;

      for DataToProcess in ToProcess do
      begin
        if DataToProcess.Code = ResponseCode then
          WriteResponseData(DataToProcess)
        else
          ProcessIncomRequest(DataToProcess);
      end;

      CheckForStop;
    end else
      raise EConnectionClosed.Create('');
  except
    on E:EConnectionClosed do
      DoDisconnect(E.Message);
    on E:ESocketError do
      DoDisconnect;
    on E:Exception do
      DoDisconnect('ReceiveCallBack disconnect: ' + E.Message);
  end;
end;

procedure TConnection.CheckForStop;
begin
  if FIsShuttingDown and FOutgoReqListLock.TryEnter then
  try
    if FOutgoRequests.IsEmpty and (FIncomRequestsCount = 0) then
      FReadyToStopEvent.SetEvent;
  finally
    FOutgoReqListLock.Leave;
  end;
end;

procedure TConnection.WaitForReceive(const ANeedTimeout: Boolean);
begin
  if IsSocketConnected then
  begin
    if not ANeedTimeout then
      FSocket.ReceiveTimeout := -1
    else
      FSocket.ReceiveTimeout := ReceiveTimeout;

    FSocket.BeginReceive(ReceiveCallBack, -1);
  end;
end;

end.
