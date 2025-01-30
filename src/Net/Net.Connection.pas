unit Net.Connection;

interface

uses
  App.Exceptions,
  App.Logs,
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
  TConnection = class
    const
      DebugMultiplier = 5;
      ReceiveTimeout = 3000;
      CommandExecTimeout = 2000 * DebugMultiplier;
      ResponseWaitingTimeout = 5000 * DebugMultiplier;
      ShutDownTimeout = 2000 * DebugMultiplier;
    private
      FOutgoRequests: TThreadList<TOutgoRequestData>;
      FIncomRequestsCount: Integer;
      FCommandHandler: TCommandHandler;
      FRequestID: UInt64;
      FIncomEmpty: TEvent;
      FOutgoEmpty: TEvent;

      procedure SendResponse(const AReqID: UInt64; const ACommandCode: Byte;
        const ABytes: TBytes; ALogLvl: Byte; const AToLog: string);
      function GetResponse(const AReqID: UInt64): TBytes;
      function IsSocketConnected: Boolean;
    protected
      FSocket: TSocket;
      FConnectionChecked: Boolean;
      FIsShuttingDown: Boolean;
      FRemoteIsAvailable: Boolean;
      FStatus: Byte;
      FOnDisconnected: TNotifyEvent;

      procedure WaitForReceive(const ANeedTimeOut: Boolean = False); inline;
      procedure Disconnect; virtual;
      procedure DoDisconnect(const AErrorMsg: string = ''); virtual; abstract;
      procedure ReceiveCallBack(const ASyncResult: IAsyncResult); virtual; abstract;
      procedure SendRequest(const ACommandByte: Byte; const ABytes: TBytes;
        const AToLog: string = ''); virtual;
      procedure ProcessCommand(const AResponse: TResponseData); virtual; abstract;
      procedure AddIncomRequest(const ARequest: TResponseData);
      procedure WriteResponseData(const AResponse: TResponseData); virtual;
      procedure CheckForStop;
      function GetRemoteAddress: string; virtual; abstract;
    public
      constructor Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
        AOnDisconnected: TNotifyEvent);
      destructor Destroy; override;

      function DoRequest(const ACommandByte: Byte;
        const AReqBytes: TBytes): TBytes;
      procedure Stop;

      property isChecked:Boolean read FConnectionChecked;
      property IsConnected: Boolean read IsSocketConnected;
  end;

implementation

{ TConnection }

constructor TConnection.Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
  AOnDisconnected: TNotifyEvent);
begin
  FSocket := ASocket;
  FCommandHandler := ACommandHandler;
  FOnDisconnected := AOnDisconnected;
  FConnectionChecked := False;
  FIsShuttingDown := False;
  FRemoteIsAvailable := False;
  FStatus := 0;
  FOutgoRequests := TThreadList<TOutgoRequestData>.Create;
  FIncomRequestsCount := 0;
  FRequestID := 0;
end;

destructor TConnection.Destroy;
begin
  Disconnect;
  FOutgoRequests.Free;
  FSocket.Free;

  inherited;
end;

procedure TConnection.Disconnect;
begin
  if TSocketState.Connected in FSocket.State then
  begin
    if FStatus <> 0 then
    begin
      FSocket.Send([FStatus]);
      Sleep(50);
    end;

    {$IFDEF MSWINDOWS}
      FSocket.Close(True);
    {$ELSE IFDEF POSIX}
      FSocket.Close;
    {$ENDIF}

    FConnectionChecked := False;
    FOutgoRequests.Clear;
    FIncomRequestsCount := 0;
  end;
end;

function TConnection.DoRequest(const ACommandByte: Byte;
  const AReqBytes: TBytes): TBytes;
var
  DoneEvent: TEvent;
  Request: TOutgoRequestData;
begin
  if FIsShuttingDown or not FRemoteIsAvailable then
    // do logs
    exit;

  Request.RequestData.Code := ACommandByte;
  AtomicIncrement(FRequestID);
  Request.RequestData.ID := FRequestID;
  Logs.DoLog(Format('<%s>[my][%d ID %d]: %s', [GetRemoteAddress, ACommandByte,
    Request.RequestData.ID, 'AReqBytes']), CmnLvlLogs, ltOutgo);
  DoneEvent := TEvent.Create;
  try
    Request.DoneEvent := DoneEvent;
    FOutgoRequests.Add(Request);
    const Len = Length(AReqBytes);
    TMonitor.Enter(FSocket);
    try
      FSocket.Send([ACommandByte] + BytesOf(@Request.RequestData.ID, 8) +
        BytesOf(@Len, 4) + AReqBytes);
    finally
      TMonitor.Exit(FSocket);
    end;

    if DoneEvent.WaitFor(ResponseWaitingTimeout) = wrSignaled then
      Result := GetResponse(Request.RequestData.ID)
    else begin
      GetResponse(Request.RequestData.ID);
      raise ERequestTimeout.Create('');
    end;
  finally
    DoneEvent.Free;
    CheckForStop;
  end;
