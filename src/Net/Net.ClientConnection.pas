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
      FOnConnectionChecked: TNotifyEvent;
      FOnConnectionLost: TNotifyEvent;
      FIsForSync: Boolean;
      FIsConnecting: Boolean;

      procedure Disconnect; override;
      procedure Reconnect;
      procedure DoDisconnect(const AReason: string = ''); override;
      procedure SetSyncFlag(AValue: Boolean);
      function GetRemoteAddress: string; override;
      function GetBlocksCountBytes<T>(const AFileName: string): TBytes;
      procedure BreakableSleep(ADuration: Integer);
      procedure ProcessCommand(const AResponse: TResponseData); override;
      procedure ReceiveCallBack(const ASyncResult: IAsyncResult); override;
      procedure BeginSyncChains;
    public
      constructor Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
        AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TNotifyEvent;
        AOnConnectionLost: TNotifyEvent);
      destructor Destroy; override;

      procedure Connect(AAddress: string; APort: Word; AIsInitConnect: Boolean = True);

      property Address: string read GetRemoteAddress;
      property IsForSync: Boolean read FIsForSync write SetSyncFlag;
      property IsChecked: Boolean read FConnectionChecked;
      property IsConnecting: Boolean read FIsConnecting;
  end;

implementation

{ TClientConnection }

procedure TClientConnection.BeginSyncChains;
begin
  SendRequest(GetRewardsCommandCode, GetBlocksCountBytes<TReward>(TReward.Filename));
  SendRequest(GetTxnsCommandCode, GetBlocksCountBytes<TTxn>(TTxn.Filename));
  SendRequest(GetAddressesCommandCode, GetBlocksCountBytes<TAccount>(TAccount.Filename));
  SendRequest(GetValidationsCommandCode, GetBlocksCountBytes<TValidation>(TValidation.Filename));
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

procedure TClientConnection.Connect(AAddress: string; APort: Word; AIsInitConnect: Boolean);
var
  Success: Boolean;
  ConTryingCnt: Integer;
begin
  FAddress := AAddress;
  FPort := APort;
  FIsConnecting := True;
  ConTryingCnt := 0;
  repeat
    Success := True;
    try
      FSocket.Connect('', AAddress, '', APort);
    except
      try
        const Endpoint = TNetEndpoint.Create(TIPAddress.LookupName(AAddress), APort);
        FSocket.Connect(Endpoint);
      except
        Success := False;
        if (ConTryingCnt = 0) and AIsInitConnect then
          Logs.DoLog(Format('%s is not responding. Try reconnect...', [Address]),
            CmnLvlLogs, ltNone)
        else if ConTryingCnt = 9 then
          Logs.DoLog(Format('Can''t connect to %s (not responding)', [Address]),
            CmnLvlLogs, ltNone);

        ConTryingCnt := Min(ConTryingCnt + 1, 9);
        BreakableSleep(1000 * Round(Power(2, ConTryingCnt)));
      end;
    end;

    if FIsShuttingDown then
      exit;
  until Success;

  Logs.DoLog(Format('Connection established to %s', [Address]), CmnLvlLogs, ltNone);
  FIsConnecting := False;
  FIsShuttingDown := False;
  FRemoteIsAvailable := True;
  WaitForReceive;
end;

constructor TClientConnection.Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
  AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TNotifyEvent;
  AOnConnectionLost: TNotifyEvent);
begin
  inherited Create(ASocket, ACommandHandler, AOnDisconnected);

  FOnConnectionChecked := AOnConnectionChecked;
  FOnConnectionLost := AOnConnectionLost;
  FIsConnecting := False;
  FIsForSync := False;
end;

destructor TClientConnection.Destroy;
begin

  inherited;
end;

procedure TClientConnection.Disconnect;
begin
//  FOnDisconnected(Self);

  inherited;
end;

procedure TClientConnection.DoDisconnect(const AReason: string = '');
var
  LogStr: string;
begin
  LogStr := Format('Disconnected from %s', [Address]);
  if not AReason.IsEmpty then
    LogStr := Format('%s: %s', [LogStr, AReason]);

//  if Assigned(Logs) then
//  begin
    Logs.DoLog(LogStr, CmnLvlLogs, ltNone);

    FConnectionChecked := False;
    if FIsShuttingDown then
      FOnDisconnected(Self)
    else begin
      FIsConnecting := True;
      FOnConnectionLost(Self);
      Reconnect;
    end;
//  end;
end;

function TClientConnection.GetBlocksCountBytes<T>(
  const AFileName: string): TBytes;
