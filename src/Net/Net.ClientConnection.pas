unit Net.ClientConnection;

interface

uses
  App.Exceptions,
  App.Intf,
  App.Logs,
  App.Types,
  Blockchain.Address,
  Blockchain.Data,
  BlockChain.DataCache,
  Blockchain.Reward,
  Blockchain.Txn,
  Blockchain.Validation,
  System.Classes,
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
    private type
      TSyncData = set of (Rewards, Transactions, Addresses, Validations);
    private const
      SyncDataAll: TSyncData = [Rewards, Transactions, Addresses, Validations];
    private
      FAddress: string;
      FPort: Word;
      FOnConnectionChecked: TNotifyEvent;
      FOnConnectionLost: TNotifyEvent;
      FIsForSync: Boolean;
      FIsConnecting: Boolean;
      FSyncData: TSyncData;

      procedure Reconnect;
      procedure SetSyncFlag(AValue: Boolean);
      procedure BreakableSleep(ADuration: Integer);
      procedure BeginSyncChains;
      function GetBlockRequestBytes<T>(const AFileName: string): TBytes;
      procedure SyncData(Data: TSyncData);

      procedure DoDisconnect(const AReason: string = ''); override;
      function GetRemoteAddress: string; override;
      procedure ProcessCommand(const AIncomData: TResponseData); override;
      procedure ProcessResponse(const AResponse: TResponseData); override;
      function GetDisconnectMessage: string; override;
    public
      constructor Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
        AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TNotifyEvent;
        AOnConnectionLost: TNotifyEvent);
      destructor Destroy; override;

      procedure Connect(AAddress: string; APort: Word; AIsInitConnect: Boolean = True);

      property Address: string read GetRemoteAddress;
      property IsForSync: Boolean read FIsForSync write SetSyncFlag;
      property IsConnecting: Boolean read FIsConnecting;
  end;

implementation

{ TClientConnection }

procedure TClientConnection.BeginSyncChains;
begin
  SendRequest(GetRewardsCommandCode, GetBlockRequestBytes<TReward>(TReward.Filename));
  SendRequest(GetTxnsCommandCode, GetBlockRequestBytes<TTxn>(TTxn.Filename));
  SendRequest(GetAddressesCommandCode, GetBlockRequestBytes<TAccount>(TAccount.Filename));
  SendRequest(GetValidationsCommandCode, GetBlockRequestBytes<TValidation>(TValidation.Filename));
end;

procedure TClientConnection.BreakableSleep(ADuration: Integer);
var
  SleepFor: Integer;
begin
  while not FIsShuttingDown and (ADuration > 0) do begin
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

procedure TClientConnection.DoDisconnect(const AReason: string = '');
begin
  inherited;

  FIsChecked := False;
  if FIsShuttingDown then
    FOnDisconnected(Self)
  else begin
    FIsConnecting := True;
    FOnConnectionLost(Self);
    Reconnect;
    if FIsShuttingDown then
      FOnDisconnected(Self);
  end;
end;

function TClientConnection.GetBlockRequestBytes<T>(
  const AFileName: string): TBytes;
begin
  const BlocksCount = TMemBlock<T>.RecordsCount(AFileName);
  var Hash:T32Bytes;
  if BlocksCount > 0 then begin
    const LastBlock = TMemBlock<T>.ReadFromFile(AFilename, BlocksCount - 1);
    Hash := LastBlock.Hash;
  end else
    FillChar(Hash, SizeOf(T32Bytes), 0);

  Result := BytesOf(@BlocksCount, 8) + TBytes(Hash);
end;

function TClientConnection.GetDisconnectMessage: string;
begin
  Result := Format('Disconnected from %s', [Address]);
  if not FDiscMsg.IsEmpty then
    Result := Format('%s: %s', [Result, FDiscMsg]);
end;

function TClientConnection.GetRemoteAddress: string;
begin
  Result := Format('%s:%d', [FAddress, FPort]);
end;

procedure TClientConnection.SyncData(Data: TSyncData);
begin
  if FSyncData <> SyncDataAll then
  begin
    FSyncData := FSyncData + Data;
    if FSyncData = SyncDataAll then
      UI.NotifyNewTETBlocks;
  end;
