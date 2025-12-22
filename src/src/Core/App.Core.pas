unit App.Core;

interface

uses
  System.Classes,
  System.IOUtils,
  System.Math,
  System.DateUtils,
  System.SysUtils,
  System.Threading,
  App.Intf,
  App.Types,
  App.DateUtils,
  App.Logs,
  App.Settings,
  App.Keystore,
  Database.Types,
  Database.Core,
  Blockchain.Types,
  Blockchain.Core,
  Blockchain.Data,
  Update.Core,
  Net.Data,
  Net.Core,
  Web.Core,
  Crypto,
  Crypto.Types,
  Miner.Utils,
  Miner.Core;

type
  TAppCore = class(TInterfacedObject, IAppCore)
  private
    FSettings: TSettings;
    FNetCore: TNetCore;
    FWebCore: TWebCore;
    FUpdate: TUpdateCore;
    FKeystore: TKeystore;
    FBlockchainCore: TBlockchainCore;
    FMiner: TMinerCore;
 private
    FStates: TAppStates;
    function GetStates: TAppStates;
    procedure DataChange;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure Reset;
    function GetPrKey: string;
    function GetPubKey: string;
    function GetAddress: string;
    function DoTransaction(const Bytes: TBytes): TBytes;
    function DoValidation(const Bytes: TBytes): TBytes;
    function DoRecoverKeys(const ASeed: string; out APubKey: string;
      out APrKey: string; out AAddress: string): string;
    procedure GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
    procedure ChangePrivateKey(const PrKey: string);
    function CalculateFee(Amount: TAmount): TAmount;
    function CalculateMaxSendValue(Amount: TAmount): TAmount;
    function RecordsCount: Int64;
    function Valid4RecordsCount: Integer;
    function ReadRawData(StartIndex: Int64): TBytes;
    procedure WriteRawData(const Data: TBytes);
    function CreateMintRawTransaction(const Name, Ticker, Description: string; Digits: Byte; AAmount: TAmount; IsIconDefault: Boolean; const APrKey: string): TBytes;
    function CreateMintLiquidityRawTransaction(const Name, Ticker, Description: string; Digits: Byte; AAmount, ALiquidity: TAmount; IsIconDefault: Boolean; const APrKey: string): TBytes;
    function CreateBurnRawTransaction(const AAmount: TAmount; const ATokenID: UInt64; const APrKey: string): TBytes;
    function CreateTransferRawTransaction(const AAddrFrom, AAddrTo: string; AAmount: TAmount; const APrKey: string; TokenId: UInt64): TBytes;
    function CreateMigrateRawTransaction(const AAddrFrom, AAddrTo: string; AAmount: TAmount; const APrKey: string): TBytes;
    function CreateStakeRawTransaction(const AAddr: string; AAmount: TAmount; const APrKey: string): TBytes;
    function CreateUnstakeRawTransaction(const AAddr: string; AAmount: TAmount; const APrKey: string): TBytes;
    function CreateValidate40RawTransaction(const AAddr: string; TxHash: string; const Rewards: TArray<TRewardInfo>; const APrKey: string): TBytes;
    function CreateMineBlockRawTransaction(const BlockData: TBlockData): TBytes;
    function CreateValidateRawTransaction(const Data: TBytes; const ToHash: TBlockHash): TBytes;
    function DoTokenMint(const Name, Ticker, Description:string; Digits: Byte; AAmount, ALiquidity: TAmount; const IconBytes: TBytes; const APrKey: string): string;
    function DoTokenBurn(const AAmount: TAmount; const ATicker: string; const APrKey: string): string;
    function DoTokenTransfer(const AAddrFrom, AAddrTo: string; AAmount: TAmount; const APrKey: string; TokenId:Uint64): string;
    function DoTokenTransfers(const AAddrFrom: string; ATo: TArray<TTransferTo>; const APrKey: string): string;
    function DoTokenMigrate(const AAddrFrom, AAddrTo: string; AAmount: TAmount; const APrKey: string): string;
    function DoTokenStake(const AAddr: string; AAmount: TAmount; const APrKey: string): string;
    function DoTokenUnstake(const AAddr: string; AAmount: TAmount; const APrKey: string): string;
    function DoValidate40(const AAddr: string; TxHash: string; const Rewards: TArray<TRewardInfo>; const APrKey: string): string;
    function DoMineBlock(const BlockData: TBlockData): string;
    function DoSignedTransfer(const AAddrFrom, AAddrTo: string; AAmount: TAmount; const APrKey: string): string;
    function DoSendRawTransaction(const ATxHexBytes: string): string;
    function GetTokenBalance(const AAddress: string; TokenId:Uint64): TAmount;
    function GetTokenData(const Name: string; Required: Boolean = True): TToken;
    function GetTokensData: TArray<TToken>;
    function GetStakingBalance(const AAddress: string): TAmount;
    function GetRewardBalance(const AAddress: string): TAmount;
    function IncNo(const AAddress: string): UInt32;
    function GetStakingInfo(const AAddress: string): TStakingInfo;
    function GetUserLastTransactions(const AAddress: string; Skip, Count: Int64;
      Ticker: string = 'TEC'): TArray<TTransactionInfo>;
    function GetLastTransactions(Skip, Count: Int64): TArray<TTransactionInfo>;
    function GetTransactionInfo(Index: Int64): TTransactionInfo; overload;
    function GetTransactionInfo(const TxHash: string): TTransactionInfo; overload;
    function GetBlockInfo(const Hash: string): TBlockInfo;
    function GetLastBlocksInfo(Skip, Count: Int64): TArray<TBlockInfo>;
    procedure EnumTxns(Proc: TTxFilterPredicate);
    procedure DoHalt(const Reason: string);
    function SendTransaction(const Data: TBytes; PacketType: TNetPacketType = ptTransaction): string;
    procedure SetBlockchainSynchronized(Synchronized: Boolean);
    function GetNetStats: TNetStatistics;
    function GetAppVersion: string;
    function GetAppVersionText: string;
    procedure StartUpdate;
    property PrKey: string read GetPrKey;
    property PubKey: string read GetPubKey;
    property Address: string read GetAddress;
    property States: TAppStates read GetStates;
  end;

