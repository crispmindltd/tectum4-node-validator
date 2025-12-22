unit Blockchain.Cache;

interface

uses
  App.Logs,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  App.Types,
  App.Exceptions,
  App.DateUtils,
  Database.Types,
  Database.Core,
  Cache.Dictionary,
  Cache.Data,
  Blockchain.Types,
  Blockchain.Data,
  Crypto.Types,
  Math;

type
  TCache = class
    const CurrentCacheVersion = 5;
    private type

      TBalancesCache = class (TDictionary<TTokenAddressPair, TAmount>)
        function ToBytes: TBytes;
        procedure FromBytes(const Bytes: TBytes; var Offset: Integer);
        function IncTokenBalance(ATokenId:UInt64; AAddress:TAddress; Amount: TAmount):TAmount;
        function DecTokenBalance(ATokenId:UInt64; AAddress:TAddress; Amount: TAmount):TAmount;
      end;

      TAssetsCache = class (TDictionary<TAddress, TAssets>)
        private type
          TAssetsPair = TPair<TAddress, TAssets>;
        private
          function ToBytes: TBytes;
          procedure FromBytes(const Bytes: TBytes; var Offset: Integer);
      end;

      TTokensCache = class (TDictionary<string, TToken>)
        private type
          TTokensPair = TPair<string, TToken>;
        private
          function ToBytes: TBytes;
          procedure FromBytes(const Bytes: TBytes; var Offset: Integer);
      end;
      THashesCache = class (TDictionary<TBlockHash, Int64>)
        private type
          THashesPair = TPair<TBlockHash, Int64>;
        private
          function ToBytes: TBytes;
          procedure FromBytes(const Bytes: TBytes; var Offset: Integer);
      end;
      TBlocksCache = class (TList<Int64>)
        private
          function ToBytes: TBytes;
          procedure FromBytes(const Bytes: TBytes; var Offset: Integer);
      end;

  private
    FDatabase: TDatabase;
    FCacheIndex: UInt64;
    FBalances: TBalancesCache;  // token balances
    FAssets: TAssetsCache;      // balances, transaction no, staking
    FTokens: TTokensCache;      // tokens
    FHashes: THashesCache;      // transactions hashes
    FBlocks: TBlocksCache;      // mining blocks
    FLastBlockHash: TBlockHash; // last block
    FCacheFileName: TFileName;
    FValid4TxCount: Integer;
    function GetTransactionInfo(Index: Int64; const Data: TBytes): TTransactionInfo; overload;
  public
    constructor Create(DataBase: TDatabase);
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    procedure Update;
    procedure FlushCacheFile;
    function GetActualCacheFilename:string;
    function GetBalance(const Address: TAddress; TokenId:Uint64): TAmount;
    function GetStakingBalance(const Address: TAddress): TAmount;
    function GetAvailableBalance(const Address: TAddress): TAmount;
    function GetRewardBalance(const Address: TAddress): TAmount;
    function GetTokenData(const Ticker: string; Required: Boolean): TToken;
    function GetTokenTicker(const ID: UInt64): string;
    function GetTokens: TArray<TToken>;
    function TokenExists(const Ticker: string): Boolean;
    function GetNo(const Address: TAddress): UInt32;
    procedure SetNo(const Address: TAddress; const No: UInt32);
    function IncNo(const Address: TAddress): UInt32;
    procedure EnumTxns(Proc: TTxFilterPredicate);
    function GetTransactionInfo(Index: Int64): TTransactionInfo; overload;
    function GetTransactionInfo(const TxHash: TBlockHash): TTransactionInfo; overload;
    function GetBlockInfo(const Hash: TBlockHash): TBlockInfo;
    function GetLastBlocksInfo(Skip, Count: Int64): TArray<TBlockInfo>;
    function GetStakingDate(const Address: TAddress): TUnixTimestamp;
    function GetLastBlockHash: TBlockHash;
    function GetLastBlock: TBlock;
    function GetTransactionIndexByHash(const TxHash: TBlockHash): Int64;
    function ToTransactionInfo(Index: UInt64; const Data: TBytes): TTransactionInfo;

    property Vali4TxCount: Integer read FValid4TxCount;
  end;


implementation

{ TCache.TAssetsCache }
procedure TCache.TAssetsCache.FromBytes(const Bytes: TBytes; var Offset: Integer);
begin
  var Pairs: TArray<TAssetsPair>;
  for var I := 0 to TCode.ValueOf<Integer>(Bytes, Offset) - 1 do begin
    var K := TCode.ValueOf<TAddress>(Bytes, Offset);
    var V := TCode.ValueOf<TAssets>(Bytes, Offset);
    Pairs := Pairs + [TAssetsPair.Create(K, V)];
  end;
  SetPairs(Pairs);