end;

procedure TConnection.SendRequest(const ACommandByte: Byte; const ABytes: TBytes;
  const AToLog: string = '');
var
  RequestData: TOutgoRequestData;
  LogLvl: Byte;
begin
  if FIsShuttingDown or not FRemoteIsAvailable then
    exit;

  RequestData.RequestData.Code := ACommandByte;
  AtomicIncrement(FRequestID);
  RequestData.RequestData.ID := FRequestID;
  RequestData.DoneEvent := nil;
  const Len = Length(ABytes);
  FOutgoRequests.Add(RequestData);

  TMonitor.Enter(Self);
  try
    FSocket.Send([ACommandByte] + BytesOf(@RequestData.RequestData.ID, 8) +
      BytesOf(@Len, 4) + ABytes);
  finally
    TMonitor.Exit(Self);
  end;

  if (ACommandByte in [GetTxnsCommandCode..GetRewardsCommandCode]) then
    LogLvl := NoneLvlLogs
  else if ACommandByte = InitConnectCode then
    LogLvl := AdvLvlLogs
  else
    LogLvl := CmnLvlLogs;

  if AToLog.IsEmpty then
    Logs.DoLog(Format('<%s>[%d ID %d]', [GetRemoteAddress, ACommandByte,
      RequestData.RequestData.ID]), LogLvl, ltOutgo)
  else
    Logs.DoLog(Format('<%s>[%d ID %d]: %s', [GetRemoteAddress, ACommandByte,
      RequestData.RequestData.ID, AToLog]), LogLvl, ltOutgo);
end;

procedure TConnection.SendResponse(const AReqID: UInt64; const ACommandCode: Byte;
  const ABytes: TBytes; ALogLvl: Byte; const AToLog: string);
begin
  try
    const Len = Length(ABytes);
    TMonitor.Enter(Self);
    try
      FSocket.Send([ResponseCode] + BytesOf(@AReqID, 8) + BytesOf(@Len, 4) + ABytes);
    finally
      AtomicDecrement(FIncomRequestsCount);
      TMonitor.Exit(Self);
    end;

    if ACommandCode in [GetTxnsCommandCode..GetRewardsCommandCode] then
      Logs.DoSyncLog(GetRemoteAddress, ACommandCode, ABytes, DbgLvlLogs, ltOutgo)
    else
      Logs.DoLog(Format('<%s>[ID %d]: %s', [GetRemoteAddress, AReqID, AToLog]),
        ALogLvl, ltOutgo);
  finally
    CheckForStop;
  end;
end;

procedure TConnection.Stop;
begin       
  FIncomEmpty := TEvent.Create;
  FIncomEmpty.ResetEvent;
  FOutgoEmpty := TEvent.Create;
  FOutgoEmpty.ResetEvent;      
      
  FIsShuttingDown := True;      
  FSocket.Send([ImShuttingDownCode]); 
  try
    CheckForStop;
    if (FIncomEmpty.WaitFor(ShutDownTimeout) <> wrSignaled) or
       (FOutgoEmpty.WaitFor(ShutDownTimeout) <> wrSignaled) then
      Logs.DoLog('timeout connection terminating', CmnLvlLogs, ltError)
  finally       
    FreeAndNil(FIncomEmpty);
    FreeAndNil(FOutgoEmpty);
    Disconnect;        
  end;
end;

procedure TConnection.AddIncomRequest(const ARequest: TResponseData);
var
  LogLvl: Byte;
  FutureObj: IFuture<TBytes>;
  ToLog: string;