implementation

constructor TAppCore.Create;
begin
  FStates := [];
  FSettings := TSettings.Create;
  FKeystore := TKeystore.Create;
  Logs := TLog.Create(FSettings.LogsLevel);
  FBlockchainCore := TBlockchainCore.Create;
  FNetCore := TNetCore.Create(FSettings);
  FWebCore := TWebCore.Create;
  FUpdate := TUpdateCore.Create;
  FMiner := TMinerCore.Create(FBlockchainCore);
  FUpdate.UpdatesRef := 'https://raw.githubusercontent.com/crispmindltd/tectum4-node-test/refs/heads/main/update/lnode-updates.json';
end;

function TAppCore.CreateBurnRawTransaction(const AAmount: TAmount;
  const ATokenID: UInt64; const APrKey: string): TBytes;
begin
  const AddressFrom = TPrivateKey(APrKey).PublicKey.Address;
  const AddressStr = AddressFrom.AsString;
  var Burn := Default(TTokenBurn);
  Burn.No := IncNo(AddressStr);
  Burn.SenderAddress := AddressFrom;
  Burn.TokenID := ATokenID;
  Burn.Amount := AAmount;
  Burn.Fee := CalculateFee(AAmount);
  Burn.Date := TUnixTimestamp.Now;
  Burn.SignBy(APrKey);

  Result := TCode.BytesOf(BURN_TOKEN_TRANSACTION) + TBytes(Burn);
  var Len: TDataLength := Length(Result);
  Result := TCode.BytesOf(Len) + Result;
end;

destructor TAppCore.Destroy;
begin
  FMiner.Free;
  FWebCore.Free;
  FNetCore.Free;
  FBlockchainCore.Free;
  FSettings.Free;
  FKeystore.Free;
  FUpdate.Free;
  FreeAndNil(Logs);
  inherited;
end;

function TAppCore.GetPrKey: string;
begin
  Result := FKeystore.PrKey;
end;

