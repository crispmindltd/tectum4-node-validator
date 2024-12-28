unit Blockchain.Reward;

interface

uses
  System.SysUtils,
  System.IOUtils,
  Blockchain.Data;

type

  TRewardType = (rtTxnFee, rtSoftnoteMint);

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

implementation

{ TReward }

class function TReward.NextId: UInt64;
begin
  Result := TMemBlock<TReward>.RecordsCount(TReward.FileName);
end;

initialization

const ProgramPath = ExtractFilePath(ParamStr(0));

const RewardPath = TPath.Combine(ProgramPath, 'reward.db');
if not TFile.Exists(RewardPath) then
  TFile.WriteAllText(RewardPath, '');

TReward.FileName := RewardPath;

end.

