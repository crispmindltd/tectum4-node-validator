unit App.Core;

interface

uses
  Blockchain.Data,
  Blockchain.DataCache,
  Blockchain.Txn,
  Blockchain.Validation,
  Blockchain.Address,
  App.Constants,
  App.Exceptions,
  App.Intf,
  App.Logs,
  App.Settings,
  App.Updater,
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
  private
    FSettings: TSettingsFile;
    FNodeServer: TNodeServer;
    FNodeClient: TNodeClient;
    FHTTPServer: THTTPServer;

    function CheckTickerName(const ATicker: string): Boolean;
    function CheckShortName(const AShortName: string): Boolean;
    function CheckAddress(const AHexAddress: string): Boolean;
    function Remove0x(AAddress: string): string;
    function SignTransaction(const AToSign: string; const APrivateKey: string): string;
    function IsURKError(const AText: string): Boolean;
    function CheckIncomingSign(const ATransBytes: TBytes): Boolean;
    function InitKeys: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Run;
    procedure Stop;
    function GetPrKey: string;
    function GetPubKey: string;
    function GetAddress: string;
    function GetNodeServer: TNodeServer;
    function GetNeedAutoUpdate: Boolean;

    procedure GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
    function DoRecoverKeys(ASeed: string; out APubKey: string;
      out APrKey: string; out AAddress: string): string;
//    function DoNewToken(AReqID, ASessionKey, AFullName, AShortName,
//      ATicker: string; AAmount: Int64; ADecimals: Integer): string;
    function GetNewTokenFee(AAmount: Int64; ADecimals: Integer): Integer;
    function DoTokenTransfer(AAddrFrom, AAddrTo: string; AAmount: UInt64;
      APrKey, APubKey: string): string;
    function DoTokenStake(AAddr: string; AAmount: UInt64; APrKey, APubKey: string): string;
    function GetTokenBalance(AAddress: string; out AFloatSize: Byte): UInt64;
    function TrySaveKeysToFile(APrivateKey: string): Boolean;
    function DoValidation(const ATransBytes: TBytes; out ASign: string): Boolean; overload;
    function DoValidation(const [Ref] ATxn: TMemBlock<TTxn>;
      out ASign: TMemBlock<TValidation>): Boolean; overload;

    function DoRequestToArchivator(const ACommandCode: Byte; ARequest: TBytes): TBytes;

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
  Logs := TLog.Create;
  FSettings := TSettingsFile.Create;
  FNodeServer := TNodeServer.Create;
  FNodeClient := TNodeClient.Create;
  if FSettings.EnabledHTTP then
    FHTTPServer := THTTPServer.Create;
end;

destructor TAppCore.Destroy;
begin
  FNodeServer.Free;
  FHTTPServer.Free;
  FNodeClient.Free;
  FSettings.Free;
  Logs.Free;

  inherited;
end;

function TAppCore.DoTokenStake(AAddr: string; AAmount: UInt64; APrKey, APubKey: string): string;
begin
  if not CheckAddress(AAddr) then
    raise EValidError.Create('invalid address "from"');
  if Length(APrKey) <> 64 then
    raise EValidError.Create('invalid private key');
  if Length(APubKey) <> 130 then
    raise EValidError.Create('invalid public key');

  var LTx:TMemBlock<TTxn> := CreateTx(AAddr, AAddr, AAmount, CalculateFee(AAmount), TTxnType.txStake, TET_Id, APrKey);

  assert(LTx.Data.SenderPubKey = apubkey);

  const Answer = DoRequestToArchivator(NewTransactionCommandCode, LTx);

  if Answer[0] = SuccessCode then begin
    Result := Crypto.BytesToHex(Copy(Answer, 1));
  end
  else begin
    Result := TEncoding.ANSI.GetString(Answer);
  end;

end;

function TAppCore.DoTokenTransfer(AAddrFrom, AAddrTo: string; AAmount: UInt64;
  APrKey, APubKey: string): string;
begin
  if not CheckAddress(AAddrFrom) then
    raise EValidError.Create('invalid address "from"');
  if not CheckAddress(AAddrTo) then
    raise EValidError.Create('invalid address "to"');
  if AAddrFrom.Equals(AAddrTo) then
    raise ESameAddressesError.Create('');

  if Length(APrKey) <> 64 then
    raise EValidError.Create('invalid private key');
  if Length(APubKey) <> 130 then
    raise EValidError.Create('invalid public key');


  var LTx:TMemBlock<TTxn> := CreateTx(AAddrFrom, AAddrTo, AAmount, CalculateFee(AAmount), TTxnType.txSend, TET_Id, APrKey);

  assert(LTx.Data.SenderPubKey = apubkey);

  const Answer = DoRequestToArchivator(NewTransactionCommandCode, LTx);
  // FNodeClient.DoRequestToArchiever(NewTransactionCommandCode, LTx);

  if Answer[0] = SuccessCode then begin
    Result := Crypto.BytesToHex(Copy(Answer, 1));
  end
  else begin
    Result := TEncoding.ANSI.GetString(Answer);
  end;