function TAppCore.GetAddress: string;
begin
  Result := FKeystore.Address;
end;

function TAppCore.GetPubKey: string;
begin
  Result := FKeystore.PubKey;
end;

function TAppCore.GetRewardBalance(const AAddress: string): TAmount;
begin
  Require(not TAddress(AAddress).IsEmpty, 'invalid address');
  Result := FBlockchainCore.GetRewardBalance(AAddress);
end;

procedure TAppCore.Start;
begin
  FKeystore.ReadKeys(FSettings.Address);
  if FSettings.HTTPEnabled then
    FWebCore.Start(FSettings.HTTPPort);
  if FSettings.MinerEnabled then
    FMiner.Start;
  if FSettings.AutoUpdate then
    StartUpdate;
  FNetCore.Start;
end;

procedure TAppCore.Stop;
begin
  FMiner.Stop;
  FWebCore.Stop;
  FNetCore.Stop;
end;

function TAppCore.Valid4RecordsCount: Integer;
begin
  Result := FBlockchainCore.Valid4RecordsCount;
end;

procedure TAppCore.Reset;
begin
  Stop;
  Start;
  DataChange;
end;

function TAppCore.GetStates: TAppStates;
begin
  Result := FStates;
end;

procedure TAppCore.DataChange;
begin
  UI.DataChange;
  FMiner.DataChange;
end;

procedure TAppCore.DoHalt(const Reason: string);
begin
  if not (TAppState.Halted in States) then begin
    Include(FStates, TAppState.Halted);
    UI.ShowException('Node stopped: ' + Reason,
    procedure
    begin
      UI.DoTerminate;
    end);
  end;
end;

function TAppCore.GetAppVersion: string;
begin
  Result := FUpdate.AppVersion;
end;

function TAppCore.GetAppVersionText: string;
begin
  Result := GetAppVersion;
  var S := Result.Split(['.']);
  if Length(S) > 2 then Result := ''.Join('.', S, 0, 3);
  Result := Result + ' Beta';
end;

procedure TAppCore.StartUpdate;
begin

end;

function TAppCore.SendTransaction(const Data: TBytes; PacketType: TNetPacketType): string;
begin
  const response = FNetCore.SendRequestToAnyServer(PacketType, Data);
  Logs.DoLog(Format('response = [%s]', [BytesToHex(response)]), INFO);
  const hash = response;
  Logs.DoLog(Format('Incoming hash = %s', [BytesToHex(hash)]), INFO);
  Require(Length(hash) = 32, 'Invalid tx hash size in server`s answer.');
  Result := BytesToHex(hash).ToLower;
end;

procedure TAppCore.SetBlockchainSynchronized(Synchronized: Boolean);
begin
  if Synchronized then
    Include(FStates, TAppState.Synchronized)
  else
    Exclude(FStates, TAppState.Synchronized);

  if TAppState.Synchronized in States then
    DataChange;
end;

function TAppCore.GetNetStats: TNetStatistics;
begin
  Result.Servers := FNetCore.GetServerStats;
  Result.Clients := FNetCore.GetClientsStats;
end;

function TAppCore.DoTransaction(const Bytes: TBytes): TBytes;
begin
  Result := FBlockchainCore.DoTransaction(Bytes);
  DataChange;
end;

function TAppCore.DoValidation(const Bytes: TBytes): TBytes;
begin
  var ToHash := FBlockchainCore.DoValidation(Bytes);
  Result := Bytes + CreateValidateRawTransaction(Bytes, ToHash);
end;

function TAppCore.DoRecoverKeys(const ASeed: string; out APubKey: string;
  out APrKey: string; out AAddress: string): string;
begin
  Result := FKeystore.DoRecoverKeys(ASeed, APubKey, APrKey, AAddress);
end;

procedure TAppCore.GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
begin
  FKeystore.GenNewKeys(ASeedPhrase, APrKey, APubKey, AAddress);
end;

procedure TAppCore.ChangePrivateKey(const PrKey: string);
begin
  FSettings.Address := FKeystore.ChangePrivateKey(PrKey);
end;

