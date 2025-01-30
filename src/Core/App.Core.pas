unit App.Core;

interface

uses
  Blockchain.Data,
  Blockchain.DataCache,
  Blockchain.Txn,
  Blockchain.Validation,
  Blockchain.Address,
  Blockchain.Reward,
  App.Constants,
  App.Exceptions,
  App.Intf,
  App.Logs,
  App.Settings,
  Update.Core,
  Classes,
  ClpIAsymmetricCipherKeyPair,
  ClpIECPrivateKeyParameters,
  ClpIECPublicKeyParameters,
  ClpCryptoLibTypes,
  Crypto,
  IOUtils,
  Math,
  Net.Client,
  Net.Data,
  Net.Server,
  Net.Socket,
  Server.HTTP,
  Server.Types,
  SyncObjs,
  SysUtils,
  WordsPool;

type
  TAppCore = class(TInterfacedObject, IAppCore)
  strict private
    FPrKey: string;
    FPubKey: string;
    FAddress: string;
  public

  private
    FSettings: TSettingsFile;
    FNodeServer: TNodeServer;
    FNodeClient: TNodeClient;
    FHTTPServer: THTTPServer;
    FUpdate: TUpdateCore;

    function CheckTickerName(const ATicker: string): Boolean;
    function CheckShortName(const AShortName: string): Boolean;
    function CheckAddress(const AHexAddress: string): Boolean;
    function Remove0x(AAddress: string): string;
    function SignTransaction(const AToSign: string; const APrivateKey: string): string;
    function IsURKError(const AText: string): Boolean;
    function CheckIncomingSign(const ATransBytes: TBytes): Boolean;
    function InitKeys: Boolean;
    procedure InitBCFiles;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Run;
    procedure Stop;
    procedure Reset;
    function GetPrKey: string;
    function GetPubKey: string;
    function GetAddress: string;
    function GetNodeServer: TNodeServer;
    function GetNeedAutoUpdate: Boolean;

    procedure GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
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
    function GetStakingReward(StartIndex: UInt64; AAddress: string): TRewardTotalInfo;
    function GetUserLastTransactions(AAddress: string; Skip,Count: Int64): TArray<TTransactionInfo>;
    function GetLastTransactions(Skip,Count: Int64): TArray<TTransactionInfo>;
    function TrySaveKeysToFile(APrivateKey: string): Boolean;
    procedure ChangePrivateKey(const PrKey: string);
    function DoValidation(const [Ref] ATxn: TMemBlock<TTxn>;
      out ASign: TMemBlock<TValidation>): Boolean;

    function DoRequestToArchivator(const ACommandCode: Byte; ARequest: TBytes): TBytes;

    function GetAppVersion: string;
    function GetAppVersionText: string;
    procedure StartUpdate;
    procedure WaitForStop;

    property PrKey: string read GetPrKey;
    property PubKey: string read GetPubKey;
    property Address: string read GetAddress;
    property NodeServer: TNodeServer read GetNodeServer;
    property NeedAutoUpdate: Boolean read GetNeedAutoUpdate;
  end;

implementation

{ TAppCore }

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

function TAppCore.CheckIncomingSign(const ATransBytes: TBytes): Boolean;
var
  IncomStr: string;
  Splitted: TArray<string>;
begin
  try
    IncomStr := TEncoding.ANSI.GetString(Copy(ATransBytes, 0, Length(ATransBytes) - 65));
    Splitted := IncomStr.Trim.Split([' '], '<', '>');
    Result := ECDSACheckTextSign(Splitted[0].Trim(['<','>']), Splitted[1],
      Copy(ATransBytes, Length(ATransBytes) - 65, 65));
  except
    Result := False;
  end;
end;

function TAppCore.CheckShortName(const AShortName: string): Boolean;
const
  Acceptable = 'QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm0123456789-., ';
var
  i: Integer;
begin
  Result := False;
  if (Length(AShortName) < 3) or (Length(AShortName) > 32) then
    exit;
  for i := 1 to Length(AShortName) do
    if Acceptable.IndexOf(AShortName[i]) = -1 then
      exit;
  Result := True;
end;

function TAppCore.CheckTickerName(const ATicker: string): Boolean;
const
  Acceptable = 'QWERTYUIOPASDFGHJKLZXCVBNM1234567890';
var
  i: Integer;
begin
  Result := False;
  if (Length(ATicker) < 3) or (Length(ATicker) > 8) or TryStrToInt(ATicker[1], i) then
    exit;
  for i := 1 to Length(ATicker) do
    if Acceptable.IndexOf(ATicker[i]) = -1 then
      exit;
  Result := True;
end;