end;

function TCache.TAssetsCache.ToBytes: TBytes;
begin
  Result := TCode.BytesOf<Integer>(Count);
  for var Pair in Self do
    Result := Result + TCode.BytesOf(Pair.Key) + TCode.BytesOf(Pair.Value);
end;

{ TCache.TTokensCache }

procedure TCache.TTokensCache.FromBytes(const Bytes: TBytes; var Offset: Integer);
begin
  var Pairs: TArray<TTokensPair>;
  for var I := 0 to TCode.ValueOf<Integer>(Bytes, Offset) - 1 do begin
    var Token := TToken.From(Bytes, Offset);
    Pairs := Pairs + [TTokensPair.Create(Token.Ticker, Token)];
  end;
  SetPairs(Pairs);
end;

function TCache.TTokensCache.ToBytes: TBytes;
begin
  Result := TCode.BytesOf<Integer>(Count);
  for var Pair in Self do
    Result := Result + TBytes(Pair.Value);
end;

{ TCache.THashCache }

procedure TCache.THashesCache.FromBytes(const Bytes: TBytes; var Offset: Integer);
begin
  var Pairs: TArray<THashesPair>;
  for var I := 0 to TCode.ValueOf<Integer>(Bytes, Offset) - 1 do begin
    var Key := TCode.ValueOf<TBlockHash>(Bytes, Offset);
    var Value := TCode.ValueOf<Int64>(Bytes, Offset);
    Pairs := Pairs + [THashesPair.Create(Key, Value)];
  end;
  SetPairs(Pairs);
end;

function TCache.THashesCache.ToBytes: TBytes;
begin
  Result := TCode.BytesOf<Integer>(Count);
  for var Pair in Self do
    Result := Result + TCode.BytesOf(Pair.Key) + TCode.BytesOf(Pair.Value);
end;

{ TCache.TBlocksCache }

procedure TCache.TBlocksCache.FromBytes(const Bytes: TBytes; var Offset: Integer);
begin
  var Items: TArray<Int64>;
  for var I := 0 to TCode.ValueOf<Integer>(Bytes, Offset) - 1 do
    Items := Items + [TCode.ValueOf<Int64>(Bytes, Offset)];
  Self.AddRange(Items);
end;

function TCache.TBlocksCache.ToBytes: TBytes;
begin
  Result := TCode.BytesOf<Integer>(Count);
  for var Item in Self do
    Result := Result + TCode.BytesOf(Item);
end;

{ TCache }
constructor TCache.Create(DataBase: TDatabase);
begin
  FCacheIndex := 0;
  FDatabase := Database;
  FTokens := TTokensCache.Create(10);
  FAssets := TAssetsCache.Create(5000);
  FHashes := THashesCache.Create(100000);
  FBalances := TBalancesCache.Create(5000);
  FBlocks := TBlocksCache.Create;
  FLastBlockHash := EmptyBlockHash;
  FValid4TxCount := 0;
  FCacheFileName := GetActualCacheFilename;
end;

destructor TCache.Destroy;
begin
  Close;
  FBalances.Free;
  FAssets.Free;
  FTokens.Free;
  FHashes.Free;
  FBlocks.Free;
end;

  // returns most actual cache file in data path
function TCache.GetActualCacheFilename: string;
begin
    Result := TPath.Combine(FDatabase.DataPath, 'cache');
    const CacheFilenames = TDirectory.GetFiles(FDatabase.DataPath, 'cache*');
    var MaxblockIndex:Uint64 := 0;
    for var filename in CacheFilenames do begin
      const Bytes = TFile.ReadAllBytes(filename);
      var Offset := Integer(0);

      const Version = TCode.ValueOf<Byte>(Bytes, Offset);
      if Version <> CurrentCacheVersion then Continue;

      const cacheIndex = TCode.ValueOf<UInt64>(Bytes, Offset);
      if cacheIndex > MaxblockIndex then begin
        Result := filename;
        MaxblockIndex := cacheIndex;
      end;
    end;
end;