end;

function TAppCore.DoValidation(const [Ref] ATxn: TMemBlock<TTxn>;
  out ASign: TMemBlock<TValidation>): Boolean;
begin
  Result := ATxn.Data.isSigned;
  if not Result then Exit;

  ASign := ATxn.Data.GetValidation(AppCore.PrKey);

end;

function TAppCore.DoValidation(const ATransBytes: TBytes; out ASign: string): Boolean;
var
  IncomStr: string;
  Splitted: TArray<string>;
begin
  Result := CheckIncomingSign(ATransBytes);
  if not Result then
  begin
    ASign := 'URKError 41502';
    Exit;
  end;

  try
    IncomStr := TEncoding.ANSI.GetString(Copy(ATransBytes, 0, Length(ATransBytes) - 65));
    Splitted := IncomStr.Trim.Split([' '], '<', '>');
    ECDSASignText(Splitted[1], HexToBytes(FPrKey), ASign);
    ASign := ASign + ' ' + PubKey.ToLower;
  except
    on E:EFileNotExistsError do
      ASign := 'URKError 41503';
  end;
end;

function TAppCore.GetNeedAutoUpdate: Boolean;
begin
  Result := FSettings.AutoUpdate;
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

function TAppCore.GetTokenBalance(AAddress: string;
  out AFloatSize: Byte): UInt64;
begin
  if not CheckAddress(AAddress) then
    raise EValidError.Create('invalid address');

  Result := DataCache.GetTokenBalance(AAddress);
end;

function TAppCore.InitKeys: Boolean;
var
  SearchRec: TSearchRec;
  Lines: TArray<string>;
  Seed, Path, RestoredKey: string;
begin
  Result := False;
  Path := TPath.Combine(ExtractFilePath(ParamStr(0)), 'keys');
  if not DirectoryExists(Path) then
    TDirectory.CreateDirectory(Path);

  const Filenames = TDirectory.GetFiles(Path, '*.txt');

  if Length(Filenames) = 0 then begin
    GenNewKeys(Seed, FPrKey, FPubKey, FAddress);
    UI.DoMessage('No keys found. New keys generated and saved in the "keys" folder');
    Result := True;
  end
  else begin
    Path := Filenames[0];
    Lines := TFile.ReadAllLines(Path);
    try
      for var i := 0 to Length(Lines) - 1 do begin
        if Lines[i].StartsWith('private key') then
          FPrKey := Lines[i].Split([':'])[1]
        else if Lines[i].StartsWith('public key') then
          FPubKey := Lines[i].Split([':'])[1];
        if not(FPrKey.IsEmpty or FPubKey.IsEmpty) then
          break;
      end;
      Result := RestorePublicKey(FPrKey, RestoredKey) and (RestoredKey = FPubKey);
    except
      Result := False;
    end;

    if Result then
      FAddress := '0x' + FPubKey.Substring(Length(FPubKey) - 40, 40).ToLower;
  end;

  if Result then
    UI.DoMessage(Format('Keys from the file "%s.txt" successfully read', [FAddress]));
end;

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
  AAddress := '0x' + APubKey.Substring(Length(APubKey) - 40, 40).ToLower;

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
  Result := FNodeClient.DoRequestToArchiever(ACommandCode, ARequest);
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
  AAddress := '0x' + APubKey.Substring(Length(APubKey) - 40, 40).ToLower;

  SavingPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'keys');
  if not DirectoryExists(SavingPath) then
    TDirectory.CreateDirectory(SavingPath);
  SavingPath := TPath.Combine(SavingPath, AAddress + '.txt');
  TFile.AppendAllText(SavingPath, 'seed phrase:' + ASeedPhrase + sLineBreak);
  TFile.AppendAllText(SavingPath, 'public key:' + APubKey + sLineBreak);
  TFile.AppendAllText(SavingPath, 'private key:' + APrKey + sLineBreak);
  TFile.AppendAllText(SavingPath, 'address:' + AAddress);
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
    FSettings.Init;
    if not InitKeys then
      raise Exception.Create('Failed to read keys from file or it is invalid');
    splt := ListenTo.Split([':']);
    FNodeServer.Start(splt[0], splt[1].ToInteger);
    if Assigned(FHTTPServer) then
      FHTTPServer.Start(HTTPPort);
    FNodeClient.Start;
    Updater.Run;
  except
    on E:Exception do
    begin
      Logs.DoLog('Error starting node: ' + E.Message, ltError);
      Stop;
      raise;
    end;
  end;
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

procedure TAppCore.Stop;
begin
  FNodeServer.Stop;
  if Assigned(FHTTPServer) then
    FHTTPServer.Stop;
  FNodeClient.Stop;
end;

end.