constructor TAppCore.Create;
begin
  FSettings := TSettingsFile.Create;
  Logs := TLog.Create(FSettings.LogsLevel);
  InitBCFiles;
  FNodeServer := TNodeServer.Create;
  FNodeClient := TNodeClient.Create;
  FUpdate:=TUpdateCore.Create;
  FUpdate.UpdatesRef:='https://raw.githubusercontent.com/crispmindltd/tectum4-node-release/refs/heads/main/update/lnode-updates.json';

  if FSettings.EnabledHTTP then
    FHTTPServer := THTTPServer.Create;
end;

destructor TAppCore.Destroy;
begin
  FUpdate.Free;
  FNodeServer.Free;
  FHTTPServer.Free;
  FNodeClient.Free;
  FSettings.Free;
  FreeAndNil(Logs);

  inherited;
end;

function TAppCore.DoTokenStake(AAddr: string; AAmount: UInt64; APrKey: string): string;
begin
  if not CheckAddress(AAddr) then
    raise EValidError.Create('invalid address');
  if Length(APrKey) <> 64 then
    raise EValidError.Create('invalid private key');

  var LTx:TMemBlock<TTxn> := CreateTx(AAddr, AAddr, AAmount, CalculateFee(AAmount), TTxnType.txStake, TET_Id, APrKey);

  const Answer = DoRequestToArchivator(NewTransactionCommandCode, LTx);

  if Answer[0] = SuccessCode then
    Result := Crypto.BytesToHex(Copy(Answer, 1))
  else
    raise Exception.Create(TEncoding.ANSI.GetString(Answer));

end;

function TAppCore.DoTokenUnstake(AAddr: string; AAmount: UInt64; APrKey: string): string;
begin
  if not CheckAddress(AAddr) then
    raise EValidError.Create('invalid address');
  if Length(APrKey) <> 64 then
    raise EValidError.Create('invalid private key');

  var LTx:TMemBlock<TTxn> := CreateTx(AAddr, AAddr, AAmount, CalculateFee(AAmount), TTxnType.txUnStake, TET_Id, APrKey);

  const Answer = DoRequestToArchivator(NewTransactionCommandCode, LTx);

  if Answer[0] = SuccessCode then
    Result := Crypto.BytesToHex(Copy(Answer, 1))
  else
    raise Exception.Create(TEncoding.ANSI.GetString(Answer));
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

  const Answer = DoRequestToArchivator(NewTransactionCommandCode, LTx);

  if Length(Answer) = 0 then
    raise Exception.Create('no answer from archiever');

  if Answer[0] = SuccessCode then
    Result := Crypto.BytesToHex(Copy(Answer, 1))
  else
    raise Exception.Create(TEncoding.ANSI.GetString(Answer));

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

  const Answer = DoRequestToArchivator(NewTransactionCommandCode, LTx);

  if Answer[0] = SuccessCode then
    Result := Crypto.BytesToHex(Copy(Answer, 1))
  else
    raise Exception.Create(TEncoding.ANSI.GetString(Answer));

end;

function TAppCore.DoValidation(const [Ref] ATxn: TMemBlock<TTxn>;
  out ASign: TMemBlock<TValidation>): Boolean;
begin
  Result := ATxn.Data.isSigned;
  if not Result then Exit;

  ASign := ATxn.Data.GetValidation(AppCore.PrKey);
end;

function TAppCore.GetNeedAutoUpdate: Boolean;
begin
  Result := FSettings.AutoUpdate;
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

function TAppCore.GetNodeServer: TNodeServer;
begin
  Result := FNodeServer;
end;

function TAppCore.GetUserLastTransactions(AAddress: string; Skip,Count: Int64): TArray<TTransactionInfo>;
begin
  Result:=GetAccountTxns(AAddress,Skip,Count);
end;

function TAppCore.GetLastTransactions(Skip,Count: Int64): TArray<TTransactionInfo>;
begin
  Result:=GetTxns(Skip,Count);
end;

function TAppCore.GetTokenBalance(AAddress: string): UInt64;
begin
  Result := DataCache.GetTokenBalance(AAddress);
end;

function TAppCore.GetStakingBalance(AAddress: string): UInt64;
begin
  Result := DataCache.GetStakeBalance(AAddress);
end;

function TAppCore.GetStakingReward(StartIndex: UInt64; AAddress: string): TRewardTotalInfo;
begin
  Result:=GetRewardTotalInfo(StartIndex, TAccount.GetAddressId(FAddress));
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

function TAppCore.InitKeys: Boolean;
var
  Seed, Path, RestoredKey: string;