begin
  if FIsShuttingDown then
  begin
    FSocket.Send([ImShuttingDownCode]);
    exit;
  end;

  if ARequest.RequestData.Code = InitConnectCode then
  begin
    LogLvl := AdvLvlLogs;
    ToLog := '[bytes for signing]';
  end else
  if (ARequest.RequestData.Code in [GetTxnsCommandCode..GetRewardsCommandCode]) then
    LogLvl := NoneLvlLogs
  else begin
    LogLvl := CmnLvlLogs;
    ToLog := 'ReqData';
  end;

  Logs.DoLog(Format('<%s>[%d ID:%d]: %s', [GetRemoteAddress,
    ARequest.RequestData.Code, ARequest.RequestData.ID, ToLog]), LogLvl);

  FutureObj := TTask.Future<TBytes>(function: TBytes
    begin
      Result := FCommandHandler.ProcessCommand(ARequest, Self);
    end);
  AtomicIncrement(FIncomRequestsCount);

  if FutureObj.Wait(CommandExecTimeout) then
  begin
    if ARequest.RequestData.Code = InitConnectCode then
      ToLog := '[signed bytes]'
    else
      ToLog := 'ReqData';

    SendResponse(ARequest.RequestData.ID, ARequest.RequestData.Code,
      FutureObj.Value, LogLvl, ToLog);
  end else
  begin
    ToLog := TEncoding.ANSI.GetString(FutureObj.Value);
    SendResponse(ARequest.RequestData.ID, ARequest.RequestData.Code,
      [ErrorCode], CmnLvlLogs, ToLog);
  end;
end;

procedure TConnection.WriteResponseData(const AResponse: TResponseData);
var
  InternalList: TList<TOutgoRequestData>;
  ToProcess: TResponseData;
  NeedProcess: Boolean;
  i: Integer;
begin
  NeedProcess := False;
  InternalList := FOutgoRequests.LockList;
  try
    for i := 0 to InternalList.Count - 1 do
    begin
      if InternalList.Items[i].RequestData.ID = AResponse.RequestData.ID then
      begin
        if (InternalList.Items[i].RequestData.Code in [GetTxnsCommandCode..GetRewardsCommandCode]) then
          Logs.DoSyncLog(GetRemoteAddress, InternalList.Items[i].RequestData.Code, AResponse.Data,
            DbgLvlLogs)
        else if InternalList.Items[i].RequestData.Code = InitConnectCode then
          Logs.DoLog(Format('<%s>[ID %d]: %s', [GetRemoteAddress,
            AResponse.RequestData.ID, '[signed bytes]']), AdvLvlLogs)
        else
          Logs.DoLog(Format('<%s>[ID %d]', [GetRemoteAddress,
            AResponse.RequestData.ID]), CmnLvlLogs);

        InternalList.List[i].Data := AResponse.Data;
        NeedProcess := not Assigned(InternalList.Items[i].DoneEvent);
        if not NeedProcess then
        begin
          WaitForReceive;
          InternalList.Items[i].DoneEvent.SetEvent;
        end else
        begin
          ToProcess.RequestData := InternalList.Items[i].RequestData;
          ToProcess.Data := InternalList.Items[i].Data;
          InternalList.Delete(i);
        end;
        break;
      end;
    end;
  finally
    FOutgoRequests.UnlockList;
    if NeedProcess then
    begin
      ProcessCommand(ToProcess);
      if FIsShuttingDown then
        Sleep(500);
      CheckForStop;
    end;
  end;
end;

function TConnection.GetResponse(const AReqID: UInt64): TBytes;
var
  InternalList: TList<TOutgoRequestData>;
  i: Integer;
begin
  InternalList := FOutgoRequests.LockList;
  try
    for i := 0 to InternalList.Count - 1 do
      if InternalList.Items[i].RequestData.ID = AReqID then
      begin
        Result := InternalList.Items[i].Data;

        InternalList.Delete(i);
        break;
      end;
  finally
    FOutgoRequests.UnlockList;
  end;
end;

function TConnection.IsSocketConnected: Boolean;
begin
  Result := TSocketState.Connected in FSocket.State;
end;

procedure TConnection.CheckForStop;
var
  InternalList: TList<TOutgoRequestData>;
begin
  if not (FIsShuttingDown) then
    exit;
  if not (Assigned(FIncomEmpty)) then
    exit;
  if not (Assigned(FOutgoEmpty)) then
    exit;

  if FIncomRequestsCount = 0 then
    FIncomEmpty.SetEvent;
    
  InternalList := FOutgoRequests.LockList;
  try
    if InternalList.IsEmpty then
      FOutgoEmpty.SetEvent;
  finally
    FOutgoRequests.UnlockList;
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

    FSocket.BeginReceive(ReceiveCallBack, -1, [TSocketFlag.PEEK]);
  end;
end;

end.
