unit BlockChain.DataCache;

interface

uses
  BlockChain.Txn,
  BlockChain.Data,
  BlockChain.Address,
  Blockchain.Reward,
  System.Generics.Collections;

type
  TCacheDataName = (cdnIncStakeSum, cdnDecStakeSum, cdnBlockId, cdnIncBalance, cdnDecBalance);

  TDataCahe = class(TDictionary<string, UInt64>)
    function GetLastTxId([Ref] const AAddress: T20Bytes): UInt64;
    function GetStakeBalance([Ref] const AAddress: T20Bytes): UInt64;
    function GetTokenBalance([Ref] const AAddress: T20Bytes; ATokenId: UInt64 = 0): UInt64;
    procedure Init();
    procedure UpdateCache([Ref] const AAddress: T20Bytes; ADataName: TCacheDataName; AValue: UInt64;
      ATokenId: UInt64 = 0); overload;
    procedure UpdateCache([Ref] const ARwd: TMemBlock<TReward>); overload;
    procedure UpdateCache([Ref] const ATxn: TMemBlock<TTxn>; ATxId: UInt64); overload;
  end;

var
  DataCache: TDataCahe;

implementation

uses
  System.SysUtils;

function TDataCahe.GetLastTxId([Ref] const AAddress: T20Bytes): UInt64;
begin
  var Key: string := string(AAddress) + '~' + Ord(cdnBlockId).ToString + '~0';
  if not DataCache.TryGetValue(Key, Result) then
    Result := INVALID;
end;

function TDataCahe.GetStakeBalance([Ref] const AAddress: T20Bytes): UInt64;
begin
  var Key: string := string(AAddress) + '~' + Ord(cdnIncStakeSum).ToString + '~0';
  var Income: UInt64 := 0;
  DataCache.TryGetValue(Key, Income);

  Key := string(AAddress) + '~' + Ord(cdnDecStakeSum).ToString + '~0';
  var Spent: UInt64 := 0;
  DataCache.TryGetValue(Key, Spent);

  Assert(Income >= Spent, 'stake value < 0. address: ' + AAddress);
  Result := Income - Spent;
end;

function TDataCahe.GetTokenBalance([Ref] const AAddress: T20Bytes; ATokenId: UInt64): UInt64;
begin
  var Key: string := string(AAddress) + '~' + Ord(cdnIncBalance).ToString + '~' + ATokenId.ToString;
  var Income: UInt64 := 0;
  DataCache.TryGetValue(Key, Income);

  Key := string(AAddress) + '~' + Ord(cdnDecBalance).ToString + '~' + ATokenId.ToString;
  var Spent: UInt64 := 0;
  DataCache.TryGetValue(Key, Spent);

  Assert(Income >= Spent, 'token balance < 0. address: ' + AAddress + ' token:' + ATokenId.ToString);
  Result := Income - Spent;

  if ATokenId <> 0 then
    Exit;

  const LStaked = GetStakeBalance(AAddress);

  Assert(LStaked <= Result, 'staked more than balance. address: ' + AAddress + ' token:' + ATokenId.ToString);
  Result := Result - LStaked;
end;

procedure TDataCahe.Init;
begin
  Clear;
  // прочитаем балансы напрямую из блокчейна.
  const BlocksAmount = TMemBlock<TTxn>.RecordsCount(TTxn.FileName); // еще не определено
  begin
  end;
  if BlocksAmount = 0 then
    Exit;

  for var txnId := 0 to BlocksAmount - 1 do begin
    const Txn = TMemBlock<TTxn>.ReadFromFile(TTxn.FileName, txnId);
    UpdateCache(Txn, txnId);
  end;
end;

procedure TDataCahe.UpdateCache([Ref] const ARwd: TMemBlock<TReward>);
begin
  const LAccount = TMemBlock<TAccount>.ReadFromFile(TAccount.Filename, ARwd.Data.RecieverAddressId);
  UpdateCache(LAccount.Data.Address, cdnIncBalance, ARwd.Data.Amount, 0 {reward always TET})
end;

procedure TDataCahe.UpdateCache([Ref] const ATxn: TMemBlock<TTxn>; ATxId: UInt64);
begin
  case ATxn.Data.TxnType of
    TTxnType.txSend, TTxnType.txMigrate: begin
        UpdateCache(ATxn.Data.Sender.Address, cdnDecBalance, ATxn.Data.Amount, ATxn.Data.TokenId);
        UpdateCache(ATxn.Data.Receiver.Address, cdnIncBalance, ATxn.Data.Amount, ATxn.Data.TokenId);
      end;
    TTxnType.txStake:
      UpdateCache(ATxn.Data.Sender.Address, cdnIncStakeSum, ATxn.Data.Amount);
    TTxnType.txUnStake:
      UpdateCache(ATxn.Data.Sender.Address, cdnDecStakeSum, ATxn.Data.Amount);
  end;

  UpdateCache(ATxn.Data.Sender.Address, cdnDecBalance, ATxn.Data.Fee.Fee1, ATxn.Data.Fee.TokenFee1Id);
  UpdateCache(ATxn.Data.Sender.Address, cdnBlockId, ATxId);
  UpdateCache(ATxn.Data.Receiver.Address, cdnBlockId, ATxId);
end;

procedure TDataCahe.UpdateCache(const [Ref] AAddress: T20Bytes; ADataName: TCacheDataName; AValue, ATokenId: UInt64);
begin
  var Key: string := string(AAddress) + '~' + Ord(ADataName).ToString + '~' + ATokenId.ToString;
  var LValue: UInt64 := 0;
  TryGetValue(Key, LValue);

  case ADataName of
    cdnBlockId:
      LValue := AValue;
  else
    Inc(LValue, AValue);
  end;
  AddOrSetValue(Key, LValue);
end;

initialization

DataCache := TDataCahe.create;

finalization

DataCache.Free;

end.

