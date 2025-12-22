unit Blockchain.Core;

interface

uses
  System.IOUtils,
  System.SysUtils,
  System.DateUtils,
  App.Types,
  App.DateUtils,
  App.Logs,
  App.Measure,
  Crypto.Types,
  Crypto.EthereumSigner,
  Crypto,
  Database.Core,
  Database.Types,
  Cache.Dictionary,
  Cache.Data,
  Blockchain.Types,
  Blockchain.Data,
  Blockchain.Cache,
  Miner.Utils,
  IconUtils;

type
  TBlockchainCore = class
  private type
    TValidateOptions = set of (ExcludeValidateSign, ExcludeValidateBalances,
      ModifyDate, UseCurrentStake, CheckValidate);
  private
    FDatabase: TDatabase;
    FCache: TCache;
    function DoValidateTransactions(Bytes: TBytes; out Count: Integer;
      Options: TValidateOptions = []; UpdateProc: TProc<TBytes> = nil;
      NoAppendDataProc: TProc<TBytes, string> = nil): TBlockHash; overload;
  public
    constructor Create; overload;
    constructor Create(const PathToData: string); overload;
    destructor Destroy; override;
    procedure WriteData(const Data: TBytes);
    function ReadData(const Index, Count: UInt64): TArray<TBytes>;
    function RecordsCount: Int64;
    function Valid4RecordsCount: Integer;
    function GetIconBytes(const RawBytes: TBytes): TBytes;
    function DoTransaction(const Bytes: TBytes): TBytes;
    function DoValidation(const Bytes: TBytes): TBytes;
    function ReadRawData(StartIndex: Int64): TBytes; overload;
    function ReadRawData(const Index, Count: UInt64): TBytes; overload;
    procedure WriteRawData(const Data: TBytes);
    function GetTokenData(const Name: string; Required: Boolean = True): TToken;
    function GetTokensData: TArray<TToken>;
    function Balance(const Address: TAddress; TokenId:Uint64): TAmount;
    function AvailableBalance(const Address: TAddress): TAmount;
    function StakingBalance(const Address: TAddress): TAmount;
    function GetNo(const Address: TAddress): UInt32;
    function IncNo(const Address: TAddress): UInt32;
    procedure EnumTxns(Proc: TTxFilterPredicate);
    function GetStakingInfo(const AAddress: TAddress): TStakingInfo;
    function GetRewardBalance(const AAddress: TAddress): TAmount;
    function GetTransactionInfo(Index: Int64): TTransactionInfo; overload;
    function GetTransactionInfo(const TxHash: TBlockHash): TTransactionInfo; overload;
    function GetBlockInfo(const Hash: TBlockHash): TBlockInfo;
    function GetLastBlocksInfo(Skip, Count: Int64): TArray<TBlockInfo>;
    function GetLastBlockHash: TBlockHash;
    function GetLastBlock: TBlock;
    function GetIndexOf(const TxHash: TBlockHash): Int64;
    function SumFee(const Bytes: TBytes): TAmount;
  end;

implementation

const
  SExecuteMeasure = 'Execute %d transactions (%d bytes) in time: %dms';
  SValidateMeasure = 'Validate %d transactions (%d bytes) in time: %dms';
  SRawSaved = 'Raw data saved: %d records (%d bytes)';

constructor TBlockchainCore.Create;
begin
  Create(TPath.GetAppPath);
end;

destructor TBlockchainCore.Destroy;
begin
  FCache.Free;
  FDatabase.Free;
end;

function TBlockchainCore.Balance(const Address: TAddress; TokenId:Uint64): TAmount;
begin
  Lock(Self);
  Result := FCache.GetBalance(Address, TokenId);
end;

constructor TBlockchainCore.Create(const PathToData: string);
begin
  Logs.DoLog('prepare to start ...', INFO);
  FDatabase := TDatabase.Create(TPath.Combine(PathToData, 'data'));
  FDatabase.IndexIn := Disk;
  FCache := TCache.Create(FDatabase);
  FDatabase.Open;
  FCache.Open;
  Logs.DoLog('TBlockchainCore.Create Ok', DEBUG);