procedure TCache.Open;
begin
  Logs.DoLog('Open cache file ...', DEBUG);
  if TFile.Exists(FCacheFileName) then begin
    var Data := TFile.ReadAllBytes(FCacheFileName);
    var Offset := Integer(0);
    var Version := TCode.ValueOf<Byte>(Data, Offset);
    if Version = CurrentCacheVersion then begin
      FCacheIndex := TCode.ValueOf<UInt64>(Data, Offset); //

      if FCacheIndex > FDatabase.Count then begin
        Logs.DoLog('Invalid cache file. Updating ...', DEBUG);
        TFile.Delete(FCacheFileName);
        AddFinally(Open);
        Exit;
      end;

      FTokens.FromBytes(Data, Offset);
      FAssets.FromBytes(Data, Offset);
      FBalances.FromBytes(Data, Offset);
      FHashes.FromBytes(Data, Offset);
      FBlocks.FromBytes(Data, Offset);
      FValid4TxCount := PInteger(@Data[Offset])^;
      Inc(Offset, 4);
      FLastBlockHash := TCode.ValueOf<TBlockHash>(Data, Offset);
      if FCacheIndex < FDatabase.Count then begin
        Update;
        FlushCacheFile;
      end;
    end else begin
      Logs.DoLog('Incorrect cache file version. Create new one ...', DEBUG);
      Update;
      FlushCacheFile;
    end;
  end else begin
    Logs.DoLog('No cache file. Create new one ...', DEBUG);
    Update;
    FlushCacheFile;
  end;
end;

procedure TCache.Close;
begin
  Logs.DoLog('Cache.Close', DEBUG);
  FlushCacheFile;
end;

procedure TCache.FlushCacheFile;
begin
  var fileName:string;
  repeat
    fileName := TPath.Combine(FDatabase.DataPath, 'cache.' + Random(1000).ToString);
  until not TFile.Exists(fileName);
  FCacheFileName := fileName;

  var Version: Byte := CurrentCacheVersion;
  var Data: TBytes;
  try
    Data := [Version] //
        + BytesOf(@FCacheIndex, SizeOf(FCacheIndex)) //
        + FTokens.ToBytes //
        + FAssets.ToBytes //
        + FBalances.ToBytes //
        + FHashes.ToBytes //
        + FBlocks.ToBytes //
        + BytesOf(@FValid4TxCount, 4) //
        + TCode.BytesOf<TBlockHash>(FLastBlockHash);
  except on E:Exception do begin
      Logs.DoLog('Exception on preparing cache file: ' + E.Message, DEBUG);
      raise;
    end;
  end;

  Logs.DoLog('Cache file ready to save.', DEBUG);
  TFile.WriteAllBytes(FCacheFileName, Data);
  Logs.DoLog('Cache file saved ok.', DEBUG);

  // delete older cache files
  const CacheFilenames = TDirectory.GetFiles(FDatabase.DataPath, 'cache*');
  for var LFilename in CacheFilenames do begin
    if not SameFileName(LFilename, FCacheFileName) then
      TFile.Delete(LFilename);
  end;
end;

function TCache.GetBalance(const Address: TAddress; TokenId:Uint64): TAmount;
begin
  Result := FBalances[TTokenAddressPair.Create(TokenId, Address)]^;
end;

function TCache.GetStakingBalance(const Address: TAddress): TAmount;
begin
  Result := FAssets[Address].Staking;
end;

function TCache.GetAvailableBalance(const Address: TAddress): TAmount;
begin
  var V := FAssets[Address];
  Result := GetBalance(Address, 0 {TEC id})- V.Staking;
end;

function TCache.GetTokenData(const Ticker: string; Required: Boolean): TToken;
begin
  if not FTokens.TryGetValue(Ticker, Result) then
    Require(not Required, 'unknown token');
end;

function TCache.GetTokens: TArray<TToken>;
begin
  var PairsArray := FTokens.ToArray;
  SetLength(Result, Length(PairsArray));
  for var i := 0 to Length(PairsArray) - 1 do
    Result[i] := PairsArray[i].Value;
end;

function TCache.GetTokenTicker(const ID: UInt64): string;
begin
  for var val in FTokens.ToArray do
    if val.Value.Id = ID then
      Exit(val.Value.Ticker);
end;

function TCache.TokenExists(const Ticker: string): Boolean;
begin
  Result := FTokens.ContainsKey(Ticker);
end;

function TCache.GetNo(const Address: TAddress): UInt32;
begin
  Result := FAssets[Address].No;
end;

function TCache.GetRewardBalance(const Address: TAddress): TAmount;
begin
  Result := FAssets[Address].Reward;
end;

procedure TCache.SetNo(const Address: TAddress; const No: UInt32);
begin
  FAssets[Address].SetNo(No);