begin
  const BlocksCount = TMemBlock<T>.RecordsCount(AFileName);
  Result := BytesOf(@BlocksCount, 8);
end;

function TClientConnection.GetRemoteAddress: string;
begin
  Result := Format('%s:%d', [FAddress, FPort]);
end;

procedure TClientConnection.ProcessCommand(const AResponse: TResponseData);
begin
  WaitForReceive;
  case AResponse.RequestData.Code of
    GetRewardsCommandCode:
    begin
      TMemBlock<TReward>.ByteArrayToFile(TReward.Filename, AResponse.Data);
      //todo: update DataCache/
      BreakableSleep(200);
      if FIsForSync then
        SendRequest(GetRewardsCommandCode, GetBlocksCountBytes<TReward>(TReward.Filename));
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
      BreakableSleep(200);
      if FIsForSync then
        SendRequest(GetTxnsCommandCode, GetBlocksCountBytes<TTxn>(TTxn.Filename));
    end;

    GetAddressesCommandCode:
    begin
      TMemBlock<TAccount>.ByteArrayToFile(TAccount.Filename, AResponse.Data);
      BreakableSleep(200);
      if FIsForSync then
        SendRequest(GetAddressesCommandCode, GetBlocksCountBytes<TAccount>(TAccount.Filename));
    end;

    GetValidationsCommandCode:
    begin
      TMemBlock<TValidation>.ByteArrayToFile(TValidation.Filename, AResponse.Data);
      BreakableSleep(200);
      if FIsForSync then
        SendRequest(GetValidationsCommandCode, GetBlocksCountBytes<TValidation>(TValidation.Filename));
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

      if not (IncomData.RequestData.Code in CommandsCodes) then
      begin
        FIsShuttingDown := True;
        FStatus := UnknownCommandErrorCode;
        raise EConnectionClosed.CreateFmt('unknown command(code %d) received',
          [IncomData.RequestData.Code]);
      end;

      case IncomData.RequestData.Code of
        SuccessCode:
          begin
            FConnectionChecked := True;
            if not FIsShuttingDown and FRemoteIsAvailable then
            begin
              Logs.DoLog(Format('Connection to %s checked', [Address]), CmnLvlLogs, ltNone);

              if not FIsForSync then
                FOnConnectionChecked(Self)
              else
                BeginSyncChains;
            end;

            WaitForReceive;
          end;

        InitConnectErrorCode:
          begin
            FIsShuttingDown := True;
            raise EConnectionClosed.Create('archiver has terminated the connection: public key not verified');
          end;

        KeyAlreadyUsesErrorCode:
          begin
            FIsShuttingDown := True;
            raise EConnectionClosed.Create('archiver has terminated the connection: key is already in use');
          end;

        ImShuttingDownCode:
          begin
            FRemoteIsAvailable := False;
            WaitForReceive;
          end;

        UnknownCommandErrorCode:
          begin
            FIsShuttingDown := True;
            raise EConnectionClosed.Create('archiver has terminated the connection: unknown command sended');
          end

        else
          begin
            FSocket.Receive(IncomData.RequestData.ID, 8, [TSocketFlag.WAITALL]);
            FSocket.Receive(LengthBytes, 4, [TSocketFlag.WAITALL]);
            FSocket.Receive(IncomData.Data, Length, [TSocketFlag.WAITALL]);

            case IncomData.RequestData.Code of
              ResponseCode:
                WriteResponseData(IncomData)
              else begin
                AddIncomRequest(IncomData);
                WaitForReceive;
              end;
            end;
          end;
      end;
    end else
      raise EConnectionClosed.Create('');
  except
    on E:EConnectionClosed do
      DoDisconnect(E.Message);
    on E:ESocketError do
      DoDisconnect('timeout data receiving');
  end;
end;

procedure TClientConnection.Reconnect;
begin
  Disconnect;

  if not FRemoteIsAvailable then
    Logs.DoLog(Format('%s is shutting down. Wait for connecting...', [Address]),
      CmnLvlLogs, ltNone)
  else
    Logs.DoLog(Format('Reconnecting to %s...', [Address]), CmnLvlLogs, ltNone);

  Connect(FAddress, FPort, False);

  if FIsShuttingDown then
    FOnDisconnected(Self);
end;

procedure TClientConnection.SetSyncFlag(AValue: Boolean);
begin
  if FIsForSync = AValue then
    exit;

  FIsForSync := AValue;
  if FIsForSync and FConnectionChecked then
    BeginSyncChains;
end;

end.