end;

function TBlockchainCore.StakingBalance(const Address: TAddress): TAmount;
begin
  Lock(Self);
  Result := FCache.GetStakingBalance(Address);
end;

function TBlockchainCore.AvailableBalance(const Address: TAddress): TAmount;
begin
  Lock(Self);
  Result := FCache.GetAvailableBalance(Address);
end;

function TBlockchainCore.GetTokenData(const Name: string; Required: Boolean = True): TToken;
begin
  Lock(Self);
  Result := FCache.GetTokenData(Name, Required);
end;

function TBlockchainCore.GetTokensData: TArray<TToken>;
begin
  Lock(Self);
  Result := FCache.GetTokens;
end;

function TBlockchainCore.GetNo(const Address: TAddress): UInt32;
begin
  Lock(Self);
  Result := FCache.GetNo(Address);
end;

function TBlockchainCore.GetRewardBalance(const AAddress: TAddress): TAmount;
begin
  Lock(Self);
  Result := FCache.GetRewardBalance(AAddress);
end;

function TBlockchainCore.IncNo(const Address: TAddress): UInt32;
begin
  Lock(Self);
  Result := FCache.IncNo(Address);
end;

function TBlockchainCore.RecordsCount: Int64;
begin
  Lock(Self);
  Result := FDatabase.Count;
end;

procedure TBlockchainCore.WriteData(const Data: TBytes);
begin
  Lock(Self);
  FDatabase.AppendData([Data]);
end;

function TBlockchainCore.ReadData(const Index, Count: UInt64): TArray<TBytes>;
begin
  Lock(Self);
  Result := FDatabase.ReadData(Index, Count);
end;

function TBlockchainCore.DoValidateTransactions(Bytes: TBytes; out Count: Integer;
  Options: TValidateOptions = []; UpdateProc: TProc<TBytes> = nil;
  NoAppendDataProc: TProc<TBytes, string> = nil): TBlockHash;

var
  NeedBalance: TDictionary<TTokenAddressPair, UInt64>;
  Ticker: string;

  procedure IncNeedBalance(AAddress:Taddress; AAmount:TAmount; ATokenId: Uint64);
  begin
    var PTokenBalance := NeedBalance[TTokenAddressPair.Create(ATokenId, AAddress)];
    Inc(PTokenBalance^, AAmount);
  end;

  procedure SetResultIfEmpty(const AHash:TBlockHash);
  begin
    if Result.IsEmpty then Result := AHash;
  end;

