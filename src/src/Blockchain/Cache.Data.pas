unit Cache.Data;

interface

uses
  System.SysUtils,
  App.DateUtils,
  Blockchain.Types;

type
  TAssets = record
    Staking: TAmount;
    Reward: TAmount;
    FirstStaking: TUnixTimestamp;
    No: UInt32;
    No2: UInt32;
    procedure StakingInc(const Value: TAmount);
    procedure StakingDec(const Value: TAmount);
    procedure RewardInc(const Value: TAmount);
    function IncNo: UInt32;
    procedure SetNo(const Value: UInt32);
  end;

  TOut = record
    Unstaking: TAmount;
    Stake: TAmount;
    No: UInt32;
    procedure UnstakingInc(const Value: TAmount);
    procedure StakingInc(const Value: TAmount);
    procedure MinNo(const Value: UInt32);
  end;

implementation

procedure TAssets.StakingInc(const Value: TAmount);
begin
  Staking := Staking + Value;
end;

procedure TAssets.StakingDec(const Value: TAmount);
begin
  Staking := Staking - Value;
end;

function TAssets.IncNo: UInt32;
begin
  if No2 < No then No2 := No;
  Inc(No2);
  Result := No2;
end;

procedure TAssets.RewardInc(const Value: TAmount);
begin
  Reward := Reward + Value;
end;

procedure TAssets.SetNo(const Value: UInt32);
begin
  No := Value;
  if No2 < No then No2 := No;
end;

{ TOut }
procedure TOut.StakingInc(const Value: TAmount);
begin
  Inc(Stake,  Value);
end;

procedure TOut.UnstakingInc(const Value: TAmount);
begin
  Inc(Unstaking, Value);
end;

procedure TOut.MinNo(const Value: UInt32);
begin
  if (No = 0) or (No > Value) then No := Value;
end;

end.
