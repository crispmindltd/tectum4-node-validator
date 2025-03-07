unit App.Core;

interface

uses
  System.Classes,
  System.IOUtils,
  System.Math,
  System.DateUtils,
  System.SysUtils,
  System.Threading,
  App.Constants,
  App.Exceptions,
  App.Intf,
  App.Types,
  App.Logs,
  App.Settings,
  App.Keystore,
  Blockchain.Data,
  Blockchain.DataCache,
  Blockchain.Txn,
  Blockchain.Validation,
  Blockchain.Address,
  Blockchain.Reward,
  Blockchain.Utils,
  Update.Core,
  Net.Data,
  Net.Core,
  Server.HTTP,
  Server.Types,
  Crypto;

type
  TAppCore = class(TInterfacedObject, IAppCore)
  private
    FSettings: TSettings;
    FNetCore: TNetCore;
    FHTTPServer: THTTPServer;
    FUpdate: TUpdateCore;
    FKeystore: TKeystore;
 private
    FRewardTotal: TRewardTotalInfo;
    FStates: TAppStates;
    function CheckAddress(const AHexAddress: string): Boolean;
    procedure InitBCFiles;
    function GetStates: TAppStates;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure Reset;
    function GetPrKey: string;
    function GetPubKey: string;
    function GetAddress: string;
    function DoRecoverKeys(ASeed: string; out APubKey: string;
      out APrKey: string; out AAddress: string): string;
    function GetBlocksCount: Int64;
    function GetNewTokenFee(AAmount: Int64; ADecimals: Integer): Integer;
    function DoTokenTransfer(AAddrFrom, AAddrTo: string; AAmount: UInt64; APrKey: string): string;
    function DoTokenMigrate(AAddrFrom, AAddrTo: string; AAmount: UInt64; APrKey: string): string;
    function DoTokenStake(AAddr: string; AAmount: UInt64; APrKey: string): string;
    function DoTokenUnstake(AAddr: string; AAmount: UInt64; APrKey: string): string;
    function GetTokenBalance(AAddress: string): UInt64;
    function GetStakingBalance(AAddress: string): UInt64;
    function GetStakingReward(AAddress: string): TRewardTotalInfo;
    function GetUserLastTransactions(AAddress: string; Skip,Count: Int64): TArray<TTransactionInfo>;
    function GetLastTransactions(Skip,Count: Int64): TArray<TTransactionInfo>;
    procedure GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
    procedure ChangePrivateKey(const PrKey: string);
    function DoValidation(const [Ref] ATxn: TMemBlock<TTxn>;
      out ASign: TMemBlock<TValidation>): Boolean;
    function ServerClientExists(const PubKey: T65Bytes): Boolean;
    procedure DoHalt(const Reason: string);

    function SendTransaction(ARequest: TBytes): TBytes;
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
  InitBCFiles;
  FNetCore := TNetCore.Create(FSettings);
  FUpdate := TUpdateCore.Create;
  FUpdate.UpdatesRef := 'https://raw.githubusercontent.com/crispmindltd/tectum4-node-release/refs/heads/main/update/lnode-updates.json';
  if FSettings.HTTPEnabled then
    FHTTPServer := THTTPServer.Create;
end;

destructor TAppCore.Destroy;
begin
  FHTTPServer.Free;
  FNetCore.Free;
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

procedure TAppCore.Start;
begin
  DataCache.Init;
  FRewardTotal := Default(TRewardTotalInfo);
  FKeystore.ReadKeys(FSettings.Address);
  if Assigned(FHTTPServer) then
    FHTTPServer.Start(FSettings.HTTPPort);
  FNetCore.Start;
  if FSettings.AutoUpdate then
    FUpdate.StartUpdate;
end;

procedure TAppCore.Stop;
begin
  if Assigned(FHTTPServer) then
    FHTTPServer.Stop;
  FNetCore.Stop;
end;

procedure TAppCore.Reset;
begin
  Stop;
  Start;
  UI.NotifyNewTETBlocks;
end;

function TAppCore.GetStates: TAppStates;
begin
  Result := FStates;
end;

