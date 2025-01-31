unit Blockchain.Txn;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.DateUtils,
  System.Hash,
  System.Math,
  Crypto,
  Blockchain.Validation,
  Blockchain.Reward,
  Blockchain.Address,
  Blockchain.Data;

type

  TTxnType = (txSend, txStake, txUnStake, txMigrate { , txNewToken } );

  TTxnParty = record
    Address: T20Bytes;
    AddressId: UInt64;
    FromBlock: UInt64; // previous tx
  end;

  TFee = record
    Fee1: Int64;
    TokenFee1Id: Integer; // link to  TToken
    Fee2: Int64;
    TokenFee2Id: Integer; // link to  TToken
    class operator Implicit(AFee: Int64): TFee;
  end;

  TTxn = record
  class var
    Filename: string;
  public
    TxnType: TTxnType;
    TokenId: Integer;
    Amount: Int64;
    Sender: TTxnParty;
    SenderPubKey: T65Bytes;
    Receiver: TTxnParty;
    Fee: TFee;
    CreatedAt: TDateTime;
    // -- signed up to here
    SenderSign: TSign;
    ValidationId: UInt64;
    RewardId: UInt64;
    Reserv: Int64;
    PreviousHash: T32Bytes;

    procedure SignWithKey(const [Ref] APrivKey: T32Bytes);
    function isSigned(): Boolean;
    function BytesToSign: TBytes;
    function CalculateSign(const [Ref] APrivKey: T32Bytes):TSign;
    function GetValidation(const [Ref] AValidatorPrivKey: T32Bytes):TMemBlock<TValidation>;
    class function NextId: UInt64; static;
    function TxnHash: string;
  end;

  TTransactionInfo = record
    DateTime: TDateTime;
    TxId: Int64;
    TxType: string;
    AddressFrom: string;
    AddressTo: string;
    Amount: Int64;
    Hash: string;
    Fee: Int64;
    RewardId: UInt64;
    Rewards: TArray<TRewardInfo>;
    class operator Implicit(const Block: TMemBlock<TTxn>): TTransactionInfo;
  end;

  TFilterPredicate = reference to procedure(const Trx: TTransactionInfo);

procedure SaveBlock(var ATxn: TMemBlock<TTxn>);

procedure SaveValidatedBlock(var ATxn: TMemBlock<TTxn>; var AArchiver: TMemBlock<TValidation>;
  const AValidators: Tarray < TMemBlock < TValidation >> );

function CreateTx(const [Ref] ASenderAddr, AReceiverAddr: T20Bytes; AValue, AFee: UInt64; ATxnType: TTxnType; ATokenId: Integer;
  const [Ref] ASenderPrivKey: T32Bytes; isNeedSign: Boolean = True): TMemBlock<TTxn>;

function GetAccountTxns(const [Ref] AAddress:T20Bytes; Skip,Count: Int64): TArray<TTransactionInfo>;
function GetTxns(Skip,Count: Int64): TArray<TTransactionInfo>;
procedure EnumTxns(Filter: TFilterPredicate);

implementation

uses
  Blockchain.DataCache,
  Blockchain.Utils;

function GetAccountTxns(const [Ref] AAddress:T20Bytes; Skip,Count: Int64): TArray<TTransactionInfo>;
begin

  var CurrentTxId:UInt64 := DataCache.GetLastTxId(AAddress);

  while (Count > 0) and (CurrentTxId <> INVALID) do begin

    const Block = TMemBlock<TTxn>.ReadFromFile(TTxn.Filename, CurrentTxId);

    if Skip > 0 then
      Dec(Skip)
    else begin
      var Item: TTransactionInfo:=Block;
      Item.TxId := CurrentTxId;
      Result := Result + [Item];
      Dec(Count);
    end;

    if Block.Data.Sender.Address = AAddress then begin
      CurrentTxId := Block.Data.Sender.FromBlock;
      Continue;
    end;
    if Block.Data.Receiver.Address = AAddress then begin
      CurrentTxId := Block.Data.Receiver.FromBlock;
      Continue;
    end;

    raise Exception.Create('Corrupted blockchain !');

  end;

end;

