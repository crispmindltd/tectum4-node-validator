unit Blockchain.Txn;

interface

uses
  System.SysUtils,
  System.IOUtils,
  Crypto,
  Blockchain.Validation,
  Blockchain.Reward,
  Blockchain.Address,
  Blockchain.Data;

type

  TTxnType = (txSend, txStake, txUnStake { , txNewToken } );

  TTxnParty = record
    Address: T20Bytes;
    AddressId: UInt64;
    // Balance: Int64; // balance after tx
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
  private
    class operator Initialize(out Dest: TTxn);
  end;

procedure SaveBlock(var ATxn: TMemBlock<TTxn>);

procedure SaveValidatedBlock(var ATxn: TMemBlock<TTxn>; var AArchiver: TMemBlock<TValidation>;
  const AValidators: Tarray < TMemBlock < TValidation >> );

function CreateTx(const [Ref] ASenderAddr, AReceiverAddr: T20Bytes; AValue, AFee: UInt64; ATxnType: TTxnType; ATokenId: Integer;
  const [Ref] ASenderPrivKey: T32Bytes; isNeedSign: Boolean = True): TMemBlock<TTxn>;

implementation

uses
  Blockchain.DataCache;

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
  Result.Data.CreatedAt := Now();

  if isNeedSign then begin
    var PubKeyStr: string;
    Assert(RestorePublicKey(ASenderPrivKey, PubKeyStr));
    Result.Data.SenderPubKey := PubKeyStr;
    Result.Data.SignWithKey(ASenderPrivKey);
    Assert(Result.Data.isSigned());
  end;
end;

procedure SaveBlock(var ATxn: TMemBlock<TTxn>);
begin
  const TxId = TTxn.NextId;

  if TxId > 0 then begin
    ATxn.Data.PreviousHash := TMemBlock<TTxn>.LastHash(TTxn.Filename);
  end;

    // если получатель - новый адрес, то запишем его в цепочку.
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
    // эти поля уже заполнены !
    // Assert(AValidators[i].Data.SignerId > 0);
    // Assert(AValidators[i].Data.StartedAt > 0)
    // Assert(AValidators[i].Data.FinishedAt > 0);
    // Assert(AValidators[i].Data.SignerPubKey
    // Assert(AValidators[i].Data.Sign

    AValidator.Data.TxnId := TxId;
    AValidator.Data.PreviousHash := AValidator.LastHash(TValidation.FileName);
    AValidator.SaveToFile(TValidation.Filename);
  end;

begin
  // выполняется только на А13 поэтому проверки подписей уже не делаем.
  // делаем следующие проверки перед сохранением блока.

  // проверка корректного заполнения последнего блока
  const LSenderLastTxnId = DataCache.GetLastTxId(ATxn.Data.Sender.Address);
  Assert(LSenderLastTxnId = ATxn.Data.Sender.FromBlock);

  // проверка получателя не обязательна, уже сделано ранее валидаторами
  // const LReceiverLastTxnId = DataCache.GetLastTxId(ATxn.Data.Receiver.Address);
  // Assert(LReceiverLastTxnId = ATxn.Data.Receiver.FromBlock);

  // проверка достаточности баланса (пока предполагаю что токен один и тот же)
  if ATxn.Data.TxnType in [txSend, txStake] then begin
    const Balance = DataCache.GetTokenBalance(ATxn.Data.Sender.Address, ATxn.Data.TokenId);
    Assert(Balance >= (ATxn.Data.Amount + ATxn.Data.Fee.Fee1));
  end;

  // для анстейкинга свои проверки
  if ATxn.Data.TxnType = txUnStake then begin
    const Stake = DataCache.GetStakeBalance(ATxn.Data.Sender.Address);
    Assert(Stake > ATxn.Data.Amount);

    const Balance = DataCache.GetTokenBalance(ATxn.Data.Sender.Address, ATxn.Data.TokenId);
    Assert(Balance > ATxn.Data.Fee.Fee1);
  end;

  // если получатель - новый адрес, нет ли его уже в существующих.
  if ATxn.Data.Receiver.AddressId = INVALID then begin
    const AddrId = TAccount.GetAddressId(ATxn.Data.Receiver.Address);
    Assert(AddrId = INVALID);
  end;

  TxId := TTxn.NextId;
  const ValidationId = TValidation.NextId;
  const RewardId = TReward.NextId;

  var ValidatorStakes: Tarray<UInt64>;
  SetLength(ValidatorStakes, Length(AValidators));

  // теперь записать блоки валидации и вознаграждения.
  try
    SaveValidator(AArchiver);
    // заполним недостающие поля валидаторов
    for var I := 0 to high(AValidators) do begin
      SaveValidator(AValidators[I]);
      ValidatorStakes[I] := DataCache.GetStakeBalance(AValidators[I].Data.SignerPubKey.Address);
    end;

    const RewardValue = GetRewards(ATxn.Data.Fee.Fee1, ValidatorStakes);

    for var I := 0 to high(AValidators) do begin
      var LReward: TMemBlock<TReward>;
      LReward.Data.RewardType := rtTxnFee;
      LReward.Data.RecieverAddressId := //
        TAccount.GetAddressId(AValidators[I].Data.SignerPubKey.Address);
      LReward.Data.Amount := RewardValue[I];
      LReward.Data.TxnId := TxId;
      LReward.Data.PreviousHash := LReward.LastHash(TReward.FileName);
      LReward.SaveToFile(TReward.Filename);
      DataCache.UpdateCache(LReward);
    end;

    ATxn.Data.ValidationId := ValidationId;
    ATxn.Data.RewardId := RewardId;

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
  // надо бы провалидировать по настоящему ))
  var PubKey:string;
  Assert(RestorePublicKey(AValidatorPrivKey, PubKey));

  const AddressId = TAccount.GetAddressId( T65Bytes(PubKey).Address );
  Assert(AddressId <> INVALID);

  Result.Data.SignerId := AddressId;
  Result.Data.SignerPubKey := PubKey;
  Result.Data.Sign := CalculateSign(AValidatorPrivKey);
end;

function TTxn.CalculateSign(const [Ref] APrivKey: T32Bytes): TSign;
begin
  const LPrivKey: TBytes = APrivKey;
  Result := ECDSASignBytes(BytesToSign, LPrivKey); // implicit Assert
end;

class operator TTxn.Initialize(out Dest: TTxn);
begin
  FillChar(Dest, Sizeof(Dest), 0);
end;

function TTxn.isSigned(): Boolean;
begin
  Result := ECDSACheckBytesSign(BytesToSign, SenderSign, SenderPubKey);
end;

class function TTxn.NextId: UInt64;
begin
  Result := TMemBlock<TTxn>.RecordsCount(TTxn.Filename);
end;

procedure TTxn.SignWithKey(const [Ref] APrivKey: T32Bytes);
begin
  SenderSign := CalculateSign(APrivKey);
end;

initialization

const ProgramPath = ExtractFilePath(ParamStr(0));

const TxnPath = TPath.Combine(ProgramPath, 'txn.db');
if not TFile.Exists(TxnPath) then
  TFile.WriteAllText(TxnPath, '');

TTxn.Filename := TxnPath;

end.