begin

  Path := TPath.Combine(ExtractFilePath(ParamStr(0)), 'keys');
  ForceDirectories(Path);

  const Address = FSettings.Address;

  if Address.IsEmpty then
  begin

    var Filenames := TDirectory.GetFiles(Path, '*.txt');

    if Length(Filenames) = 0 then begin
      GenNewKeys(Seed, FPrKey, FPubKey, FAddress);
      UI.DoMessage('No keys found. New keys generated and saved in the "keys" folder');
      Exit(True);
    end else
      Path := Filenames[0];

  end else
     Path := TPath.Combine(Path,Address+'.txt');

  try

    for var L in TFile.ReadAllLines(Path) do
      if L.StartsWith('private key') then
        FPrKey := L.Split([':'])[1]
      else if L.StartsWith('public key') then
        FPubKey := L.Split([':'])[1];

    Result := RestorePublicKey(FPrKey, RestoredKey) and (CompareText(RestoredKey, FPubKey) = 0);

  except
    Result:=False;
  end;

  if Result then
  begin
    FAddress := RestoreAddressAsStr(FPubKey);
    UI.DoMessage(Format('Keys from the file "%s" successfully read',[TPath.GetFileName(Path)]));
  end;

//  FAddress := '0xE38465D9EA628BBE533067E0395F66212B723873';
//  FPrKey := '5f6843e1a0da7c4507adb2cfc1451a11c4ab400b4acd3acbe1e548e015caeb16';
//  FPubKey := '048cc86cc39867c02e975d482e9e7a82e409a30a1f433b41e23279a58832b86af45a65a59d65d70178fea5164f5a51fca4498a2c79ae26084c7f581ac8aa504c6e';

end;

//procedure TAppCore.ChangePrivateKey(const PrKey: string);
//begin
//
//  var PubKeyStr: string;
//
//  if not RestorePublicKey(PrKey, PubKeyStr) then
//    raise Exception.Create('Restorte error');
//
//  const pubKey:T65Bytes = PubKeyStr;
//
//  const Address = AddressToStr(pubKey.address);
//
//  var KeyFile:=TPath.Combine(TPath.Combine(ExtractFilePath(ParamStr(0)), 'keys'),Address+'.txt');
//
//  if TFile.Exists(KeyFile) then
//    raise Exception.Create('Key file already exists');
//
//  TFile.WriteAllText(KeyFile, 'seed phrase:'+sLineBreak+
//    'public key:' + PubKey + sLineBreak+
//    'private key:' + PrKey + sLineBreak+
//    'address:' + Address);
//
//   FSettings.SetKeyFile(Address);
//
//end;

function TAppCore.IsURKError(const AText: string): Boolean;
begin
  Result := AText.StartsWith('URKError');
end;

function TAppCore.DoRecoverKeys(ASeed: string; out APubKey: string;
  out APrKey: string; out AAddress: string): string;
var
  FKeys: IAsymmetricCipherKeyPair;
  BytesArray: TCryptoLibByteArray;
begin
  if (Length(ASeed.Split([' '])) <> 12) then
    raise EValidError.Create('incorrect seed phrase');

  GenECDSAKeysOnPhrase(ASeed, FKeys);
  BytesArray := (FKeys.Public as IECPublicKeyParameters).Q.GetEncoded;
  SetLength(APubKey, Length(BytesArray) * 2);
  BinToHex(BytesArray, PChar(APubKey), Length(BytesArray));
  APubKey := PubKey.ToLower;
  AAddress := RestoreAddressAsStr(APubKey);

  SetLength(BytesArray, 0);
  APrKey := '';
  BytesArray := (FKeys.Private as IECPrivateKeyParameters).D.ToByteArrayUnsigned;
  SetLength(APrKey, Length(BytesArray) * 2);
  BinToHex(BytesArray, PChar(APrKey), Length(BytesArray));
  APrKey := APrKey.ToLower;
end;

function TAppCore.DoRequestToArchivator(const ACommandCode: Byte;
  ARequest: TBytes): TBytes;
begin
  Result := FNodeClient.DoRequestToArchiver(ACommandCode, ARequest);
end;

procedure TAppCore.GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
var
  Keys: IAsymmetricCipherKeyPair;
  BytesArray: TCryptoLibByteArray;
  SavingPath: string;