function GetTxns(Skip,Count: Int64): TArray<TTransactionInfo>;
begin

  var RecordCount:=TTxn.NextId;
  var StartIndex:=RecordCount;

  if StartIndex>Skip+Count then StartIndex:=StartIndex-(Skip+Count) else StartIndex:=0;
  if StartIndex+Count>RecordCount then Count:=RecordCount-StartIndex;

  Result:=[];

  if Count=0 then Exit;

  const Blocks = TMemBlock<TTxn>.ByteArrayFromFile(TTxn.Filename,StartIndex,Count);

  for var I := 0 to Count-1 do
  begin

    const Block: TMemBlock<TTxn> = Copy(Blocks, I*SizeOf(TTxn), SizeOf(TTxn));

    var Tx: TTransactionInfo := Block;

    Tx.TxId:=StartIndex+I;

    Result := [Tx] + Result;

  end;

end;

procedure EnumTxns(Filter: TFilterPredicate);
const ReadCount = 200;
begin

  const RecordCount = TMemBlock<TTxn>.RecordsCount(TTxn.Filename);
  var StartIndex := SafeSub(RecordCount,1);

  while StartIndex>=0 do
  begin

    var EndIndex := StartIndex;

    StartIndex := SafeSub(StartIndex, ReadCount);

    const Blocks = TMemBlock<TTxn>.ByteArrayFromFile(TTxn.Filename, StartIndex, EndIndex - StartIndex + 1);

    for var I := 0 to EndIndex - StartIndex do
    begin

      const Block: TMemBlock<TTxn> = Copy(Blocks, I*SizeOf(TTxn), SizeOf(TTxn));

      var Tx: TTransactionInfo := Block;

      Tx.TxId:=StartIndex+I;

      Filter(Tx);

    end;

    if StartIndex=0 then Break;

  end;

end;

function CreateTx(const [Ref] ASenderAddr, AReceiverAddr: T20Bytes; AValue, AFee: UInt64; ATxnType: TTxnType; ATokenId: Integer;
  const [Ref] ASenderPrivKey: T32Bytes; isNeedSign: Boolean = True): TMemBlock<TTxn>;
begin
  FillChar(Result, Sizeof(Result), 0);
  Result.Data.TxnType := ATxnType;
  Result.Data.TokenId := ATokenId;
  Result.Data.Amount := AValue;
  Result.Data.Sender.Address := ASenderAddr;
  Result.Data.Sender.AddressId := TAccount.GetAddressId(ASenderAddr);
  Result.Data.Sender.FromBlock := DataCache.GetLastTxId(ASenderAddr);
  Result.Data.Receiver.Address := AReceiverAddr;
  Result.Data.Receiver.AddressId := TAccount.GetAddressId(AReceiverAddr);
  Result.Data.Receiver.FromBlock := DataCache.GetLastTxId(AReceiverAddr);

  if AFee = INVALID then
    Result.Data.Fee := CalculateFee(AValue)
  else
    Result.Data.Fee := AFee;

  Result.Data.CreatedAt := NowUTC;

  const isSenderOwnerOfToken = (Result.Data.Sender.AddressId = 0);
  const isReceiverOwnerOfToken = (Result.Data.Receiver.AddressId = 0);

  Assert( (atxnType <> TTxnType.txMigrate) or isSenderOwnerOfToken or isReceiverOwnerOfToken,
    'Token owner must take part in migrate transaction!');

  if isNeedSign then begin
    var PubKeyStr: string;
    Assert(RestorePublicKey(ASenderPrivKey, PubKeyStr), 'can not restore pubkey from privkey when creating new tx');
    Result.Data.SenderPubKey := PubKeyStr;
    Result.Data.SignWithKey(ASenderPrivKey);
    Assert(Result.Data.isSigned(), 'error checking new tx`s sign');
  end;
end;

procedure SaveBlock(var ATxn: TMemBlock<TTxn>);
begin
  const TxId = TTxn.NextId;

  if TxId > 0 then begin
    ATxn.Data.PreviousHash := TMemBlock<TTxn>.LastHash(TTxn.Filename);
  end;

    // save new address to chain
  if ATxn.Data.Receiver.AddressId = INVALID then begin
    var LAcccount: TMemBlock<TAccount>;
    LAcccount.Data.Address := ATxn.Data.Receiver.Address;
    LAcccount.Data.TxId := TxId;
    LAcccount.Data.PreviousHash := LAcccount.LastHash(TAccount.Filename);
    LAcccount.SaveToFile(TAccount.Filename);
  end;

  ATxn.SaveToFile(TTxn.Filename);
  DataCache.UpdateCache(ATxn, TTxn.NextId - 1);