function TAppCore.CalculateMaxSendValue(Amount: TAmount): TAmount;
begin
  if Amount <= 10000 then             Exit(0)
  else if Amount <= 10010000 then     Exit(Amount - 10000)
  else if Amount <= 100100000000 then Result := (Amount * 1000) div 1001
  else                                Result := Amount - _1_TEC;

  if Result + CalculateFee(Result) < Amount then Inc(Amount);
end;

function TAppCore.CalculateFee(Amount: TAmount): TAmount;
const
  MinFee = _1_TEC div 10000; // 0.0001 TEC
  MaxFee = _1_TEC;
begin
  Result := Amount div 1000;
  if Result < MinFee then      Result := MinFee
  else if Result > MaxFee then Result := MaxFee;
end;

function TAppCore.CreateMintLiquidityRawTransaction(const Name, Ticker,
  Description: string; Digits: Byte; AAmount, ALiquidity: TAmount;
  IsIconDefault: Boolean; const APrKey: string): TBytes;
begin
  const AddressFrom = TPrivateKey(APrKey).PublicKey.Address;
  const AddressStr = AddressFrom.AsString;
  var Mint := Default(TLiquidityMint);
  Mint.No := IncNo(AddressStr);
  Mint.Name := Name;
  Mint.Ticker := Ticker.ToUpper;
  Mint.Amount := AAmount;
  Mint.Liquidity := ALiquidity;
  Mint.Fee := 10 * _1_TEC;
  Mint.Digits := Digits;
  Mint.Description := Description;
  if IsIconDefault then
    Mint.IconURL := IconURLDomain + '/default.png'
  else
    Mint.IconURL := Format('%s/%s.png',[IconURLDomain,Ticker]).ToLower;
  Mint.Date := TUnixTimestamp.Now;
  Mint.SenderAddress := AddressFrom;
  Mint.SignBy(APrKey);

  Result := TCode.BytesOf(MINT_LIQUIDITY_TRANSACTION) + TBytes(Mint);
  var Len: TDataLength := Length(Result);
  Result := TCode.BytesOf(Len) + Result;
end;

function TAppCore.CreateMintRawTransaction(const Name, Ticker, Description: string;
  Digits: Byte; AAmount: TAmount; IsIconDefault: Boolean; const APrKey: string): TBytes;
begin
  const AddressFrom = TPrivateKey(APrKey).PublicKey.Address;
  const AddressStr = AddressFrom.AsString;
  var Mint := Default(TMint);
  Mint.No := IncNo(AddressStr);
  Mint.Name := Name;
  Mint.Ticker := Ticker.ToUpper;
  Mint.Amount := AAmount;
  Mint.Fee := 10 * _1_TEC;
  Mint.Digits := Digits;
  Mint.Description := Description;
  if IsIconDefault then
    Mint.IconURL := IconURLDomain + '/default.png'
  else
    Mint.IconURL := Format('%s/%s.png',[IconURLDomain,Ticker]).ToLower;
  Mint.Date := TUnixTimestamp.Now;
  Mint.SenderAddress := AddressFrom;
  Mint.SignBy(APrKey);

  Result := TCode.BytesOf(MINT_TRANSACTION) + TBytes(Mint);
  var Len: TDataLength := Length(Result);
  Result := TCode.BytesOf(Len) + Result;
end;

function TAppCore.CreateTransferRawTransaction(const AAddrFrom, AAddrTo: string; AAmount: TAmount;
  const APrKey: string; TokenId: UInt64): TBytes;
begin
  var RestoreAddress := TPrivateKey(APrKey).PublicKey.Address.AsString;
  Require(RestoreAddress = AAddrFrom, 'invalid address');

  var TransferData := Default(TTransferData);
  TransferData.No := IncNo(RestoreAddress);
  TransferData.AddressTo := AAddrTo;
  TransferData.Amount := AAmount;
  TransferData.Fee := CalculateFee(AAmount);
  TransferData.TokenId := TokenId;

  var Transfer := Default(TTransfer);
  Transfer.SenderAddress := AAddrFrom;
  Transfer.Data := TransferData;
  Transfer.Date := TUnixTimestamp.Now;
  Transfer.SignBy(APrKey);

  Result := TCode.BytesOf(TRANSFER_TRANSACTION) + TBytes(Transfer);
  var Len: TDataLength := Length(Result);
  Result := TCode.BytesOf(Len) + Result;