end;

function TCache.IncNo(const Address: TAddress): UInt32;
begin
  Result := FAssets[Address].IncNo;
end;

procedure TCache.Update;
begin
  Logs.DoLog('Updating cache from ' + FCacheIndex.ToString + ' to ' + FDatabase.Count.ToString, DEBUG);
  const MaxUpdateAmount = 1000;
  var I:Integer;
  try
    repeat
      var UpdateAmount := FDatabase.Count - FCacheIndex;
      if UpdateAmount = 0 then Break;
      if UpdateAmount > MaxUpdateAmount then UpdateAmount := MaxUpdateAmount;
      var Data := FDatabase.ReadData(FCacheIndex, UpdateAmount);
      //Logs.DoLog('from ' + FCacheIndex.ToString + ' amount ' + UpdateAmount.ToString, DEBUG);
      for I := 0 to High(Data) do begin
        var DataType := PDataType(Data[I])^;
        var PData := @Data[I][SizeOf(TDataType)];
        const blockId = FCacheIndex + I;

        if DataType = MINT_TRANSACTION then begin
          var Mint: TMint := PData;
          var AddressOwner:TAddress := Mint.SenderAddress;

          var Token := Default(TToken);
          Token.Name := Mint.Name;
          Token.Ticker := Mint.Ticker;
          Token.Digits := Mint.Digits;
          Token.ExRate := 0;
          Token.Description := Mint.Description;
          Token.IconURL := Mint.IconURL;
          Token.AddressOwner := AddressOwner;
          Token.Id := blockId;

          FTokens.Add(Mint.Ticker, Token);

          var V := FAssets[AddressOwner];
          V.SetNo(Mint.No);

          FBalances.IncTokenBalance(blockId, AddressOwner, Mint.Amount);
          FBalances.DecTokenBalance(0 {TEC Id}, AddressOwner, Mint.Fee);

          FHashes.Add(Mint.Hash, blockId);
        end else

        if DataType = MINT_LIQUIDITY_TRANSACTION then begin
          var Mint: TLiquidityMint := PData;
          var AddressOwner:TAddress := Mint.SenderAddress;

          var Token := Default(TToken);
          Token.Name := Mint.Name;
          Token.Ticker := Mint.Ticker;
          Token.Digits := Mint.Digits;
          Token.ExRate := Mint.Liquidity / (Mint.Amount * Trunc(Power(10, 8 - Mint.Digits)));
          Token.Description := Mint.Description;
          Token.IconURL := Mint.IconURL;
          Token.AddressOwner := AddressOwner;
          Token.Id := blockId;

          FTokens.Add(Mint.Ticker, Token);

          var V := FAssets[AddressOwner];
          V.SetNo(Mint.No);

          FBalances.IncTokenBalance(blockId, AddressOwner, Mint.Amount);
          FBalances.DecTokenBalance(0 {TEC Id}, AddressOwner, Mint.Fee);
          FBalances.DecTokenBalance(0, AddressOwner, Mint.Liquidity);

          FHashes.Add(Mint.Hash, blockId);
        end else

        if DataType = BURN_TOKEN_TRANSACTION then
        begin
          var Burn: TTokenBurn := PData;
          var AddressOwner: TAddress := Burn.SenderAddress;

          var V := FAssets[AddressOwner];
          V.SetNo(Burn.No);
          FBalances.DecTokenBalance(0 {TEC id}, AddressOwner, Burn.Fee);
          FBalances.DecTokenBalance(Burn.TokenID, AddressOwner, Burn.Amount);
          var TokenData := GetTokenData(GetTokenTicker(Burn.TokenID), True);
          FBalances.IncTokenBalance(0, AddressOwner, Trunc(Burn.Amount * TokenData.ExRate));

          FHashes.Add(Burn.Hash, blockId);
        end else

        if DataType = TRANSFER_TRANSACTION then begin
          var Transfer: PTransfer := PData;
          var AddressFrom: TAddress := Transfer.SenderAddress;
          var AddressTo := Transfer.Data.AddressTo;
          const tokenId = Transfer.Data.TokenId;

          var V := FAssets[AddressFrom];
          V.SetNo(Transfer.Data.No);
          FBalances.DecTokenBalance(0 {TEC id}, AddressFrom, Transfer.Data.Fee);
          FBalances.DecTokenBalance(tokenId, AddressFrom, Transfer.Data.Amount);
          FBalances.IncTokenBalance(tokenId, AddressTo, Transfer.Data.Amount);
          FHashes.Add(Transfer.Hash, blockId);
        end else

        if DataType = STAKING_TRANSACTION then begin
          var Staking: PStaking := PData;
          var Address:Taddress := Staking.SenderAddress;

          var V := FAssets[Address];
          if V.FirstStaking = 0 then
            V.FirstStaking := Staking.Date;
          V.StakingInc(Staking.Data.Amount);
          V.SetNo(Staking.Data.No);

          FBalances.DecTokenBalance(0 {TEC id}, Address, Staking.Data.Fee);