procedure TAppCore.DoHalt(const Reason: string);
begin
  if not (TAppState.Halted in States) then
  begin
    Include(FStates, TAppState.Halted);
    UI.ShowException('Node stopped: ' + Reason,
    procedure
    begin
      UI.DoTerminate;
    end);
  end;
end;

function TAppCore.ServerClientExists(const PubKey: T65Bytes): Boolean;
begin
  Result := FNetCore.ServerClientExists(PubKey);
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
  FUpdate.StartUpdate;
end;

function TAppCore.SendTransaction(ARequest: TBytes): TBytes;
begin
  Result := FNetCore.SendRequestToAnyServer(NewTransactionCommandCode, ARequest);
end;

procedure TAppCore.SetBlockchainSynchronized(Synchronized: Boolean);
begin

  if Synchronized then
    Include(FStates, TAppState.Synchronized)
  else
    Exclude(FStates, TAppState.Synchronized);

  if TAppState.Synchronized in States then
    UI.NotifyNewTETBlocks;

end;

function TAppCore.GetNetStats: TNetStatistics;
begin
  Result.Servers := FNetCore.GetServerStats;
  Result.Clients := FNetCore.GetClientsStats;
end;

procedure TAppCore.InitBCFiles;
begin
  const ProgramPath = ExtractFilePath(ParamStr(0));
  const ChainsDirPath = TPath.Combine(ProgramPath, 'chains');
  if not DirectoryExists(ChainsDirPath) then
    TDirectory.CreateDirectory(ChainsDirPath);

  const AddressPath = TPath.Combine(ChainsDirPath, ConstStr.AddressChainFileName);
  if not TFile.Exists(AddressPath) then
    TFile.WriteAllText(AddressPath, '');
  TAccount.Filename := AddressPath;

  const TxnPath = TPath.Combine(ChainsDirPath, ConstStr.TxnFileName);
  if not TFile.Exists(TxnPath) then
    TFile.WriteAllText(TxnPath, '');
  TTxn.Filename := TxnPath;

  const RewardPath = TPath.Combine(ChainsDirPath, ConstStr.RewardFileName);
  if not TFile.Exists(RewardPath) then
    TFile.WriteAllText(RewardPath, '');
  TReward.FileName := RewardPath;

  const ValidationPath = TPath.Combine(ChainsDirPath, ConstStr.ValidationFileName);
  if not TFile.Exists(ValidationPath) then
    TFile.WriteAllText(ValidationPath, '');
  TValidation.FileName := ValidationPath;

end;