end;

function TAppCore.CreateMigrateRawTransaction(const AAddrFrom, AAddrTo: string; AAmount: TAmount;
  const APrKey: string): TBytes;
begin
  var RestoreAddress := TPrivateKey(APrKey).PublicKey.Address.AsString;
  Require(RestoreAddress = AAddrFrom, 'invalid address');

  var MigrateData := Default(TMigrateData);
  MigrateData.No := IncNo(RestoreAddress);
  MigrateData.AddressTo := AAddrTo;
  MigrateData.Amount := AAmount;

  var Migrate := Default(TMigrate);
  Migrate.SenderAddress := AAddrFrom;
  Migrate.Data := MigrateData;
  Migrate.Date := TUnixTimestamp.Now;
  Migrate.SignBy(APrKey);

  Result := TCode.BytesOf(MIGRATE_TRANSACTION) + TBytes(Migrate);
  var Len: TDataLength := Length(Result);
  Result := TCode.BytesOf(Len) + Result;
end;

function TAppCore.CreateStakeRawTransaction(const AAddr: string; AAmount: TAmount; const APrKey: string): TBytes;
begin
  var RestoreAddress := TPrivateKey(APrKey).PublicKey.Address.AsString;
  Require(RestoreAddress = AAddr, 'invalid address');

  var StakingData := Default(TStakingData);
  StakingData.No := IncNo(RestoreAddress);
  StakingData.Amount := AAmount;
  StakingData.Fee := CalculateFee(AAmount);

  var Staking := Default(TStaking);
  Staking.SenderAddress := AAddr;
  Staking.Data := StakingData;
  Staking.Date := TUnixTimestamp.Now;
  Staking.SignBy(APrKey);

  Result := TCode.BytesOf(STAKING_TRANSACTION) + TBytes(Staking);
  var Len: TDataLength := Length(Result);
  Result := TCode.BytesOf(Len) + Result;
end;

function TAppCore.CreateUnstakeRawTransaction(const AAddr: string; AAmount: TAmount; const APrKey: string): TBytes;
begin
  var RestoreAddress := TPrivateKey(APrKey).PublicKey.Address.AsString;
  Require(RestoreAddress = AAddr, 'invalid address');

  var UnstakingData := Default(TUnstakingData);
  UnstakingData.No := IncNo(RestoreAddress);
  UnstakingData.Amount := AAmount;
  UnstakingData.Fee := CalculateFee(AAmount);

  var Unstaking := Default(TUnstaking);
  Unstaking.SenderAddress := AAddr;
  Unstaking.Data := UnstakingData;
  Unstaking.Date := TUnixTimestamp.Now;
  Unstaking.SignBy(APrKey);

  Result := TCode.BytesOf(UNSTAKING_TRANSACTION) + TBytes(Unstaking);
  var Len: TDataLength := Length(Result);
  Result := TCode.BytesOf(Len) + Result;
end;

function TAppCore.CreateValidate40RawTransaction(const AAddr: string; TxHash: string;
  const Rewards: TArray<TRewardInfo>; const APrKey: string): TBytes;