end;

procedure TClientConnection.ProcessCommand(const AIncomData: TResponseData);
begin
  case AIncomData.Code of
    SuccessCode:
      begin
        FIsChecked := True;
        if not FIsShuttingDown then
        begin
          Logs.DoLog(Format('Connection to %s checked', [Address]), CmnLvlLogs, ltNone);

          if not FIsForSync then
            FOnConnectionChecked(Self)
          else
            BeginSyncChains;
        end;
      end;

    InitConnectErrorCode:
    begin
      FIsShuttingDown := True;
      FDiscMsg := 'archiver has terminated the connection: init connection error';
    end;

    KeyAlreadyUsesErrorCode:
    begin
      FIsShuttingDown := True;
      FDiscMsg := 'archiver has terminated the connection: key is already in use';
    end;

    BlockchainCorruptedErrorCode: begin
      raise EBlockchainCorrupted.Create();
    end;
  end;
end;

procedure TClientConnection.ProcessResponse(const AResponse: TResponseData);
begin
  case AResponse.Code of
    GetRewardsCommandCode: begin
      TMemBlock<TReward>.ByteArrayToFile(TReward.Filename, AResponse.Data);
      var i := 0;
      while i < Length(AResponse.Data) do begin
        const reward: TMemBlock<TReward> = Copy(AResponse.Data, i, SizeOf(TReward));
        DataCache.UpdateCache(reward);
        Inc(i, SizeOf(TReward));
      end;
      BreakableSleep(200);
      if FIsForSync and not FIsShuttingDown then begin
        SendRequest(GetRewardsCommandCode, GetBlockRequestBytes<TReward>(TReward.Filename));
        if Length(AResponse.Data) = 0 then SyncData([Rewards]) else FSyncData := [];
      end;
    end;

    GetTxnsCommandCode:
    begin
      const FromID = TMemBlock<TTxn>.RecordsCount(TTxn.Filename);
      TMemBlock<TTxn>.ByteArrayToFile(TTxn.Filename, AResponse.Data);
      var i := 0;
      while i < Length(AResponse.Data) do
      begin
        const txn: TMemBlock<TTxn> = Copy(AResponse.Data, i, SizeOf(TTxn));
        DataCache.UpdateCache(txn, FromID + i div SizeOf(TTxn));
        Inc(i, SizeOf(TTxn));
      end;

      BreakableSleep(200);
      if FIsForSync and not FIsShuttingDown then
      begin
        SendRequest(GetTxnsCommandCode, GetBlockRequestBytes<TTxn>(TTxn.Filename));
        if Length(AResponse.Data) = 0 then SyncData([Transactions]) else FSyncData := [];
      end;
    end;

    GetAddressesCommandCode:
    begin
      TMemBlock<TAccount>.ByteArrayToFile(TAccount.Filename, AResponse.Data);
      BreakableSleep(200);
      if FIsForSync and not FIsShuttingDown then
      begin
        SendRequest(GetAddressesCommandCode, GetBlockRequestBytes<TAccount>(TAccount.Filename));
        if Length(AResponse.Data) = 0 then SyncData([Addresses]) else FSyncData := [];
      end;
    end;

    GetValidationsCommandCode:
    begin
      TMemBlock<TValidation>.ByteArrayToFile(TValidation.Filename, AResponse.Data);
      BreakableSleep(200);
      if FIsForSync and not FIsShuttingDown then
      begin
        SendRequest(GetValidationsCommandCode, GetBlockRequestBytes<TValidation>(TValidation.Filename));
        if Length(AResponse.Data) = 0 then SyncData([Validations]) else FSyncData := [];
      end;
    end;
  end;
end;

procedure TClientConnection.Reconnect;
begin
  Disconnect;

  Logs.DoLog(Format('Reconnecting to %s...', [Address]), CmnLvlLogs, ltNone);

  Connect(FAddress, FPort, False);
end;

procedure TClientConnection.SetSyncFlag(AValue: Boolean);
begin
  if FIsForSync = AValue then
    exit;

  FIsForSync := AValue;
  if FIsForSync and FIsChecked then
    BeginSyncChains;
end;

end.