//          FBalances.DecTokenBalance(0 {TEC id}, Address, Staking.Data.Amount);
          FHashes.Add(Staking.Hash, blockId);
        end else

        if DataType = UNSTAKING_TRANSACTION then begin
          var Unstaking: PUnstaking := PData;
          var Address:TAddress := Unstaking.SenderAddress;

          var V := FAssets[Address];
          V.StakingDec(Unstaking.Data.Amount);
          V.SetNo(Unstaking.Data.No);

          FBalances.DecTokenBalance(0 {TEC id}, Address, Unstaking.Data.Fee);
//          FBalances.IncTokenBalance(0 {TEC id}, Address, Unstaking.Data.Amount);
          FHashes.Add(Unstaking.Hash, blockId);
        end else

        if DataType = MIGRATE_TRANSACTION then begin
          var Migrate: PMigrate := PData;
          var Address:TAddress := Migrate.SenderAddress;

          FAssets[Address].SetNo(Migrate.Data.No);
          FBalances.DecTokenBalance(0 {TEC id}, Address, Migrate.Data.Amount);
          FBalances.IncTokenBalance(0 {TEC id}, Migrate.Data.AddressTo, Migrate.Data.Amount);
          FHashes.Add(Migrate.Hash, blockId);
        end else

        if DataType = VALIDATE1_TRANSACTION then begin
          var Validate1: PValidate1 := PData;
          var Address:TAddress := Validate1.SenderAddress;

          FAssets[Address].SetNo(Validate1.Data.No);
          var V := Validate1.Data.Validator;
          FAssets[V.Address].RewardInc(V.Reward);
          FBalances.IncTokenBalance(0 {TEC id}, V.Address, V.Reward);
        end else

        if DataType = VALIDATE4_TRANSACTION then begin
          var Validate4: PValidate4 := PData;
          Inc(FValid4TxCount);
          var Address:TAddress := Validate4.SenderAddress;

          FAssets[Address].SetNo(Validate4.Data.No);
          for var V in Validate4.Data.Validators do begin
            FBalances.IncTokenBalance(0 {TEC id}, V.Address, V.Reward);
            FAssets[V.Address].RewardInc(V.Reward);
          end;
          FLastBlockHash := Validate4.Hash();
          FHashes.Add(FLastBlockHash, blockId);
        end else

        if DataType = MINEBLOCK_TRANSACTION then begin
          var Block: PBlock := PData;
          var Address:TAddress := Block.SenderAddress;

          FBalances.IncTokenBalance(0 {TEC id}, Address, Block.Data.Reward);
          FHashes.Add(Block.Data.Hash, blockId);
          FAssets[Address].RewardInc(Block.Data.Reward);
          FBlocks.Add(blockId);
          FLastBlockHash := Block.Data.Hash;
        end else

        if DataType = VALIDATE_TRANSACTION then begin
          var Validate: PValidate := PData;
          var Address:TAddress := Validate.SenderAddress;

          FAssets[Address].SetNo(Validate.Data.No);
          FBalances.IncTokenBalance(0 {TEC id}, Address, Validate.Data.Reward);
          FAssets[Address].RewardInc(Validate.Data.Reward);
          FHashes.Add(Validate.Hash, blockId);
        end;
      end;
      Inc(FCacheIndex, UpdateAmount);
    until False;
  except on E:Exception do begin
      Logs.DoLog('Cache update exception: ' + E.Message, ERROR);
      Logs.DoLog('Cache index: ' + FCacheIndex.ToString, ERROR);
      Logs.DoLog('I = ' + I.ToString, ERROR);
      raise;
    end;
  end;
end;