begin
  var RestoreAddress := TPrivateKey(APrKey).PublicKey.Address.AsString;
  Require(RestoreAddress = AAddr, 'invalid address');

  if Length(Rewards) = 1 then begin
    Require(not Rewards[0].Address.IsEmpty, 'invalid address');

    var Validate1Data := Default(TValidate1Data);
    Validate1Data.No := IncNo(RestoreAddress);
    Validate1Data.TxHash := TxHash;
    Validate1Data.Validator.ValidatorType := 0;
    Validate1Data.Validator.Date.SetDateTime(Now, False);
    Validate1Data.Validator.Reward := Rewards[0].Amount;
    Validate1Data.Validator.Address := Rewards[0].Address;

    var Validate1 := Default(TValidate1);
    Validate1.SenderAddress := AAddr;
    Validate1.Data := Validate1Data;
    Validate1.Date := TUnixTimestamp.Now;
    Validate1.SignBy(APrKey);

    Result := TCode.BytesOf(VALIDATE1_TRANSACTION) + TBytes(Validate1);
    var Len: TDataLength := Length(Result);
    Result := TCode.BytesOf(Len) + Result;
  end
  else if Length(Rewards) = 4 then begin
    var Validate4Data := Default(TValidate4Data);
    Validate4Data.No := IncNo(RestoreAddress);
    Validate4Data.TxHash := TxHash;

    var Index := Integer(0);

    for var Reward in Rewards do begin
      Require(not Reward.Address.IsEmpty, 'invalid address');
      if Reward.TypeName = 'a' then
        Validate4Data.Validators[Index].ValidatorType := 0
      else
        Validate4Data.Validators[Index].ValidatorType := 1;
      Validate4Data.Validators[Index].Date.SetDateTime(Now, False);
      Validate4Data.Validators[Index].Address := Reward.Address;
      Validate4Data.Validators[Index].Reward := Reward.Amount;
      Inc(Index);
    end;

    var Validate4 := Default(TValidate4);
    Validate4.SenderAddress := AAddr;
    Validate4.Data := Validate4Data;
    Validate4.Date := TUnixTimestamp.Now;
    Validate4.SignBy(APrKey);

    Result := TCode.BytesOf(VALIDATE4_TRANSACTION) + TBytes(Validate4);
    var Len: TDataLength := Length(Result);
    Result := TCode.BytesOf(Len) + Result;
  end
  else
    App.Types.Stop('invalid rewards');
end;

function TAppCore.CreateMineBlockRawTransaction(const BlockData: TBlockData): TBytes;
begin
  // addr and prkey got from appcore properties
  var RestoreAddress := TPrivateKey(PrKey).PublicKey.Address.AsString;

  var Block := Default(TBlock);
  Block.SenderAddress := RestoreAddress;
  Block.Data := BlockData;
  Block.Date := TUnixTimestamp.Now;
  Block.SignBy(PrKey);

  Result := TCode.BytesOf(MINEBLOCK_TRANSACTION) + TBytes(Block);
  var Len: TDataLength := Length(Result);
  Result := TCode.BytesOf(Len) + Result;
end;

function TAppCore.CreateValidateRawTransaction(const Data: TBytes; const ToHash: TBlockHash): TBytes;
begin
  var Reward := FBlockchainCore.SumFee(Data);

  if Reward = 0 then Exit(nil);

  var Validate := Default(TValidate);
  Validate.SenderAddress := Address;

  Validate.Data.No := IncNo(Address);
  Validate.Data.ToHash := ToHash;
  Validate.Data.Reward := Reward;
  Validate.Date := TUnixTimestamp.Now;
  Validate.SignBy(PrKey);

  Result := TCode.BytesOf(VALIDATE_TRANSACTION) + TBytes(Validate);
  var Len: TDataLength := Length(Result);
  Result := TCode.BytesOf(Len) + Result;
end;

function TAppCore.DoTokenMint(const Name, Ticker, Description: string; Digits: Byte;
  AAmount, ALiquidity: TAmount; const IconBytes: TBytes; const APrKey: string): string;
begin
  var Data: TBytes;
  if ALiquidity = 0 then
    Data := CreateMintRawTransaction(Name, Ticker, Description, Digits, AAmount, Length(IconBytes) = 0, APrKey)
  else
    Data := CreateMintLiquidityRawTransaction(Name, Ticker, Description, Digits, AAmount, ALiquidity, Length(IconBytes) = 0, APrKey);

  var IconData: TIconData := Default(TIconData);
  IconData.Bytes := IconBytes;
  var RawIconData := TCode.BytesOf(TOKEN_ICON_DATA) + TBytes(IconData);
  var Len: TDataLength := Length(RawIconData);
  RawIconData := TCode.BytesOf(Len) + RawIconData;

  Data := Data + RawIconData;
  FBlockchainCore.DoValidation(Data);
  Result := SendTransaction(Data);