begin
  try
    var OutAssets := TDictionary<TAddress, TOut>.Create;
    AddRelease(OutAssets);

    NeedBalance := TDictionary<TTokenAddressPair, UInt64>.Create;
    AddRelease(NeedBalance);

    Count := 0;
    Result := EmptyBlockHash;

    var _SumFee:UInt64 := 0;
    var LastBlockHash: TBlockHash;
    var LastBlockIndexTo: UInt64;
    const LastBlock = GetLastBlock;
    LastBlockHash :=  LastBlock.Data.Hash;
    LastBlockIndexTo := LastBlock.Data.IndexTo;

    var TecOwnerAddress := GetTokenData('TEC', False).AddressOwner;
    var Offset := Integer(0);

    Logs.DoLog('start main validation cycle', DEBUG);

    while Offset<Length(Bytes) do begin
      var Len := TCode.ValueOf<TDataLength>(Bytes, Offset);
      var _Offset := Offset;
      const DataType = TCode.ValueOf<TDataType>(Bytes, _Offset);
      const PData = @Bytes[_Offset];

      if DataType = MINT_TRANSACTION then begin
        const Mint: TMint = PData;
        const Address:TAddress = Mint.SenderAddress;
        if SameText('TEC', Mint.Name) then
          TecOwnerAddress := Address;
        OutAssets[Address].MinNo(Mint.No);
        Require(not FCache.TokenExists(Mint.Ticker), 'duplicate token');
        Require(Mint.Amount > 0, 'wrong amount');
        Require((RecordsCount = 0) or (Mint.Fee > 0), 'wrong fee');

        Require(Length(Mint.Name) in [3..32], 'invalid token name length');
        Require(Length(Mint.Ticker) in [3..8], 'invalid token ticker length');
        Require(Length(Mint.Description) in [10..255], 'invalid token description length');
        Require(Length(Mint.IconURL) in [0..128], 'invalid token icon URL length');

        IncNeedBalance(Address, Mint.Fee, 0 {TEC});
        Inc(_SumFee, Mint.Fee);
        Ticker := Mint.Ticker.ToUpper;
        if not (ExcludeValidateSign in Options) then Mint.CheckSign;
        SetResultIfEmpty(Mint.Hash);
      end else

      if DataType = MINT_LIQUIDITY_TRANSACTION then
      begin
        const Mint: TLiquidityMint = PData;
        const Address: TAddress = Mint.SenderAddress;
        if SameText('TEC', Mint.Name) then
          TecOwnerAddress := Address;
        OutAssets[Address].MinNo(Mint.No);
        Require(not FCache.TokenExists(Mint.Ticker), 'duplicate token');
        Require(Mint.Amount > 0, 'wrong amount');
        Require(Mint.Fee > 0, 'wrong fee');
        Require(AvailableBalance(Mint.SenderAddress) >= (Mint.Liquidity + Mint.Fee), 'not enough TEC');

        Require(Length(Mint.Name) in [3..32], 'invalid token name length');
        Require(Length(Mint.Ticker) in [3..8], 'invalid token ticker length');
        Require(Length(Mint.Description) in [10..255], 'invalid token description length');
        Require(Length(Mint.IconURL) in [0..128], 'invalid token icon URL length');

        IncNeedBalance(Address, Mint.Liquidity, 0 {TEC});
        IncNeedBalance(Address, Mint.Fee, 0);
        Inc(_SumFee, Mint.Fee);
        Ticker := Mint.Ticker.ToUpper;
        if not (ExcludeValidateSign in Options) then Mint.CheckSign;
        SetResultIfEmpty(Mint.Hash);
      end else

      if DataType = BURN_TOKEN_TRANSACTION then
      begin
        const Burn: TTokenBurn = PData;
        const Address: TAddress = Burn.SenderAddress;
        OutAssets[Address].MinNo(Burn.No);
        Require(Burn.Amount > 0, 'wrong amount');
        Require(Burn.Fee > 0, 'wrong fee');
        Require(Balance(Burn.SenderAddress, Burn.TokenID) >= Burn.Amount, 'not enough tokens');
        var TokenData := GetTokenData(FCache.GetTokenTicker(Burn.TokenID), True);
        Require(TokenData.ExRate > 0, 'the token has no liquidity');

        IncNeedBalance(Address, Burn.Amount, Burn.TokenID);
        IncNeedBalance(Address, Burn.Fee, 0 {TEC});
        Inc(_SumFee, Burn.Fee);
        if not (ExcludeValidateSign in Options) then Burn.CheckSign;
        SetResultIfEmpty(Burn.Hash);
      end else

      if DataType = TRANSFER_TRANSACTION then begin
        const Transfer: PTransfer = PData;
        const AddressFrom = Transfer.SenderAddress;
        OutAssets[AddressFrom].MinNo(Transfer.Data.No);
        Require(not Transfer.Data.AddressTo.IsEmpty, 'invalid address');
        Require(Transfer.Data.AddressTo <> AddressFrom, 'match addresses');
        Require(Transfer.Data.Amount >= 0, 'wrong amount');
        Require(Transfer.Data.Fee > 0, 'wrong fee');
        IncNeedBalance(AddressFrom, Transfer.Data.Amount, Transfer.Data.TokenId);
        IncNeedBalance(AddressFrom, Transfer.Data.Fee, 0 {TEC});
        Inc(_SumFee, Transfer.Data.Fee);

        if not (ExcludeValidateSign in Options) then Transfer.CheckSign;
        if ModifyDate in Options then Transfer.Date := TUnixTimestamp.Now;
        SetResultIfEmpty(Transfer.Hash);
      end else

      if DataType = STAKING_TRANSACTION then begin
        const Staking: PStaking = PData;
        const Address: TAddress = Staking.SenderAddress;
        OutAssets[Address].MinNo(Staking.Data.No);
        OutAssets[Address].StakingInc(Staking.Data.Amount);
        Require(Staking.Data.Amount >= 0, 'wrong amount');
        Require(Staking.Data.Fee > 0, 'wrong fee');
        IncNeedBalance(Address, Staking.Data.Amount + Staking.Data.Fee, 0 {TEC});
        Inc(_SumFee, Staking.Data.Fee);
        if not (ExcludeValidateSign in Options) then Staking.CheckSign;
        SetResultIfEmpty(Staking.Hash);
      end else

      if DataType = UNSTAKING_TRANSACTION then begin
        const Unstaking: PUnstaking = PData;
        const Address: TAddress = Unstaking.SenderAddress;
        OutAssets[Address].MinNo(Unstaking.Data.No);
        Require(Unstaking.Data.Amount > 0, 'wrong amount');
        Require(Unstaking.Data.Fee > 0, 'wrong fee');
        OutAssets[Address].UnstakingInc(Unstaking.Data.Amount);
        IncNeedBalance(Address, Unstaking.Data.Fee, 0 {TEC});
        Inc(_SumFee, Unstaking.Data.Fee);
        if not (ExcludeValidateSign in Options) then Unstaking.CheckSign;
        SetResultIfEmpty(Unstaking.Hash);
      end else

      if DataType = MIGRATE_TRANSACTION then begin
        const Migrate: PMigrate = PData;
        const Address: TAddress = Migrate.SenderAddress;
        OutAssets[Address].MinNo(Migrate.Data.No);
        Require(Migrate.Data.Amount > 0, 'wrong amount');
        Require(Address <> Migrate.Data.AddressTo, 'match addresses');
        Require(not Migrate.Data.AddressTo.IsEmpty, 'invalid address');
        Require((Address = TecOwnerAddress) or (Migrate.Data.AddressTo = TecOwnerAddress), 'wrong address');
        IncNeedBalance(Address, Migrate.Data.Amount, 0 {TEC});
        if not (ExcludeValidateSign in Options) then Migrate.CheckSign;
        SetResultIfEmpty(Migrate.Hash);
      end else

      if DataType = VALIDATE1_TRANSACTION then begin
        const Validate1: PValidate1 = PData;
        const Address: TAddress = Validate1.SenderAddress;
        OutAssets[Address].MinNo(Validate1.Data.No);
        var V := Validate1.Data.Validator;
        Require(V.Reward = 0, 'wrong amount');
        Require(not V.Address.IsEmpty, 'invalid address');
        Require(not Validate1.Data.TxHash.IsEmpty, 'invalid txhash');
        if not (ExcludeValidateSign in Options) then Validate1.CheckSign;
        SetResultIfEmpty(Validate1.Hash);
      end else

      if DataType = VALIDATE4_TRANSACTION then begin
        const Validate4: PValidate4 = PData;
        const Address: TAddress = Validate4.SenderAddress;
        OutAssets[Address].MinNo(Validate4.Data.No);
        for var V in Validate4.Data.Validators do begin
          Require(V.Reward > 0, 'wrong amount');
          Require(not V.Address.IsEmpty, 'invalid address');
        end;
        Require(not Validate4.Data.TxHash.IsEmpty, 'invalid txhash');
        if not (ExcludeValidateSign in Options) then Validate4.CheckSign;
        SetResultIfEmpty(Validate4.Hash);
      end else

      if DataType = MINEBLOCK_TRANSACTION then begin
        const Block: PBlock = PData;
        const Address:TAddress = Block.SenderAddress;
        var CurrentStaking := StakingBalance(Address);
        if OutAssets.ContainsKey(Address) then begin
          const JustStaked = OutAssets[Address].Stake;
          const JustUnstaked = OutAssets[Address].Unstaking;
          CurrentStaking := CurrentStaking + JustStaked - JustUnstaked;
        end;
        Require(CurrentStaking >= MINER_MIN_STAKE, 'low stake for mining');
        if Block.Data.IndexTo < RecordsCount then begin
          Require(Block.Data.PrevBlockHash = LastBlockHash, 'wrong prev block');
          var IndexFrom := UInt64(0);
          if not LastBlockHash.IsEmpty then
            IndexFrom := LastBlockIndexTo + 1;
          const Data = ReadRawData(IndexFrom, Block.Data.IndexTo - IndexFrom + 1);
          const Reward = SumFee(Data);
          const Difficulty = CalcDifficulty(Block.Data.StakeAmount);
          if UseCurrentStake in Options then
            Require(Block.Data.StakeAmount = CurrentStaking, 'wrong stake amount');
          Require(Reward = Block.Data.Reward, 'wrong reward MINEBLOCK_TRANSACTION');
          Require(Block.Data.Hash = GetNonceHash(Block.Data.Nonce, Data), 'wrong hash');
          Require(HashDifficulty(Block.Data.Hash) < Difficulty, 'low difficulty');
        end;
        Require(Block.Data.Reward > 0, 'wrong reward MINEBLOCK_TRANSACTION');
        if not (ExcludeValidateSign in Options) then Block.CheckSign;
        SetResultIfEmpty(Block.Data.Hash);
        LastBlockHash := Block.Data.Hash;
        LastBlockIndexTo := Block.Data.IndexTo;
      end else

      if DataType = VALIDATE_TRANSACTION then begin
        const Validate: PValidate = PData;
        const Address: TAddress = Validate.SenderAddress;
        OutAssets[Address].MinNo(Validate.Data.No);
        Require(not Validate.Data.ToHash.IsEmpty, 'tohash is empty');
        if CheckValidate in Options then begin
          Require(Validate.Data.Reward = _SumFee, 'wrong reward VALIDATE_TRANSACTION, ' +
            'Validate.Data.Reward = ' + Validate.Data.Reward.ToString + ', ' +
            'SumFee(Bytes) = ' + _SumFee.ToString);
        end;
        if not (ExcludeValidateSign in Options) then Validate.CheckSign;
        if ModifyDate in Options then Validate.Date := TUnixTimestamp.Now;
        SetResultIfEmpty(Validate.Hash);
      end else

      if DataType = TOKEN_ICON_DATA then begin
        const TokenIcon: PIconData = PData;
        Require(isValidIcon(TIconData(TokenIcon).Bytes), 'invalid icon');
        if Assigned(NoAppendDataProc) then
        begin
          NoAppendDataProc(TIconData(TokenIcon).Bytes, Ticker);

          Bytes := Copy(Bytes, 0, Offset - SizeOf(TDataLength)) +
            Copy(Bytes, Offset + Len, Length(Bytes));
          Dec(Offset, SizeOf(TDataLength));
          Len := 0;
        end;
      end else
        Stop('Unknown transaction type (' + DataType.ToString + ')');

      Inc(Count);
      Inc(Offset, Len);
    end;

    Lock(Self);

    for var Pair in OutAssets do begin
      if not (ExcludeValidateBalances in Options) then begin
        const JustStaked = Pair.Value.Stake;
        const JustUnstaked = Pair.Value.Unstaking;
        Require(StakingBalance(Pair.Key) + JustStaked >= JustUnstaked, 'insufficient staking');
      end;
      Require((Pair.Value.No = 0) or (GetNo(Pair.Key) < Pair.Value.No), 'duplicate transaction');
    end;

    if not (ExcludeValidateBalances in Options) then begin
      for var Pair in NeedBalance do begin
        if Pair.Key.TokenId = 0 {TEC} then
          Require(AvailableBalance(Pair.Key.Address) >= Pair.Value, 'insufficient funds')
        else
          Require(Balance(Pair.Key.Address, Pair.Key.TokenId) >= Pair.Value, 'insufficient funds')
      end;
    end;

    if Assigned(UpdateProc) then begin
      try
        UpdateProc(Bytes);
      except
        on E:Exception do begin
          Logs.DoLog('Error in UpdateProc: ' + E.Message, ERROR);
          raise;
        end;
      end;
    end;

  except
    on E:Exception do begin
      Logs.DoLog('Error in DoValidateTransactions: ' + E.Message, ERROR);
      Logs.DoLog('Count = ' + Count.ToString, DEBUG);
      raise;
    end;
  end;
