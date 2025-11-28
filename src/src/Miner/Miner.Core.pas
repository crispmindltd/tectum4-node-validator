unit Miner.Core;

interface

uses
  System.SysUtils,
  System.Threading,
  System.SyncObjs,
  System.Hash,
  System.Math,
  Database.Types,
  Blockchain.Data,
  Blockchain.Types,
  Blockchain.Core,
  Crypto.Types,
  App.Types,
  App.Logs,
  App.Intf,
  Miner.Utils;

type
  TMinerCore = class
  private
    FBlockchainCore: TBlockchainCore;
    FTask: ITask;
    FActive: Boolean;
    FSuspend: TEvent;
    FNonce: UInt64;
    procedure Suspend;
    procedure Resume;
    function Wait: Boolean;
  public
    constructor Create(BlockchainCore: TBlockchainCore);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure DataChange;
  end;

implementation

{ TMiner }

constructor TMinerCore.Create(BlockchainCore: TBlockchainCore);
begin
  FBlockchainCore := BlockchainCore;
  FActive := False;
  FSuspend := TEvent.Create;
end;

destructor TMinerCore.Destroy;
begin
  Stop;
  FSuspend.Free;
  inherited;
end;

procedure TMinerCore.DataChange;
begin
  if FActive then Resume;
end;

procedure TMinerCore.Suspend;
begin
  FSuspend.ResetEvent;
end;

procedure TMinerCore.Resume;
begin
  FSuspend.SetEvent;
end;

function TMinerCore.Wait: Boolean;
begin
  Result := FSuspend.WaitFor = wrSignaled;
end;

procedure TMinerCore.Start;
begin

  FActive := True;

  FTask := TTask.Run(procedure
  begin

    while Wait and FActive do
    try

      var RecordsCount: UInt64 := FBlockchainCore.RecordsCount;

      if RecordsCount = 0 then // blockchain is empty
      begin
        Suspend;
        Continue;
      end;

      var LastBlock := FBlockchainCore.GetLastBlock;
      var LastBlockAsString := 'none';
      var BlockData := Default(TBlockData);

      BlockData.PrevBlockHash := LastBlock.Data.Hash;

      var IndexFrom := UInt64(0);

      if not BlockData.PrevBlockHash.IsEmpty then
      begin
        IndexFrom := LastBlock.Data.IndexTo + 1;
        LastBlockAsString := string(BlockData.PrevBlockHash).Substring(0, 40) + '...';
      end;

      Logs.DoLog('Mining... (Last block: ' + LastBlockAsString + ')', INFO);

      BlockData.IndexTo := Min(RecordsCount - 1, IndexFrom + 1000);
      BlockData.StakeAmount := FBlockchainCore.StakingBalance(AppCore.Address);
      var Data := FBlockchainCore.ReadRawData(IndexFrom, BlockData.IndexTo - IndexFrom + 1);
      BlockData.Reward := FBlockchainCore.SumFee(Data);
      var Difficulty := CalcDifficulty(BlockData.StakeAmount);

      if BlockData.Reward = 0 then
      begin
        Suspend;
        Logs.DoLog('Mining suspended: No transactions', INFO);
      end else

        while FActive do
        begin

          if BlockData.PrevBlockHash <> FBlockchainCore.GetLastBlockHash then
          begin
            Logs.DoLog('Mining canceled: Last block changed', INFO);
            Break;
          end;

          BlockData.Nonce := FNonce;
          BlockData.Hash := GetNonceHash(BlockData.Nonce, Data);

          Inc(FNonce);

          if FNonce = FNonce.MaxValue then
            FNonce := FNonce.MinValue;

          if HashDifficulty(BlockData.Hash) < Difficulty then
          begin
            Suspend;
            Logs.DoLog('Mine success: ' + AppCore.DoMineBlock(BlockData), INFO);
            Break;
          end;

        end;

    except on E: Exception do
      Logs.DoLog('Mine exception: ' + E.Message, ERROR);
    end;

  end);

end;

procedure TMinerCore.Stop;
begin
  FActive := False;
  Resume;
  if Assigned(FTask) then FTask.Wait;
end;

end.
