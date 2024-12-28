unit Net.ClientConnection;

interface

uses
  App.Exceptions,
  App.Intf,
  App.Logs,
  Blockchain.Address,
  Blockchain.Data,
  BlockChain.DataCache,
  Blockchain.Reward,
  Blockchain.Txn,
  Blockchain.Validation,
  System.Classes,
  Crypto,
  System.Math,
  Net.CommandHandler,
  Net.Connection,
  Net.Data,
  Net.Socket,
  System.SyncObjs,
  System.SysUtils,
  System.Types;

type
  TClientConnection = class(TConnection)
    private
      FAddress: string;
      FPort: Word;
      FOnNeedChooseSync: TNotifyEvent;
      FIsForSync: Boolean;
      FServerIsAvailable: Boolean;

      procedure Reconnect;
      procedure DoDisconnect; override;
      procedure SetSyncFlag(AValue: Boolean);
      function GetFullAddress: string;
      function GetBlocksCountBytes<T>(const AFileName: string): TBytes;
      procedure BreakableSleep(ADuration: Integer);
      procedure ProcessCommand(const AResponse: TResponseData); override;
      procedure ReceiveCallBack(const ASyncResult: IAsyncResult); override;
      procedure BeginSyncChains;
      procedure SendRequest(const ACommandByte: Byte; const ABytes: TBytes;
        AToLog: Boolean = True); override;
    public
      constructor Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
        AOnDisconnected: TNotifyEvent; AOnNeedChooseSync: TNotifyEvent = nil);
      destructor Destroy; override;

      function Connect(AAddress: string; APort: Word): Boolean;
      function DoRequest(const ACommandByte: Byte;
        const AReqBytes: TBytes): TBytes; override;

      property Address: string read GetFullAddress;
      property IsForSync: Boolean read FIsForSync write SetSyncFlag;
      property IsAvailable: Boolean read FServerIsAvailable;
  end;

implementation

{ TClientConnection }

procedure TClientConnection.BeginSyncChains;
begin
  SendRequest(GetRewardsCommandCode, GetBlocksCountBytes<TReward>(TReward.Filename), False);
  SendRequest(GetTxnsCommandCode, GetBlocksCountBytes<TTxn>(TTxn.Filename), False);
  SendRequest(GetAddressesCommandCode, GetBlocksCountBytes<TAccount>(TAccount.Filename), False);
  SendRequest(GetValidationsCommandCode, GetBlocksCountBytes<TValidation>(TValidation.Filename), False);
end;

procedure TClientConnection.BreakableSleep(ADuration: Integer);
var
  SleepFor: Integer;
begin
  while not FIsShuttingDown and (ADuration > 0) do
  begin
    SleepFor := Min(250, ADuration);
    Dec(ADuration, SleepFor);
    Sleep(SleepFor);
  end;
end;

function TClientConnection.Connect(AAddress: string; APort: Word): Boolean;
begin
  try
    FSocket.Connect('', AAddress, '', APort);
  except
    try
      const Endpoint = TNetEndpoint.Create(TIPAddress.LookupName(AAddress), APort);
      FSocket.Connect(Endpoint);
    except
      Exit(False);
    end;
  end;

  BeginReceive;
  FAddress := AAddress;
  FPort := APort;
  FIsForSync := False;
  FServerIsAvailable := True;
  Result := True;
  FStopwatch.Start;
end;

constructor TClientConnection.Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
  AOnDisconnected: TNotifyEvent; AOnNeedChooseSync: TNotifyEvent);
begin
  inherited Create(ASocket, ACommandHandler, AOnDisconnected);

  FOnNeedChooseSync := AOnNeedChooseSync;
end;

destructor TClientConnection.Destroy;
begin

  inherited;
end;

procedure TClientConnection.DoDisconnect;
begin
  FConnectionChecked := False;
  if FIsShuttingDown then
    FOnDisconnected(Self)
  else begin
//    if FIsForSync then
//      FOnNeedChooseSync(Self);
    Reconnect;
    if FIsShuttingDown then
      FOnDisconnected(Self);
  end;
end;

function TClientConnection.DoRequest(const ACommandByte: Byte;
  const AReqBytes: TBytes): TBytes;
begin
  if not FIsShuttingDown and FServerIsAvailable then
    Result := inherited DoRequest(ACommandByte, AReqBytes);
end;

function TClientConnection.GetBlocksCountBytes<T>(
  const AFileName: string): TBytes;
begin
  const BlocksCount = TMemBlock<T>.RecordsCount(AFileName);
  Result := BytesOf(@BlocksCount, 8);
end;

function TClientConnection.GetFullAddress: string;
begin
  Result := Format('%s:%d', [FAddress, FPort]);
end;