end;

function TAppCore.DoTokenTransfer(const AAddrFrom, AAddrTo: string; AAmount: TAmount;
  const APrKey: string; TokenId: UInt64): string;
begin
  var Data := CreateTransferRawTransaction(AAddrFrom, AAddrTo, AAmount, APrKey, TokenId);
  FBlockchainCore.DoValidation(Data);
  Result := SendTransaction(Data);
end;

function TAppCore.DoTokenTransfers(const AAddrFrom: string; ATo: TArray<TTransferTo>;
  const APrKey: string): string;
begin
  var Data := TBytes(nil);
  for var Item in ATo do
    Data := Data + CreateTransferRawTransaction(AAddrFrom, Item.Address, Item.Amount, APrKey, 0 {TEC id});
  FBlockchainCore.DoValidation(Data);
  Result := SendTransaction(Data);
end;

function TAppCore.DoTokenBurn(const AAmount: TAmount; const ATicker: string;
  const APrKey: string): string;
begin
  var TokenData := AppCore.GetTokenData(ATicker, True);
  var Data := CreateBurnRawTransaction(AAmount, TokenData.Id, APrKey);
  FBlockchainCore.DoValidation(Data);
  Result := SendTransaction(Data);
end;

function TAppCore.DoTokenMigrate(const AAddrFrom, AAddrTo: string; AAmount: TAmount;
  const APrKey: string): string;
begin
  var Data := CreateMigrateRawTransaction(AAddrFrom, AAddrTo, AAmount, APrKey);
  FBlockchainCore.DoValidation(Data);
  Result := SendTransaction(Data);
end;

function TAppCore.DoTokenStake(const AAddr: string; AAmount: TAmount; const APrKey: string): string;
begin
  var Data := CreateStakeRawTransaction(AAddr, AAmount, APrKey);
  FBlockchainCore.DoValidation(Data);
  Result := SendTransaction(Data);
end;

function TAppCore.DoTokenUnstake(const AAddr: string; AAmount: TAmount; const APrKey: string): string;
begin
  var Data := CreateUnstakeRawTransaction(AAddr, AAmount, APrKey);
  FBlockchainCore.DoValidation(Data);
  Result := SendTransaction(Data);
end;

function TAppCore.DoValidate40(const AAddr: string; TxHash: string; const Rewards: TArray<TRewardInfo>; const APrKey: string): string;
begin
  var Data := CreateValidate40RawTransaction(AAddr, TxHash, Rewards, APrKey);
  FBlockchainCore.DoValidation(Data);
  Result := SendTransaction(Data);
end;

{ example of call
begin
  var Rewards: TArray<TRewardInfo>;
  var A: TRewardInfo;
  A.TypeName :='a';
  A.Address := '0xbe07ae854e6a72bac492674a06ad6990bd228041';
  A.Amount := 450;

  var V: TRewardInfo;
  V.TypeName :='v';
  V.Address := '0xe38465d9ea628bbe533067e0395f66212b723873';
  V.Amount := 290;

  Rewards := [A, V, V, V];
  AppCore.DoValidate40(AppCore.Address, '5b1e1f8d5df5238ad41ad3aa5e85175e5a5c9f515d74e6fc4b2311619d793dee', Rewards, AppCore.PrKey);
end;
}

function TAppCore.DoMineBlock(const BlockData: TBlockData): string;
begin
  var Data := CreateMineBlockRawTransaction(BlockData);
  FBlockchainCore.DoValidation(Data);
  Result := SendTransaction(Data);
end;

function TAppCore.DoSignedTransfer(const AAddrFrom, AAddrTo: string; AAmount: TAmount; const APrKey: string): string;
begin
  var Data := CreateTransferRawTransaction(AAddrFrom, AAddrTo, AAmount, APrKey, 0 {TEC id});
  FBlockchainCore.DoValidation(Data);
  Result := BytesToHex(Data).ToLower;
end;

function TAppCore.DoSendRawTransaction(const ATxHexBytes: string): string;
begin
  var Data := HexToBytes(ATxHexBytes);
  FBlockchainCore.DoValidation(Data);
  Result := SendTransaction(Data);