end;

procedure SaveValidatedBlock(var ATxn: TMemBlock<TTxn>; var AArchiver: TMemBlock<TValidation>;
  const AValidators: Tarray < TMemBlock < TValidation >> );
var
  TxId: UInt64;
  procedure SaveValidator(var AValidator: TMemBlock<TValidation>);
  begin
    AValidator.Data.TxnId := TxId;
    AValidator.Data.PreviousHash := AValidator.LastHash(TValidation.FileName);
    AValidator.SaveToFile(TValidation.Filename);
  end;

  procedure SaveReward(AAccountId:UInt64; AAmount:UInt64; ARewardType:TRewardType);
  begin
      var LReward: TMemBlock<TReward>;
      LReward.Data.RewardType := ARewardType;
      LReward.Data.RecieverAddressId := AAccountId;
      LReward.Data.Amount := AAmount;
      LReward.Data.TxnId := TxId;
      LReward.Data.PreviousHash := LReward.LastHash(TReward.FileName);
      LReward.SaveToFile(TReward.Filename);
      DataCache.UpdateCache(LReward);
  end;

begin
  const LSenderLastTxnId = DataCache.GetLastTxId(ATxn.Data.Sender.Address);
  Assert(LSenderLastTxnId = ATxn.Data.Sender.FromBlock, '(a13) incorrect FromBlock value for tx sender');

  // checking balance (assuming this is a TET tx)
  if ATxn.Data.TxnType in [TTxnType.txSend, TTxnType.txStake, TTxnType.txMigrate] then begin
    const Balance = DataCache.GetTokenBalance(ATxn.Data.Sender.Address, ATxn.Data.TokenId);
    Assert(Balance >= (ATxn.Data.Amount + ATxn.Data.Fee.Fee1), '(a13) insufficient funds for tx');
  end;

  // check before unstake
  if ATxn.Data.TxnType = TTxnType.txUnStake then begin
    const Stake = DataCache.GetStakeBalance(ATxn.Data.Sender.Address);
    Assert(Stake >= ATxn.Data.Amount, '(a13) not enough staked to unstake');

    const Balance = DataCache.GetTokenBalance(ATxn.Data.Sender.Address, ATxn.Data.TokenId);
    Assert(Balance + ATxn.Data.Amount >= ATxn.Data.Fee.Fee1, '(a13) insufficient funds for unstake fee');
  end;

  // check if the NEW address exists already
  if ATxn.Data.Receiver.AddressId = INVALID then begin
    const AddrId = TAccount.GetAddressId(ATxn.Data.Receiver.Address);
    Assert(AddrId = INVALID, '(a13) address already exists ' + ATxn.Data.Receiver.Address);
  end;

  TxId := TTxn.NextId;
  const ValidationId = TValidation.NextId;
  const RewardId = TReward.NextId;

  var ValidatorStakes: Tarray<UInt64>;
  SetLength(ValidatorStakes, Length(AValidators));

  // now save validation and reward blocks
  try
    SaveValidator(AArchiver);

    ATxn.Data.RewardId := INVALID;

    if ATxn.Data.TxnType <> TTxnType.txMigrate then begin

      for var I := 0 to high(AValidators) do begin
        SaveValidator(AValidators[I]);
        ValidatorStakes[I] := DataCache.GetStakeBalance(AValidators[I].Data.SignerPubKey.Address);
      end;

      const RewardValue = GetRewards(ATxn.Data.Fee.Fee1, ValidatorStakes);
      for var I := 0 to high(AValidators) do begin
        const LAccountId = TAccount.GetAddressId(AValidators[I].Data.SignerPubKey.Address);
        const RewardAmount = RewardValue[I];
        SaveReward(LAccountId, RewardAmount, rtValidatorReward);
      end;
      const LAccountId = TAccount.GetAddressId(AArchiver.Data.SignerPubKey.Address);
      const RewardAmount = ATxn.Data.Fee.Fee1;
      SaveReward(LAccountId, RewardAmount, rtArchiverReward);

      ATxn.Data.RewardId := RewardId;
    end;

    ATxn.Data.ValidationId := ValidationId;

    SaveBlock(ATxn);
  except
    on E: Exception do begin
      Writeln('Transaction save error. Cannot continue. Stop Node!');
      Halt;
    end;
  end;

