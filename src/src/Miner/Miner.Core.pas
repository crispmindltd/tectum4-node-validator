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
  Randomize;
  FNonce := UInt64( Random(MaxInt) ) * Random(MaxInt);
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
    while Wait and FActive do begin
      try
        if FBlockchainCore.StakingBalance(AppCore.Address) < MINER_MIN_STAKE then begin
//          Logs.DoLog('Low stake for mining', INFO);
          Suspend;
          Continue;
        end;

        const RecordsCount: UInt64 = FBlockchainCore.RecordsCount;
        if RecordsCount = 0 then begin // blockchain is empty
          Suspend;
          Continue;
        end;

        var LastBlock := FBlockchainCore.GetLastBlock;
        var LastBlockAsString := 'none';
        var BlockData := Default(TBlockData);

        BlockData.PrevBlockHash := LastBlock.Data.Hash;

        var IndexFrom := UInt64(0);

        if not BlockData.PrevBlockHash.IsEmpty then begin
          IndexFrom := LastBlock.Data.IndexTo + 1;
          LastBlockAsString := string(BlockData.PrevBlockHash).Substring(0, 40) + '...';
        end;

        Logs.DoLog('Mining... (Last block: ' + LastBlockAsString + ')', INFO);

        const MAX_BLOCK_TX_COUNT = 100;
        BlockData.IndexTo := Min(RecordsCount - 1, IndexFrom + MAX_BLOCK_TX_COUNT - 1);
        BlockData.StakeAmount := FBlockchainCore.StakingBalance(AppCore.Address);
        const Data = FBlockchainCore.ReadRawData(IndexFrom, BlockData.IndexTo - IndexFrom + 1);
        BlockData.Reward := FBlockchainCore.SumFee(Data);
        const Difficulty = CalcDifficulty(BlockData.StakeAmount);

        if BlockData.Reward = 0 then begin
          Suspend;
          Logs.DoLog('Mining suspended: No transactions', INFO);
        end
        else
          while FActive do begin
            if RecordsCount <> FBlockchainCore.RecordsCount then begin
              Break;
            end;

            if BlockData.PrevBlockHash <> FBlockchainCore.GetLastBlockHash then begin
              Logs.DoLog('Mining canceled: Last block changed', INFO);
              Break;
            end;

            BlockData.Nonce := FNonce;
            BlockData.Hash := GetNonceHash(BlockData.Nonce, Data);

            Inc(FNonce);

            if FNonce = FNonce.MaxValue then
              FNonce := FNonce.MinValue;

            if HashDifficulty(BlockData.Hash) < Difficulty then begin
              Suspend;
              Logs.DoLog('Mine success: ' + AppCore.DoMineBlock(BlockData), INFO);
              Break;
            end;
          end;

      except on E: Exception do begin
          Logs.DoLog('Mine exception: ' + E.Message, ERROR);
          If FActive then
            Resume;
        end;
      end
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