end;

function TAppCore.RecordsCount: Int64;
begin
  Result := FBlockchainCore.RecordsCount;
end;

function TAppCore.ReadRawData(StartIndex: Int64): TBytes;
begin
  Result := FBlockchainCore.ReadRawData(StartIndex);
end;

procedure TAppCore.WriteRawData(const Data: TBytes);
begin
  FBlockchainCore.WriteRawData(Data);
end;

function TAppCore.GetStakingInfo(const AAddress: string): TStakingInfo;
begin
  Result := FBlockchainCore.GetStakingInfo(AAddress);
end;

function TAppCore.GetUserLastTransactions(const AAddress: string; Skip, Count: Int64;
  Ticker: string): TArray<TTransactionInfo>;
begin
  var A := Result;
  var C := Int64(0);
  FBlockchainCore.EnumTxns(procedure (const Tx: TTransactionInfo; var Continued: Boolean)
  begin
    if ((Tx.AddressFrom = AAddress) or (Tx.AddressFrom = Copy(AAddress, 3, Length(Address))) or
    (Tx.AddressTo = AAddress) or (Tx.AddressTo = Copy(AAddress, 3, Length(Address)))) and
    ((Tx.Ticker = Ticker) or ((Tx.TxType = 'burn') and (Ticker = 'TEC'))) then begin
      Inc(C);
      if C <= Skip then else
      if C > Skip + Count then
        Continued := False
      else
        A := A + [Tx];
    end;
  end);
  Result := A;
end;

function TAppCore.GetLastTransactions(Skip, Count: Int64): TArray<TTransactionInfo>;
begin
  var A := Result;
  var C := Int64(0);

  FBlockchainCore.EnumTxns(procedure (const Tx: TTransactionInfo; var Continued: Boolean)
  begin
    if Tx.TxType.Equals('validate4') then begin
      if (Length(A) > 0) and (A[Length(A)-1].TxType.Equals('transfer')) then
        A[Length(A)-1].Rewards := Tx.Rewards;
    end else begin
      Inc(C);
      if C <= Skip then else
      if C > Skip + Count then
        Continued := False
      else
        A := A + [Tx];
    end;
  end);
  Result := A;
end;

function TAppCore.GetTransactionInfo(Index: Int64): TTransactionInfo;
begin
  Result := FBlockchainCore.GetTransactionInfo(Index);
end;

function TAppCore.GetTransactionInfo(const TxHash: string): TTransactionInfo;
begin
  Result := FBlockchainCore.GetTransactionInfo(TxHash);
end;

function TAppCore.GetBlockInfo(const Hash: string): TBlockInfo;
begin
  Result := FBlockchainCore.GetBlockInfo(Hash);
end;

function TAppCore.GetLastBlocksInfo(Skip, Count: Int64): TArray<TBlockInfo>;
begin
  Result := FBlockchainCore.GetLastBlocksInfo(Skip, Count);
end;

procedure TAppCore.EnumTxns(Proc: TTxFilterPredicate);
begin
  FBlockchainCore.EnumTxns(Proc);
end;

function TAppCore.GetTokenBalance(const AAddress: string; TokenId:Uint64): TAmount;
begin
  Require(not TAddress(AAddress).IsEmpty, 'invalid address');
  Result := FBlockchainCore.Balance(AAddress, TokenId);
end;

function TAppCore.GetTokenData(const Name: string; Required: Boolean): TToken;
begin
  Result := FBlockchainCore.GetTokenData(Name, Required);
end;

function TAppCore.GetTokensData: TArray<TToken>;
begin
  Result := FBlockchainCore.GetTokensData;
end;

function TAppCore.GetStakingBalance(const AAddress: string): TAmount;
begin
  Require(not TAddress(AAddress).IsEmpty, 'invalid address');
  Result := FBlockchainCore.StakingBalance(AAddress);
end;

function TAppCore.IncNo(const AAddress: string): UInt32;
begin
  Result := FBlockchainCore.IncNo(AAddress);
end;

end.