function TCache.ToTransactionInfo(Index: UInt64; const Data: TBytes): TTransactionInfo;
begin
  Result := Default(TTransactionInfo);
  Result.Id := Index;

  var DataType := PDataType(Data)^;
  var PData := @Data[SizeOf(TDataType)];

  if DataType = MINT_TRANSACTION then begin
    var Mint: TMint := PData;

    Result.TxType := 'mint';
    Result.DateTime := Mint.Date;
    Result.No := Mint.No;
    Result.AddressFrom := EmptyAddress.AsString;
    Result.AddressTo := Mint.SenderAddress.AsString;
    Result.Amount := Mint.Amount;
    Result.IndexFrom := 0;
    Result.Fee := Mint.Fee;
    Result.Hash := Mint.Hash;
    Result.Name := Mint.Name;
    Result.Ticker := Mint.Ticker;
    Result.Decimals := Mint.Digits;
    Result.Description := Mint.Description;
    Result.IconURL := Mint.IconURL;
  end;

  if DataType = MINT_LIQUIDITY_TRANSACTION then begin
    var Mint: TLiquidityMint := PData;

    Result.TxType := 'mint';
    Result.DateTime := Mint.Date;
    Result.No := Mint.No;
    Result.AddressFrom := EmptyAddress.AsString;
    Result.AddressTo := Mint.SenderAddress.AsString;
    Result.Amount := Mint.Amount;
    Result.IndexFrom := Mint.Liquidity;
    Result.Fee := Mint.Fee;
    Result.Hash := Mint.Hash;
    Result.Name := Mint.Name;
    Result.Ticker := Mint.Ticker;
    Result.Decimals := Mint.Digits;
    Result.Description := Mint.Description;
    Result.IconURL := Mint.IconURL;
  end;

  if DataType = BURN_TOKEN_TRANSACTION then begin
    var Burn: TTokenBurn := PData;

    Result.TxType := 'burn';
    Result.DateTime := Burn.Date;
    Result.No := Burn.No;
    Result.AddressFrom := Burn.SenderAddress.AsString;
    Result.AddressTo := Burn.SenderAddress.AsString;
    Result.Amount := Burn.Amount;
    Result.IndexFrom := Burn.TokenID;
    Result.Fee := Burn.Fee;
    Result.Hash := Burn.Hash;
    Result.Ticker := GetTokenTicker(Burn.TokenID);
    Result.Decimals := GetTokenData(Result.Ticker, False).Digits;
  end;

  if DataType = TRANSFER_TRANSACTION then begin
    var Transfer: PTransfer := PData;

    Result.TxType := 'transfer';
    Result.DateTime := Transfer.Date;
    Result.No := Transfer.Data.No;
    Result.AddressFrom := Transfer.SenderAddress.AsString;
    Result.AddressTo := Transfer.Data.AddressTo.AsString;
    Result.Amount := Transfer.Data.Amount;
    Result.Fee := Transfer.Data.Fee;
    Result.Hash := Transfer.Hash;
    Result.Ticker := GetTokenTicker(Transfer.Data.TokenId);
    Result.Decimals := GetTokenData(Result.Ticker, False).Digits;
  end;

  if DataType = STAKING_TRANSACTION then begin
    var Staking: PStaking := PData;

    Result.TxType := 'stake';
    Result.DateTime := Staking.Date;
    Result.No := Staking.Data.No;
    Result.AddressFrom := Staking.SenderAddress.AsString;
    Result.AddressTo := Staking.SenderAddress.AsString;
    Result.Amount := Staking.Data.Amount;
    Result.Fee := Staking.Data.Fee;
    Result.Hash := Staking.Hash;
    Result.Ticker := 'TEC';
    Result.Decimals := 8;
  end;

  if DataType = UNSTAKING_TRANSACTION then begin
    var Unstaking: PUnstaking := PData;

    Result.TxType := 'unstake';
    Result.DateTime := Unstaking.Date;
    Result.No := Unstaking.Data.No;
    Result.AddressFrom := Unstaking.SenderAddress.AsString;
    Result.AddressTo := EmptyAddress.AsString;
    Result.Amount := Unstaking.Data.Amount;
    Result.Fee := Unstaking.Data.Fee;
    Result.Hash := Unstaking.Hash;
    Result.Ticker := 'TEC';
    Result.Decimals := 8;
  end;

  if DataType = MIGRATE_TRANSACTION then begin
    var Migrate: PMigrate := PData;

    Result.TxType := 'migrate';
    Result.DateTime := Migrate.Date;
    Result.No := Migrate.Data.No;
    Result.AddressFrom := Migrate.SenderAddress.AsString;
    Result.AddressTo := Migrate.Data.AddressTo.AsString;
    Result.Amount := Migrate.Data.Amount;
    Result.Hash := Migrate.Hash;
    Result.Ticker := 'TEC';
    Result.Decimals := 8;
  end;

  if DataType = VALIDATE1_TRANSACTION then begin
    var Validate1: PValidate1 := PData;

    Result.TxType := 'validate';
    Result.DateTime := Validate1.Date;
    Result.No := Validate1.Data.No;
    Result.AddressFrom := EmptyAddress.AsString;
    Result.AddressTo := Validate1.Data.Validator.Address.AsString;
    Result.Amount := Validate1.Data.Validator.Reward;
    Result.Hash := Validate1.Hash;
    Result.Ticker := 'TEC';
    Result.Decimals := 8;
  end;

  if DataType = VALIDATE4_TRANSACTION then begin
    var Validate4: PValidate4 := PData;

    Result.TxType := 'validate4';
    Result.DateTime := Validate4.Date;
    Result.No := Validate4.Data.No;
    Result.AddressFrom := EmptyAddress.AsString;
    Result.AddressTo := Validate4.Data.Validators[0].Address.AsString;
    Result.Amount := Validate4.Data.Validators[0].Reward;
    SetLength(Result.Rewards, 4);
    for var i := 0 to 3 do begin
      case Validate4.Data.Validators[i].ValidatorType of
        0: Result.Rewards[i].TypeName := 'v';
        1: Result.Rewards[i].TypeName := 'a';
      end;
      Result.Rewards[i].Address := Validate4.Data.Validators[i].Address;
      Result.Rewards[i].Amount := Validate4.Data.Validators[i].Reward;
    end;
    Result.Hash := Validate4.Hash;
    Result.Ticker := 'TEC';
    Result.Decimals := 8;
  end;

  if DataType = MINEBLOCK_TRANSACTION then begin
    var Block: PBlock := PData;
    Result.TxType := 'block';
    Result.DateTime := Block.Date;
    Result.AddressFrom := EmptyAddress.AsString;
    Result.AddressTo := Block.SenderAddress.AsString;
    const prevHash:string = Block.Data.PrevBlockHash;
    const Hash:string = Block.Data.Hash;
    try
      const PrevBlockInfo = GetBlockInfo(Block.Data.PrevBlockHash);
      Result.IndexFrom := PrevBlockInfo.IndexTo + 1;
    except
      on E:ENotFoundError do
        Result.IndexFrom := 0;
    end;
    Result.IndexTo := Block.Data.IndexTo;
    Result.Amount := Block.Data.Reward;
    Result.Hash := Block.Data.Hash;
    Result.Ticker := 'TEC';
    Result.Decimals := 8;
  end;

  if DataType = VALIDATE_TRANSACTION then begin
    var Validate: PValidate := PData;

    Result.TxType := 'validate';
    Result.DateTime := Validate.Date;
    Result.AddressFrom := EmptyAddress.AsString;
    Result.AddressTo := Validate.SenderAddress.AsString;
    Result.Amount := Validate.Data.Reward;
    Result.Hash := Validate.Hash;
    Result.Ticker := 'TEC';
    Result.Decimals := 8;
  end;