end;

function TBlockchainCore.DoTransaction(const Bytes: TBytes): TBytes;
begin
  Lock(Self);
  var Count := Integer(0);
  var M := TMeasure.Start;
  var AddrFrom: TAddress := '';
  try
    Result := DoValidateTransactions(Bytes, Count, [ExcludeValidateSign,
      ModifyDate, UseCurrentStake, CheckValidate],
      procedure(ToAppend: TBytes)
      begin
        try
          M.Step('Validate: %dms');
          Logs.DoLog('FDatabase.AppendRawData ' + length(Bytes).ToString, DEBUG);
          FDatabase.AppendRawData(ToAppend);
          M.Step('Save: %dms');
          Logs.DoLog('FCache.Update', DEBUG);
          FCache.Update;
          M.Step('CacheUpdate: %dms').Stop;
        except
          on E:Exception do begin
            Logs.DoLog('Error in UpdateProc: ' + E.Message, ERROR);
            raise;
          end;
        end;
      end,

      procedure(IconBytes: TBytes; NewTokenTicker: string)
      begin
        try
          IconUtils.WriteNewIcon(IconBytes, NewTokenTicker);
        except
          on E:Exception do begin
            Logs.DoLog('Error in NoUpdateDataProc: ' + E.Message, ERROR);
            raise;
          end;
        end;
      end);
  except
    on E:Exception do begin
      Logs.DoLog('Error in TBlockchainCore.DoTransaction: ' + E.Message, ERROR);
      raise;
    end;
  end;

  Logs.DoLog(Format(SExecuteMeasure, [Count, Length(Bytes), M.Elapsed]), INFO);
  Logs.DoLog(M.ToString, INFO);
  Logs.DoLog('Hash: ' + BytesToHex(Result).ToLower, INFO);