begin
  ASeedPhrase := GenSeedPhrase;
  GenECDSAKeysOnPhrase(ASeedPhrase, Keys);

  SetLength(BytesArray, 0);
  BytesArray := (Keys.Private as IECPrivateKeyParameters).D.ToByteArrayUnsigned;
  APrKey := BytesToHex(BytesArray).ToLower;
  BytesArray := (Keys.Public as IECPublicKeyParameters).Q.GetEncoded;
  APubKey := BytesToHex(BytesArray).ToLower;
  AAddress := RestoreAddressAsStr(APubKey);

  SavingPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'keys');
  if not DirectoryExists(SavingPath) then
    TDirectory.CreateDirectory(SavingPath);
  SavingPath := TPath.Combine(SavingPath, AAddress + '.txt');
  TFile.AppendAllText(SavingPath, 'seed phrase:' + ASeedPhrase + sLineBreak);
  TFile.AppendAllText(SavingPath, 'public key:' + APubKey + sLineBreak);
  TFile.AppendAllText(SavingPath, 'private key:' + APrKey + sLineBreak);
  TFile.AppendAllText(SavingPath, 'address:' + AAddress);
end;

procedure TAppCore.ChangePrivateKey(const PrKey: string);
begin

  var PubKeyStr: string;

  if not RestorePublicKey(PrKey, PubKeyStr) then
    raise EKeyException.Create('Restore public key error',EKeyException.INVALID_KEY);

  const Address = RestoreAddressAsStr(PubKeyStr);

  var KeyFile:=TPath.Combine(TPath.Combine(ExtractFilePath(ParamStr(0)), 'keys'),Address+'.txt');

  if TFile.Exists(KeyFile) then
    raise EKeyException.Create('Private key already exists',EKeyException.KEYFILE_EXISTS);

  TFile.WriteAllText(KeyFile, 'seed phrase:'+sLineBreak+
    'public key:' + PubKeyStr + sLineBreak+
    'private key:' + PrKey + sLineBreak+
    'address:' + Address);

   FSettings.SetAddress(Address);

end;

function TAppCore.GetPrKey: string;
begin
  Result := FPrKey;
end;

function TAppCore.GetAddress: string;
begin
  Result := FAddress;
end;

function TAppCore.GetPubKey: string;
begin
  Result := FPubKey;
end;

function TAppCore.Remove0x(AAddress: string): string;
begin
  if (Length(AAddress) > 40) and AAddress.StartsWith('0x') then
    Result := AAddress.Substring(2, Length(AAddress))
  else
    Result := AAddress;
end;

procedure TAppCore.Run;
var
  splt: TArray<string>;
begin
  try
    DataCache.Init;
    FSettings.Init;
    if not InitKeys then
      raise Exception.Create('Failed to read keys from file or it is invalid');
    splt := ListenTo.Split([':']);
    FNodeServer.Start(splt[0], splt[1].ToInteger);
    if Assigned(FHTTPServer) then
      FHTTPServer.Start(HTTPPort);
    FNodeClient.Start;
    if GetNeedAutoUpdate then
      FUpdate.StartUpdate;
  except
    on E:Exception do
    begin
      Logs.DoLog('Error starting node: ' + E.Message, CmnLvlLogs, ltError);
      Stop;
      raise;
    end;
  end;
end;

procedure TAppCore.Reset;
begin
  Stop;
  Run;
  UI.NotifyNewTETBlocks;
end;

function TAppCore.TrySaveKeysToFile(APrivateKey: string): Boolean;
var
  Path, PubKey: string;
begin
  Result := RestorePublicKey(APrivateKey, PubKey);
  if not Result then
    exit;

  Path := TPath.Combine(ExtractFilePath(ParamStr(0)), 'keys');
  if not DirectoryExists(Path) then
    TDirectory.CreateDirectory(Path);
  Path := TPath.Combine(Path, 'keys');
  Path := Format('%s_%s.txt', [Path, PubKey]);
  TFile.AppendAllText(Path, 'public key:' + PubKey + sLineBreak);
  TFile.AppendAllText(Path, 'private key:' + APrivateKey + sLineBreak);
end;

function TAppCore.SignTransaction(const AToSign: string; const APrivateKey: string): string;
var
  prKeyBytes: TBytes;
begin
  prKeyBytes := HexToBytes(APrivateKey);

  ECDSASignText(AToSign,prKeyBytes,Result);
end;

function TAppCore.GetAppVersion: string;
begin
  Result:=FUpdate.AppVersion;
end;

function TAppCore.GetAppVersionText: string;
begin
  Result:='v'+GetAppVersion+' beta';
end;

procedure TAppCore.StartUpdate;
begin
  FUpdate.StartUpdate;
end;

procedure TAppCore.Stop;
begin
  if Assigned(FHTTPServer) then
    FHTTPServer.Stop;
  FNodeClient.Stop;
  FNodeServer.Stop;
end;

procedure TAppCore.WaitForStop;
begin
  FNodeServer.WaitFor;
end;

end.