end;

function ToBlockInfo(Index: UInt64; const Data: TBytes): TBlockInfo;
begin
  Result := Default(TBlockInfo);
  Result.Id := Index;

  var DataType := PDataType(Data)^;
  var PData := @Data[SizeOf(TDataType)];

  if DataType = MINEBLOCK_TRANSACTION then begin
    var Block: PBlock := PData;
    Result.Nonce := Block.Data.Nonce;
    Result.IndexTo := Block.Data.IndexTo;
    Result.DateTime := Block.Date;
    Result.Address := Block.SenderAddress;
    Result.Reward := Block.Data.Reward;
    Result.StakeAmount := Block.Data.StakeAmount;
    Result.PrevHash := Block.Data.PrevBlockHash;
    Result.Hash := Block.Data.Hash;
  end
  else if DataType = VALIDATE4_TRANSACTION then begin
    var Val4: PValidate4 := PData;
    Result.Nonce := 0;
    Result.IndexTo := Index + 1;
    Result.DateTime := Val4.Date;
    Result.Address := Default(TAddress);
    Result.Reward := 0;
    Result.StakeAmount := 0;
    Result.PrevHash := Default(TBlockHash);
    Result.Hash := Val4.Hash();
  end;
end;

procedure TCache.EnumTxns(Proc: TTxFilterPredicate);
begin
  var Continued := True;
  var Data := FDatabase.ReadData(0, FDatabase.Count);
  for var I:= High(Data) downto 0 do
  begin
    var T := ToTransactionInfo(I, Data[I]);
    if not T.TxType.IsEmpty then
      Proc(T, Continued);
    if not Continued then begin
      Break;
    end;
  end;