procedure TClientConnection.ProcessCommand(const AResponse: TResponseData);
begin
//  if (Length(AResponse.Data) = 1) and (AResponse.Data[0] = ErrorCode) then
//  begin
//    Logs.DoLog(Format('<%s>[my][ID %d]: %d', [GetRemoteAddress,
//      AResponse.RequestData.ID, ErrorCode]), ltError);
//    exit;
//  end;

  case AResponse.RequestData.Code of
    GetRewardsCommandCode:
    begin
      TMemBlock<TReward>.ByteArrayToFile(TReward.Filename, AResponse.Data);
      Sleep(50);
      if not FIsShuttingDown and FIsForSync then
        SendRequest(GetRewardsCommandCode, GetBlocksCountBytes<TReward>(TReward.Filename), False);
    end;

    GetTxnsCommandCode:
    begin
      var FromID := TMemBlock<TTxn>.RecordsCount(TTxn.Filename);
      TMemBlock<TTxn>.ByteArrayToFile(TTxn.Filename, AResponse.Data);
      var i := 0;
      while i < Length(AResponse.Data) do
      begin
        const txn: TMemBlock<TTxn> = Copy(AResponse.Data, i, SizeOf(TTxn));
        DataCache.UpdateCache(txn, FromID + i div SizeOf(TTxn));
        Inc(i, SizeOf(TTxn));
      end;
      if Length(AResponse.Data) > 0 then
        UI.NotifyNewTETBlocks;
      Sleep(50);
      if not FIsShuttingDown and FIsForSync then
        SendRequest(GetTxnsCommandCode, GetBlocksCountBytes<TTxn>(TTxn.Filename), False);
    end;

    GetAddressesCommandCode:
    begin
      TMemBlock<TAccount>.ByteArrayToFile(TAccount.Filename, AResponse.Data);
      Sleep(50);
      if not FIsShuttingDown and FIsForSync then
        SendRequest(GetAddressesCommandCode, GetBlocksCountBytes<TAccount>(TAccount.Filename), False);
    end;

    GetValidationsCommandCode:
    begin
      TMemBlock<TValidation>.ByteArrayToFile(TValidation.Filename, AResponse.Data);
      Sleep(50);
      if not FIsShuttingDown and FIsForSync then
        SendRequest(GetValidationsCommandCode, GetBlocksCountBytes<TValidation>(TValidation.Filename), False);
    end;
  end;
end;

procedure TClientConnection.ReceiveCallBack(const ASyncResult: IAsyncResult);
var
  IncomData: TResponseData;
  LengthBytes: array[0..3] of Byte;
  Length: Integer absolute LengthBytes;
begin
  try
    IncomData.Data := FSocket.EndReceiveBytes(ASyncResult);
    if Assigned(IncomData.Data) then
    begin
      FSocket.Receive(IncomData.RequestData.Code, 1, [TSocketFlag.WAITALL]);
      case IncomData.RequestData.Code of
        PingCode:
          if not FIsShuttingDown then
          begin
            FConnectionChecked := True;
            FSocket.BeginReceive(ReceiveCallBack, -1, [TSocketFlag.PEEK]);
            if FIsForSync then
              BeginSyncChains
            else
              FSocket.Send([PingCode]);
            UI.DoMessage(Format('Connected to %s', [Address]));
          end;

        PongCode:
          begin
            FSocket.BeginReceive(ReceiveCallBack, -1, [TSocketFlag.PEEK]);
            if not (FIsForSync or FIsShuttingDown) and FServerIsAvailable then
            begin
              Sleep(50);
              FSocket.Send([PingCode]);
            end;
          end;

        ImShuttingDownCode:
          begin
            FServerIsAvailable := False;
            FSocket.BeginReceive(ReceiveCallBack, -1, [TSocketFlag.PEEK]);
          end;

        KeyAlreadyUsesErrorCode:
          begin
            UI.DoMessage(
              Format('The public key is already in use in an active session on %s archiver. Please use a different key',
              [GetFullAddress]));
            Stop;
          end

        else
          begin
            FSocket.Receive(IncomData.RequestData.ID, 8, [TSocketFlag.WAITALL]);
            FSocket.Receive(LengthBytes, 4, [TSocketFlag.WAITALL]);
            FSocket.Receive(IncomData.Data, Length, [TSocketFlag.WAITALL]);
            FSocket.BeginReceive(ReceiveCallBack, -1, [TSocketFlag.PEEK]);

            if IncomData.RequestData.Code in [ResponseCode, ResponseSyncCode] then
              WriteResponseData(IncomData, IncomData.RequestData.Code = ResponseCode)
            else
              AddIncomRequest(IncomData);
          end;
      end;
    end else
      raise ESocketError.Create('');
  except
    on E:ESocketError do
      DoDisconnect;
  end;
end;

procedure TClientConnection.Reconnect;
var
  i: Integer;
begin
  Disconnect;
  i := 0;
  UI.DoMessage(Format('Reconnecting to %s...', [Address]));
  while not FIsShuttingDown do
  begin
    if Connect(FAddress, FPort) then
      exit;

    if i = 9 then
      UI.DoMessage(Format('Can''t connect to %s (not responding)', [Address]));
    i := Min(i + 1, 9);
    BreakableSleep(1000 * Round(Power(2, i)));
  end;
end;

procedure TClientConnection.SendRequest(const ACommandByte: Byte;
  const ABytes: TBytes; AToLog: Boolean);
begin
  if FServerIsAvailable then
    inherited SendRequest(ACommandByte, ABytes, AToLog);
end;

procedure TClientConnection.SetSyncFlag(AValue: Boolean);
begin
  if (FIsForSync <> AValue) and FConnectionChecked then
    if AValue then
      BeginSyncChains
    else
      FSocket.Send([PingCode]);

  FIsForSync := AValue;
end;

end.