end;

function TBlockchainCore.DoValidation(const Bytes: TBytes): TBytes;
begin
  Lock(Self);
  var M := TMeasure.Start;
  var Count := Integer(0);
  Result := DoValidateTransactions(Bytes, Count);
  M.Step('Validate: %dms').Stop;
  Logs.DoLog(Format(SValidateMeasure, [Count, Length(Bytes), M.Elapsed]), INFO);
  Logs.DoLog('Hash: ' + BytesToHex(Result).ToLower, INFO);
end;

function TBlockchainCore.ReadRawData(StartIndex: Int64): TBytes;
const _1Mb = 1 * 1024 * 1024;
begin
  Lock(Self);
  Result := FDatabase.ReadRawSize(StartIndex, _1Mb);
end;

function TBlockchainCore.ReadRawData(const Index, Count: UInt64): TBytes;
begin
  Lock(Self);
  Result := FDatabase.ReadRawData(Index, Count);
end;

procedure TBlockchainCore.WriteRawData(const Data: TBytes);
begin
  Lock(Self);
  var Count := Integer(0);
  DoValidateTransactions(Data, Count, [ExcludeValidateSign, ExcludeValidateBalances],
    procedure(ToAppend: TBytes)
    begin
      try
        FDatabase.AppendRawData(ToAppend);
      except on E: Exception do
          Logs.DoLog('write data exception ' + e.Message , ERROR);
      end;
      try
        FCache.Update;
      except on E: Exception do
          Logs.DoLog('cache update exception ' + e.Message , ERROR);
      end;
    end);
  Logs.DoLog(Format(SRawSaved, [Count, length(Data)]), INFO);