end;

function TCache.GetTransactionIndexByHash(const TxHash: TBlockHash): Int64;
begin
  if not FHashes.TryGetValue(TxHash, Result) then
    Result := -1;
end;

function TCache.GetTransactionInfo(Index: Int64; const Data: TBytes): TTransactionInfo;
begin
  Result := ToTransactionInfo(Index, Data);
  if Result.TxType.IsEmpty then
    raise ENotFoundError.Create('Not found');
end;

function TCache.GetTransactionInfo(Index: Int64): TTransactionInfo;
begin
  if (Index =-1) or (Index >= FDatabase.Count) then
    raise ENotFoundError.Create('Not found');
  var Data := FDatabase.Read(Index);
  Result := GetTransactionInfo(Index, Data);
end;

function TCache.GetTransactionInfo(const TxHash: TBlockHash): TTransactionInfo;
begin
  Result := GetTransactionInfo(GetTransactionIndexByHash(TxHash));
end;

function TCache.GetBlockInfo(const Hash: TBlockHash): TBlockInfo;
begin
  var Index := GetTransactionIndexByHash(Hash);
  if Index =-1 then
    raise ENotFoundError.Create('Not found');
  var Data := FDatabase.Read(Index);
  Result := ToBlockInfo(Index, Data);
end;

function TCache.GetLastBlocksInfo(Skip, Count: Int64): TArray<TBlockInfo>;
begin
  Result := nil;
  for var Index := FBlocks.Count - 1 - Skip downto 0 do
  if Count > 0 then
  begin
    Dec(Count);
    var Data := FDatabase.Read(FBlocks[Index]);
    Result := Result + [ToBlockInfo(FBlocks[Index], Data)];
  end;
end;

function TCache.GetStakingDate(const Address: TAddress): TUnixTimestamp;
begin
  Result := FAssets[Address].FirstStaking;
end;

function TCache.GetLastBlockHash: TBlockHash;
begin
  Result := FLastBlockHash;
end;

function TCache.GetLastBlock: TBlock;
begin
  if FLastBlockHash.IsEmpty then
    Result := Default(TBlock)
  else begin
    var LastBlockIndex := GetTransactionIndexByHash(FLastBlockHash);
    Require(LastBlockIndex <> -1, 'Blockchain corrupted');
    var Data := FDatabase.ReadData(LastBlockIndex, 1)[0];
    var DataType := PDataType(Data)^;
    if DataType = MINEBLOCK_TRANSACTION then
      Result := PBlock(@Data[SizeOf(TDataType)])^
    else if DataType = VALIDATE4_TRANSACTION then begin
      //fake block to continue mining after last 4.0 validation
      Result := Default(TBlock);
      Result.Data.IndexTo := LastBlockIndex + 1;
      Result.Data.Hash := FLastBlockHash;
    end
    else
      raise ERequireException.Create('Blockchain corrupted', 0);
  end;
end;

{ TCache.TBalanceCache }
procedure TCache.TBalancesCache.FromBytes(const Bytes: TBytes; var Offset: Integer);
begin
  Clear;
  for var I := 0 to TCode.ValueOf<Integer>(Bytes, Offset) - 1 do begin
    var Key := TCode.ValueOf<TTokenAddressPair>(Bytes, Offset);
    var Value := TCode.ValueOf<Int64>(Bytes, Offset);
    AddOrSetValue(Key, Value);
  end;
end;

function TCache.TBalancesCache.DecTokenBalance(ATokenId: UInt64; AAddress: TAddress; Amount: TAmount): TAmount;
begin
  var PTokenBalance := Self[TTokenAddressPair.Create(ATokenId, AAddress)];
  Dec(PTokenBalance^, Amount);
  Result := PTokenBalance^;
end;

function TCache.TBalancesCache.IncTokenBalance(ATokenId: UInt64; AAddress: TAddress; Amount: TAmount): TAmount;
begin
  var PTokenBalance := Self[TTokenAddressPair.Create(ATokenId, AAddress)];
  Inc(PTokenBalance^, Amount);
  Result := PTokenBalance^;
end;

function TCache.TBalancesCache.ToBytes: TBytes;
begin
  Result := TCode.BytesOf<Integer>(Count);
  for var Pair in Self do
    Result := Result + TCode.BytesOf(Pair.Key) + TCode.BytesOf(Pair.Value);
end;

end.