function TAppCore.DoRecoverKeys(ASeed: string; out APubKey: string;
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

function TAppCore.CheckAddress(const AHexAddress: string): Boolean;
const
  Acceptable = 'ABCDEFabcdef0123456789';
var
  i: Integer;
begin
  Result := False;
  if (Length(AHexAddress) <> 42) or (not AHexAddress.StartsWith('0x')) then
    exit;
  for i := 3 to Length(AHexAddress) do
    if Acceptable.IndexOf(AHexAddress[i]) = -1 then
      exit;
  Result := True;
end;

function TAppCore.DoTokenStake(AAddr: string; AAmount: UInt64; APrKey: string): string;
begin
  if not CheckAddress(AAddr) then
    raise EValidError.Create('invalid address');
  if Length(APrKey) <> 64 then
    raise EValidError.Create('invalid private key');

  var LTx:TMemBlock<TTxn> := CreateTx(AAddr, AAddr, AAmount, CalculateFee(AAmount), TTxnType.txStake, TET_Id, APrKey);

  Result := Crypto.BytesToHex(SendTransaction(LTx)).ToLower;

end;

function TAppCore.DoTokenUnstake(AAddr: string; AAmount: UInt64; APrKey: string): string;
begin
  if not CheckAddress(AAddr) then
    raise EValidError.Create('invalid address');
  if Length(APrKey) <> 64 then
    raise EValidError.Create('invalid private key');

  var LTx:TMemBlock<TTxn> := CreateTx(AAddr, AAddr, AAmount, CalculateFee(AAmount), TTxnType.txUnStake, TET_Id, APrKey);

  Result := Crypto.BytesToHex(SendTransaction(LTx)).ToLower;

end;

function TAppCore.DoTokenTransfer(AAddrFrom, AAddrTo: string; AAmount: UInt64;
  APrKey: string): string;
begin
  if not CheckAddress(AAddrFrom) then
    raise EValidError.Create('invalid address "from"');
  if not CheckAddress(AAddrTo) then
    raise EValidError.Create('invalid address "to"');
  if AAddrFrom.Equals(AAddrTo) then
    raise ESameAddressesError.Create('addresses match');

  if Length(APrKey) <> 64 then
    raise EValidError.Create('invalid private key');

  var LTx:TMemBlock<TTxn> := CreateTx(AAddrFrom, AAddrTo, AAmount, CalculateFee(AAmount), TTxnType.txSend, TET_Id, APrKey);

  Result := Crypto.BytesToHex(SendTransaction(LTx)).ToLower;

end;

function TAppCore.DoTokenMigrate(AAddrFrom, AAddrTo: string; AAmount: UInt64;
  APrKey: string): string;
begin
  if not CheckAddress(AAddrFrom) then
    raise EValidError.Create('invalid address "from"');
  if not CheckAddress(AAddrTo) then
    raise EValidError.Create('invalid address "to"');
  if AAddrFrom.Equals(AAddrTo) then
    raise ESameAddressesError.Create('addresses match');

  if Length(APrKey) <> 64 then
    raise EValidError.Create('invalid private key');

  var LTx:TMemBlock<TTxn> := CreateTx(AAddrFrom, AAddrTo, AAmount, {fee=} 0, TTxnType.txMigrate, TET_Id, APrKey);

  Result := Crypto.BytesToHex(SendTransaction(LTx)).ToLower;

end;

function TAppCore.DoValidation(const [Ref] ATxn: TMemBlock<TTxn>;
  out ASign: TMemBlock<TValidation>): Boolean;
begin
  Result := ATxn.Data.isSigned;
  if not Result then Exit;
  ASign := ATxn.Data.GetValidation(AppCore.PrKey);
end;

function TAppCore.GetBlocksCount: Int64;
begin
  Result:=TMemBlock<TTxn>.RecordsCount(TTxn.Filename);
end;

function TAppCore.GetNewTokenFee(AAmount: Int64; ADecimals: Integer): Integer;
begin
  if (AAmount < 1000) or (AAmount > 9999999999999999) then
    raise EValidError.Create('invalid amount value');
  if (ADecimals < 2) or (ADecimals > 8) then
    raise EValidError.Create('invalid decimals value');
  if Length(AAmount.ToString) + ADecimals > 18 then
    raise EValidError.Create('invalid decimals value');

  Result := Min((AAmount div (ADecimals * 10)) + 1, 10);
end;

function TAppCore.GetUserLastTransactions(AAddress: string; Skip,Count: Int64): TArray<TTransactionInfo>;
begin
  Result:=GetAccountTxns(AAddress, Skip,Count);
end;

function TAppCore.GetLastTransactions(Skip,Count: Int64): TArray<TTransactionInfo>;
begin
  Result:=GetTxns(Skip, Count);
end;

function TAppCore.GetTokenBalance(AAddress: string): UInt64;
begin
  Result := DataCache.GetTokenBalance(AAddress);
end;

function TAppCore.GetStakingBalance(AAddress: string): UInt64;
begin
  Result := DataCache.GetStakeBalance(AAddress);
end;

function TAppCore.GetStakingReward(AAddress: string): TRewardTotalInfo;
begin

  var R:=GetRewardTotalInfo(FRewardTotal.EndBlockIndex, TAccount.GetAddressId(AAddress));

  Inc(FRewardTotal.Amount, R.Amount);

  if FRewardTotal.FirstTxnId = 0 then FRewardTotal.FirstTxnId := R.FirstTxnId;

  FRewardTotal.EndBlockIndex := R.EndBlockIndex;

  var D := NowUTC;

  if FRewardTotal.FirstTxnId > 0 then
    D := TMemBlock<TTxn>.ReadFromFile(TTxn.Filename, FRewardTotal.FirstTxnId).Data.CreatedAt;

  FRewardTotal.Days := DaysBetween(D, NowUTC);

  Result := FRewardTotal;

end;

end.