end;

procedure TBlockchainCore.EnumTxns(Proc: TTxFilterPredicate);
begin
  Lock(Self);
  FCache.EnumTxns(Proc);
end;

function TBlockchainCore.GetStakingInfo(const AAddress: TAddress): TStakingInfo;
begin
  Lock(Self);
  Result := Default(TStakingInfo);
  var Timestamp := FCache.GetStakingDate(AAddress);
  if Timestamp = 0 then
    Result.Days := 0
  else
    Result.Days := DaysBetween(Timestamp.ToDateTime(False), Now);
end;

function TBlockchainCore.GetTransactionInfo(Index: Int64): TTransactionInfo;
begin
  Lock(Self);
  Result := FCache.GetTransactionInfo(Index);
end;

function TBlockchainCore.GetTransactionInfo(const TxHash: TBlockHash): TTransactionInfo;
begin
  Lock(Self);
  Result := FCache.GetTransactionInfo(TxHash);
end;

function TBlockchainCore.GetBlockInfo(const Hash: TBlockHash): TBlockInfo;
begin
  Lock(Self);
  Result := FCache.GetBlockInfo(Hash);
end;

function TBlockchainCore.GetLastBlocksInfo(Skip, Count: Int64): TArray<TBlockInfo>;
begin
  Lock(Self);
  Result := FCache.GetLastBlocksInfo(Skip, Count);