end;

class operator TFee.Implicit(AFee: Int64): TFee;
begin
  FillChar(Result, Sizeof(Result), 0);
  Result.Fee1 := AFee;
end;

{ TTxn }

function TTxn.BytesToSign: TBytes;
begin
  const bytesLength = UInt64(@SenderSign) - UInt64(@Self);
  SetLength(Result, bytesLength);
  Move(Self, Result[0], bytesLength);
end;

function TTxn.GetValidation(const [Ref] AValidatorPrivKey: T32Bytes): TMemBlock<TValidation>;
begin
  // must validate in truth ))
  var PubKey:string;
  Assert(RestorePublicKey(AValidatorPrivKey, PubKey), 'cannot restore pubkey on create new validation');

  const ValidatorAddress = T65Bytes(PubKey).Address;
  const AddressId = TAccount.GetAddressId( ValidatorAddress );
  Assert(AddressId <> INVALID, 'validator`s address not found: ' + ValidatorAddress);

  Result.Data.SignerId := AddressId;
  Result.Data.SignerPubKey := PubKey;
  Result.Data.Sign := CalculateSign(AValidatorPrivKey);
end;

function TTxn.CalculateSign(const [Ref] APrivKey: T32Bytes): TSign;
begin
  const LPrivKey: TBytes = APrivKey;
  Result := ECDSASignBytes(BytesToSign, LPrivKey); // implicit Assert
end;

function TTxn.isSigned(): Boolean;
begin
  Result := ECDSACheckBytesSign(BytesToSign, SenderSign, SenderPubKey);
end;

class function TTxn.NextId: UInt64;
begin
  Result := TMemBlock<TTxn>.RecordsCount(TTxn.Filename);
end;

type
  TTxnHash = record
    TxnType: TTxnType;
    TokenId: Integer;
    Amount: Int64;
    AddressFrom: T20Bytes;
    AddressTo: T20Bytes;
    CreatedAt: TDateTime;
    SenderSign: TSign;
  end;

function TTxn.TxnHash: string;
var TxnHash: TTxnHash;
begin

  Assert(isSigned,'transaction is not signed');

  TxnHash.TxnType := TxnType;
  TxnHash.TokenId := TokenId;
  TxnHash.Amount := Amount;
  TxnHash.AddressFrom := Sender.Address;
  TxnHash.AddressTo := Receiver.Address;
  TxnHash.CreatedAt := CreatedAt;
  TxnHash.SenderSign := SenderSign;

  const LSHA2 = THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);

  LSHA2.Update(TxnHash, SizeOf(TTxnHash));

  Result := LSHA2.HashAsString;

end;

procedure TTxn.SignWithKey(const [Ref] APrivKey: T32Bytes);
begin
  SenderSign := CalculateSign(APrivKey);
end;

class operator TTransactionInfo.Implicit(const Block: TMemBlock<TTxn>): TTransactionInfo;
begin
  const tx = Block.Data;

  Result.DateTime := tx.CreatedAt;
  Result.TxId := 0;
  Result.AddressFrom := AddressToStr(tx.Sender.Address);
  Result.AddressTo := AddressToStr(tx.Receiver.Address);
  Result.Amount := tx.Amount;
  Result.Fee := tx.Fee.Fee1;
  Result.Hash := BytesToHex(Block.Hash).ToLower;
  Result.RewardId := tx.RewardId;

  case tx.TxnType of
    TTxnType.txSend: Result.TxType := 'transfer';
    TTxnType.txStake: Result.TxType := 'stake';
    TTxnType.txUnStake: Result.TxType := 'unstake';
    TTxnType.txMigrate: Result.TxType := 'migrate';
  end;

  //Result.Validations:=GetVns(tx.ValidationId);
  //Result.Rewards:=GetRwd(tx.RewardId);

end;

end.
