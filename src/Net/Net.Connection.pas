unit Net.Connection;

interface

uses
  App.Logs,
  System.Classes,
  Diagnostics,
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
      DebugMultiplier = 1;
      ReceiveDataTimeout = 1500 * DebugMultiplier;
      ConnectTimeout = 1500 * DebugMultiplier;
      CommandExecTimeout = 1000 * DebugMultiplier;
      ResponseWaitingTimeout = 1500 * DebugMultiplier;
      ShutDownTimeout = 3000 * DebugMultiplier;
    private
      FOutgoRequests: TThreadList<TOutgoRequestData>;
      FIncomRequestsCount: Integer;
      FCommandHandler: TCommandHandler;

      procedure SendResponse(const AReqID: UInt64; const ABytes: TBytes;
        AToLog: Boolean = True);
      function GetResponse(const AReqID: UInt64): TBytes;
      function GetRemoteAddress: string;
    protected
      FSocket: TSocket;
      FConnectionChecked: Boolean;
      FIsShuttingDown: Boolean;
      FOnDisconnected: TNotifyEvent;
      FStopwatch: TStopwatch;

      procedure BeginReceive; inline;
      procedure Disconnect; virtual;
      procedure DoDisconnect; virtual; abstract;
      procedure ReceiveCallBack(const ASyncResult: IAsyncResult); virtual; abstract;
      procedure SendRequest(const ACommandByte: Byte; const ABytes: TBytes;
        AToLog: Boolean = True); virtual;
      procedure ProcessCommand(const AResponse: TResponseData); virtual; abstract;
      procedure AddIncomRequest(const ARequest: TResponseData);
      procedure WriteResponseData(const AResponse: TResponseData;
        AToLog: Boolean = True); virtual;
      function IsReadyToStop: Boolean;
    public
      constructor Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
        AOnDisconnected: TNotifyEvent);
      destructor Destroy; override;

      function DoRequest(const ACommandByte: Byte;
        const AReqBytes: TBytes): TBytes; virtual;
      procedure Stop; virtual;
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
  FSocket.ConnectTimeout := ConnectTimeout;
  FSocket.ReceiveTimeout := ReceiveDataTimeout;
  FOutgoRequests := TThreadList<TOutgoRequestData>.Create;
  FIncomRequestsCount := 0;
  FStopwatch := TStopwatch.Create;
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
    {$IFDEF MSWINDOWS}
      FSocket.Close(True);
    {$ELSE IFDEF LINUX}
      FSocket.Close;
    {$ENDIF}

    FConnectionChecked := False;
    FOutgoRequests.Clear;
    FIncomRequestsCount := 0;
    FStopwatch.Stop;
  end;
end;

function TConnection.DoRequest(const ACommandByte: Byte;
  const AReqBytes: TBytes): TBytes;
var
  DoneEvent: TEvent;
  Request: TOutgoRequestData;
begin
  Request.RequestData.Code := ACommandByte;
  Request.RequestData.ID := TThread.GetTickCount64;
  Logs.DoLog(Format('<%s>[my][%d ID %d]: %s', [GetRemoteAddress, ACommandByte,
    Request.RequestData.ID, 'AReqBytes']), ltOutgo);
  DoneEvent := TEvent.Create;
  try
    Request.DoneEvent := DoneEvent;
    FOutgoRequests.Add(Request);
    const Len = Length(AReqBytes);
    FSocket.Send([ACommandByte] + BytesOf(@Request.RequestData.ID, 8) +
      BytesOf(@Len, 4) + AReqBytes);

    if DoneEvent.WaitFor(ResponseWaitingTimeout) = wrSignaled then
      Result := GetResponse(Request.RequestData.ID)
    else begin
      GetResponse(Request.RequestData.ID);
      Result := TEncoding.ANSI.GetBytes('URKError -1');
    end;
  finally
    DoneEvent.Free;
  end;
end;

function TConnection.GetRemoteAddress: string;
begin
  Result := Format('%s:%d', [FSocket.RemoteEndpoint.Address.Address,
    FSocket.RemoteEndpoint.Port]);
end;

procedure TConnection.SendRequest(const ACommandByte: Byte; const ABytes: TBytes;
  AToLog: Boolean);
var
  RequestData: TOutgoRequestData;
