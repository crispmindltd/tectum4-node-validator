unit Sync.ChainsUpdater;

interface

uses
  App.Exceptions,
  App.Intf,
  App.Logs,
  App.Updater,
  Blockchain.Address,
  Blockchain.Data,
  Blockchain.Reward,
  Blockchain.Txn,
  Blockchain.Validation,
  Classes,
  Crypto,
  Generics.Collections,
  Math,
  Net.Data,
  Net.Socket,
  Sync.Base,
  SyncObjs,
  SysUtils;

type
  TBlocksUpdater = class(TSyncChain)
    private
      FIsChainsSync: Boolean;
      FVerReqTimer: UInt64;
      FSendLock: TCriticalSection;
      FDynTETChainTotalBlocksToLoad: Integer;
      FTETChainTotalBlocksToLoad: Integer;

      procedure DoChainsSyncRequests;
      procedure DoPing;
      procedure DoVersionRequest;
      procedure SetChainsSync(AValue: Boolean);
      procedure ReceiveValidationData;

      function DoBlocksRequest<T>(const ACommandCode: Byte;
        const AFileName:string): Boolean;
    protected
      procedure Execute; override;
    public
      constructor Create(const AAddress: string; APort: Word);
      destructor Destroy; override;

      function DoRequest(const ARequestBytes: TBytes): TBytes;

      property IsChainsSync: Boolean read FIsChainsSync write SetChainsSync;
  end;

implementation

{ TBlocksUpdater }

constructor TBlocksUpdater.Create(const AAddress: string; APort: Word);
begin
  inherited Create(AAddress, APort);

  FDynTETChainTotalBlocksToLoad := 0;
  FTETChainTotalBlocksToLoad := 0;
  FSendLock := TCriticalSection.Create;
end;

destructor TBlocksUpdater.Destroy;
begin
  FSendLock.Free;

  inherited;
end;

procedure TBlocksUpdater.Execute;
var
  CommandCode: Byte;
  NeedDownloadBlocks: Boolean;
begin
  inherited;
  if Terminated or (Status > 0) then
    exit;

  try
      AppCore.BlocksSyncDone := True;

    while not (Terminated or (Status > 0)) do
    begin
      if FSocket.ReceiveLength > 0 then
      begin
        FSendLock.Enter;
        try
          FSocket.Receive(CommandCode, 0, 1, [TSocketFlag.WAITALL]);
          if CommandCode = ValidateCommandCode then
            ReceiveValidationData;
        finally
          FSendLock.Leave;
        end;
      end;

      if FIsChainsSync then
        DoChainsSyncRequests
      else
        DoPing;

      if not Terminated then
        BreakableSleep(RequestDelay);
    end;

    if Status = 0 then
      FSocket.Send([DisconnectingCode], 0, 1);
  except
    on E:EReceiveTimeout do
      if not DoTryReconnect then
        DoCantReconnect;
    on E:Exception do
      DoCantReconnect;
  end;
end;

procedure TBlocksUpdater.ReceiveValidationData;
var
  CountBytes: array[0..3] of Byte;
  Count: Integer absolute CountBytes;
  Sign: string;
  Bytes: TBytes;
begin
  FSocket.Receive(CountBytes, 0, 4, [TSocketFlag.WAITALL]);
  Bytes := GetResponse(Count);
  AppCore.DoValidation(Bytes, Sign);
  Bytes := TEncoding.ANSI.GetBytes(Sign);
  const Len = Length(Bytes);
  Bytes := [ValidationDoneCode] + BytesOf(@Len, 4) + Bytes;
  FSocket.Send(Bytes, 0, Length(Bytes));
end;

procedure TBlocksUpdater.SetChainsSync(AValue: Boolean);
begin
  FIsChainsSync := AValue;
  if FIsChainsSync then
    FVerReqTimer := GetTickCount64 + TNodeUpdater.VersionRequestDelay;
end;

function TBlocksUpdater.DoRequest(const ARequestBytes: TBytes): TBytes;
var
  IncomCount: Integer;
  ReceivedBytes: TBytes;
begin
  FSendLock.Enter;
  try
    if Terminated or UpdateInProgress then
      exit;

    FSocket.Send(ARequestBytes);
    FSocket.Receive(IncomCount, 4, [TSocketFlag.WAITALL]);
    ReceivedBytes := GetResponse(IncomCount);
    Result := ReceivedBytes;
  finally
    FSendLock.Leave;
  end;
end;

function TBlocksUpdater.DoBlocksRequest<T>(const ACommandCode: Byte;
  const AFileName:string): Boolean;
var
  TxnCount: UInt64;
  IncomCount: Integer;
  BytesToReceive: TBytes;
begin
  Result := False;
  TxnCount := TMemBlock<T>.RecordsCount(AFileName);

  FSocket.Send([ACommandCode] + BytesOf(@TxnCount, 8), 0, 9);
  FSocket.Receive(IncomCount, 4, [TSocketFlag.WAITALL]);

  if Terminated or (IncomCount = 0) then
    Exit;

  BytesToReceive := GetResponse(IncomCount);

  if Terminated then
    Exit;

//  Logs.DoLog(Format('<DBC>[%d]: Blocks received = %d',
//    [SmartKeySyncCommandCode, IncomCount]), INCOM, TLogFolder.sync);

  TMemBlock<T>.ByteArrayToFile(AFileName, BytesToReceive);

  Result := True;
end;

procedure TBlocksUpdater.DoVersionRequest;
begin
  FSendLock.Enter;
  try
    if Terminated or UpdateInProgress then
      exit;

    FSocket.Send([CheckVersionCommandCode], 0, 1);
    GetVersionInfo;
    FVerReqTimer := GetTickCount64;
  finally
    FSendLock.Leave;
  end;
end;


procedure TBlocksUpdater.DoPing;
var
  Bytes: TBytes;
begin
  FSendLock.Enter;
  try
    if Terminated or UpdateInProgress then
      exit;
    FSocket.Send([PingCommandCode], 0, 1);
    GetResponse(1);
    if FSocket.ReceiveLength > 0 then begin
      const Command:Byte = FSocket.Receive(1, [TSocketFlag.PEEK])[0];
      if Command = ValidateCommandCode then begin
        Bytes := GetResponse(FSocket.ReceiveLength);

        // тут могла бы быть валидация

      end;
    end;
  finally
    FSendLock.Leave;
  end;
end;

procedure TBlocksUpdater.DoChainsSyncRequests;
var
  TokenID: Integer;
begin
  if IsTimeout(FVerReqTimer, TNodeUpdater.VersionRequestDelay) then
    DoVersionRequest;

  while not Terminated and DoBlocksRequest<TTxn>(GetTxnsCommandCode, TTxn.Filename) do
  begin
  end;

  while not Terminated and DoBlocksRequest<TAccount>(GetAddressesCommandCode,
    TAccount.Filename) do
  begin
  end;

  while not Terminated and DoBlocksRequest<TValidation>(GetValidationsCommandCode,
    TValidation.Filename) do
  begin
  end;

  while not Terminated and DoBlocksRequest<TReward>(GetRewardsCommandCode,
    TReward.Filename) do
  begin
  end;
end;

end.
