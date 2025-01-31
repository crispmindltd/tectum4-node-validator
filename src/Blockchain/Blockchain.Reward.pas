unit Blockchain.Reward;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Math,
  Blockchain.Data,
  Blockchain.Address;

type

  TRewardType = (rtValidatorReward, rtArchiverReward, rtSoftnoteMint);

  TReward = record
  class var
    FileName: string;
  public
    RewardType: TRewardType; // byte
    // SenderAddressId: UInt64; // link to TAddress
    RecieverAddressId: UInt64; // link to TAddress
    Amount: UInt64;
    TxnId: UInt64; // link to TTxn or 0
    // HashTransaction: THash; // link to TTXn
    // Previous: UInt64; // link to TAward for one operation
    PreviousHash: T32Bytes;
    class function NextId: UInt64; static;
  end;

  TRewardInfo = record
    TypeName: string;
    Address: string;
    Amount: UInt64;
    class operator Implicit(const Block: TMemBlock<TReward>): TRewardInfo;
  end;

  TRewardTotalInfo = record
    Amount: UInt64;
    FirstTxnId: UInt64;
    EndBlockIndex: UInt64;
    Days: Integer;
  end;

function GetRwd(FirstBlock: UInt64): TArray<TRewardInfo>;
function GetRewardTotalInfo(StartIndex: UInt64; AddressId: UInt64): TRewardTotalInfo;

implementation

function GetRwd(FirstBlock: UInt64): TArray<TRewardInfo>;
begin

  Result:=[];

  if FirstBlock=0 then Exit;
  if FirstBlock=INVALID then Exit;

  var LastBlock := FirstBlock + 4;

  var B:=TMemBlock<TReward>.ByteArrayFromFile(TReward.FileName,FirstBlock,LastBlock-FirstBlock);

  var BlockSize:=SizeOf(TReward);
  var TxnId: UInt64:=0;

  for var I:=0 to (Length(B) div BlockSize)-1 do
  begin
    var V: TMemBlock<TReward> := Copy(B,I*BlockSize,BlockSize);
    if TxnId=0 then TxnId:=V.Data.TxnId;
    if TxnId<>V.Data.TxnId then Break;
    Result:=Result+[V];
  end;

end;

function GetRewardTotalInfo(StartIndex: UInt64; AddressId: UInt64): TRewardTotalInfo;
begin

  Result:=Default(TRewardTotalInfo);

  Result.EndBlockIndex := TReward.NextId;

  var BlockSize:=SizeOf(TReward);

  while StartIndex<Result.EndBlockIndex do
  begin

    var BlocksCount := Min(100,Result.EndBlockIndex-StartIndex);

    var B:=TMemBlock<TReward>.ByteArrayFromFile(TReward.FileName,StartIndex,BlocksCount);

    for var I:=0 to BlocksCount-1 do
    begin

      var V: TMemBlock<TReward> := Copy(B,I*BlockSize,BlockSize);

      if (V.Data.RewardType=rtValidatorReward) and (V.Data.RecieverAddressId=AddressId) then
      begin
        Inc(Result.Amount,V.Data.Amount);
        if Result.FirstTxnId=0 then Result.FirstTxnId := V.Data.TxnId;
      end;

    end;

    Inc(StartIndex,BlocksCount);

  end;

end;

{ TReward }

class function TReward.NextId: UInt64;
begin
  Result := TMemBlock<TReward>.RecordsCount(TReward.FileName);
end;

class operator TRewardInfo.Implicit(const Block: TMemBlock<TReward>): TRewardInfo;
begin

  const rw = Block.Data;
  const ad = TMemBlock<TAccount>.ReadFromFile(TAccount.Filename,rw.RecieverAddressId);

  Result.Address := AddressToStr(ad.Data.Address);
  Result.Amount := rw.Amount;

  case rw.RewardType of
  rtValidatorReward: Result.TypeName := 'v';
  rtArchiverReward: Result.TypeName := 'a';
  rtSoftnoteMint: Result.TypeName := 'm';
  end;

end;

initialization

const ProgramPath = ExtractFilePath(ParamStr(0));

const ChainsDirPath = TPath.Combine(ProgramPath, 'chains');
if not DirectoryExists(ChainsDirPath) then
  TDirectory.CreateDirectory(ChainsDirPath);

const RewardPath = TPath.Combine(ChainsDirPath, 'reward.db');
if not TFile.Exists(RewardPath) then
  TFile.WriteAllText(RewardPath, '');

TReward.FileName := RewardPath;

end.