begin
  RequestData.RequestData.Code := ACommandByte;
  RequestData.RequestData.ID := FStopwatch.ElapsedTicks;
  RequestData.DoneEvent := nil;
  const Len = Length(ABytes);
  FOutgoRequests.Add(RequestData);

  FSocket.Send([ACommandByte] + BytesOf(@RequestData.RequestData.ID, 8) +
    BytesOf(@Len, 4) + ABytes);

  if AToLog then
    Logs.DoLog(Format('<%s>[my][%d ID %d]: %s', [GetRemoteAddress, ACommandByte,
      RequestData.RequestData.ID, TEncoding.ANSI.GetString(ABytes)]), ltOutgo);
end;

procedure TConnection.SendResponse(const AReqID: UInt64; const ABytes: TBytes;
  AToLog: Boolean);
begin
  try
    const Len = Length(ABytes);
    if not AToLog then
      FSocket.Send([ResponseSyncCode] + BytesOf(@AReqID, 8) + BytesOf(@Len, 4) + ABytes)
    else
      FSocket.Send([ResponseCode] + BytesOf(@AReqID, 8) + BytesOf(@Len, 4) + ABytes);

    AtomicDecrement(FIncomRequestsCount);

    if AToLog then
      Logs.DoLog(Format('<%s>[ID %d]: %s', [GetRemoteAddress, AReqID,
        TEncoding.ANSI.GetString(ABytes)]), ltOutgo);
  finally
    if FIsShuttingDown and IsReadyToStop then
      DoDisconnect;
  end;
end;

procedure TConnection.Stop;
begin
  FIsShuttingDown := True;
end;

procedure TConnection.AddIncomRequest(const ARequest: TResponseData);
var
  FutureObj: IFuture<TBytes>;
begin
  const ToLog = not (ARequest.RequestData.Code in
    [GetTxnsCommandCode..GetRewardsCommandCode]);
  if ToLog then
    Logs.DoLog(Format('<%s>[%d ID:%d]: %s', [GetRemoteAddress,
      ARequest.RequestData.Code, ARequest.RequestData.ID,
      TEncoding.ANSI.GetString(ARequest.Data)]));

  FutureObj := TTask.Future<TBytes>(function: TBytes
    begin
      Result := FCommandHandler.ProcessCommand(ARequest, Self);
    end);
  AtomicIncrement(FincomRequestsCount);

  if FutureObj.Wait(CommandExecTimeout) then
    SendResponse(ARequest.RequestData.ID, FutureObj.Value, ToLog)
  else
    SendResponse(ARequest.RequestData.ID, [ErrorCode], ToLog);
end;

procedure TConnection.WriteResponseData(const AResponse: TResponseData;
  AToLog: Boolean = True);
var
  InternalList: TList<TOutgoRequestData>;
  ToProcess: TResponseData;
  NeedProcess: Boolean;
  i: Integer;
begin
  if AToLog then
    Logs.DoLog(Format('<%s>[my][ID %d]: %s', [GetRemoteAddress,
      AResponse.RequestData.ID, TEncoding.ANSI.GetString(AResponse.Data)]));

  NeedProcess := False;
  InternalList := FOutgoRequests.LockList;
  try
    for i := 0 to InternalList.Count - 1 do
    begin
      if InternalList.Items[i].RequestData.ID = AResponse.RequestData.ID then
      begin
        InternalList.List[i].Data := AResponse.Data;
        NeedProcess := not Assigned(InternalList.Items[i].DoneEvent);
        if not NeedProcess then
          InternalList.Items[i].DoneEvent.SetEvent
        else begin
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
      ProcessCommand(ToProcess);
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
    if FIsShuttingDown and IsReadyToStop then
      DoDisconnect;
  end;
end;

function TConnection.IsReadyToStop: Boolean;
var
  InternalList: TList<TOutgoRequestData>;
begin
  InternalList := FOutgoRequests.LockList;
  try
    Result := InternalList.IsEmpty and (FIncomRequestsCount = 0);
  finally
    FOutgoRequests.UnlockList;
  end;
end;

procedure TConnection.BeginReceive;
begin
  if TSocketState.Connected in FSocket.State then
    FSocket.BeginReceive(ReceiveCallBack, -1, [TSocketFlag.PEEK]);
end;

end.