end;

function TBlockchainCore.GetLastBlockHash: TBlockHash;
begin
  Lock(Self);
  Result := FCache.GetLastBlockHash;
end;

function TBlockchainCore.GetLastBlock: TBlock;
begin
  Lock(Self);
  Result := FCache.GetLastBlock;
end;

function TBlockchainCore.GetIconBytes(const RawBytes: TBytes): TBytes;
begin
  Lock(Self);
  var Offset := Integer(8);
  const Len = TCode.ValueOf<TDataLength>(RawBytes, Offset);
  var _Offset := Offset;
  const DataType = TCode.ValueOf<TDataType>(RawBytes, _Offset);
  const PData = @RawBytes[_Offset];
end;

function TBlockchainCore.GetIndexOf(const TxHash: TBlockHash): Int64;
begin
  Lock(Self);
  Result := FCache.GetTransactionIndexByHash(TxHash);
end;

function TBlockchainCore.SumFee(const Bytes: TBytes): TAmount;
begin
  Lock(Self);

  Result := 0;
  var Offset := Integer(0);
  var _Offset := Offset;

  try
    while Offset < Length(Bytes) do begin
      var Len := TCode.ValueOf<TDataLength>(Bytes, Offset);
      _Offset := Offset;
      var DataType := TCode.ValueOf<TDataType>(Bytes, _Offset);
      var PData := @Bytes[_Offset];

      if DataType = MINT_TRANSACTION then
        Result := Result + TMint(PData).Fee
      else
      if DataType = TRANSFER_TRANSACTION then
        Result := Result + PTransfer(PData).Data.Fee
      else
      if DataType = STAKING_TRANSACTION then
        Result := Result + PStaking(PData).Data.Fee
      else
      if DataType = UNSTAKING_TRANSACTION then
        Result := Result + PUnstaking(PData).Data.Fee;

      Inc(Offset, Len);
    end;
  except on E:Exception do begin
      logs.DoLog('!! TBlockchainCore.SumFee: ' + E.Message, DEBUG);
      logs.DoLog('!! Result: ' + Result.ToString, DEBUG);
      logs.DoLog('!! Offset: ' + Offset.ToString, DEBUG);
      logs.DoLog('!! _Offset: ' + _Offset.ToString, DEBUG);
      raise;
    end;
  end;
end;

function TBlockchainCore.Valid4RecordsCount: Integer;
begin
  Lock(Self);
  Result := FCache.Vali4TxCount;
end;

end.
