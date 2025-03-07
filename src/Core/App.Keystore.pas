unit App.Keystore;

interface

uses
  System.Classes,
  System.IOUtils,
  System.Math,
  System.DateUtils,
  System.SysUtils,
  System.Threading,
  App.Types,
  App.Exceptions,
  App.Intf,
  App.Logs,
  Blockchain.Address,
  ClpIAsymmetricCipherKeyPair,
  ClpIECPrivateKeyParameters,
  ClpIECPublicKeyParameters,
  ClpCryptoLibTypes,
  Crypto,
  WordsPool;

type
  TKeystore = class
  private const
    KeyFileExt = '.txt';
    KeysFolder = 'keys';
  private
    FKeysPath: string;
    FPrKey: string;
    FPubKey: string;
    FAddress: string;
    procedure SaveKeyFile(const FileName, SeedPhrase, PubKey, PrKey, Address: string);
    procedure ReadKeyFile(const FileName: string; out PubKey, PrKey: string);
    function GetKeyFileNameFor(const Address: string): string;
  public
    constructor Create;
    procedure GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
    procedure ReadKeys(const Address: string);
    function ChangePrivateKey(const PrKey: string): string;
    function DoRecoverKeys(ASeed: string; out APubKey: string;
      out APrKey: string; out AAddress: string): string;
    property PrKey: string read FPrKey;
    property PubKey: string read FPubKey;
    property Address: string read FAddress;
  end;

implementation

constructor TKeystore.Create;
begin
  FKeysPath := TPath.Combine(TPath.GetAppPath, KeysFolder);
  if not DirectoryExists(FKeysPath) then
    TDirectory.CreateDirectory(FKeysPath);
end;

procedure TKeystore.SaveKeyFile(const FileName, SeedPhrase, PubKey, PrKey, Address: string);
begin
  TFile.WriteAllText(FileName,
    'seed phrase:' + SeedPhrase + sLineBreak +
    'public key:' + PubKey + sLineBreak +
    'private key:' + PrKey + sLineBreak +
    'address:' + Address);
end;

procedure TKeystore.ReadKeyFile(const FileName: string; out PubKey, PrKey: string);
begin
  for var L in TFile.ReadAllLines(FileName) do
  if L.StartsWith('private key') then
    PrKey := L.Split([':'])[1]
  else if L.StartsWith('public key') then
    PubKey := L.Split([':'])[1];
end;

function TKeystore.GetKeyFileNameFor(const Address: string): string;
begin
  Result := TPath.Combine(FKeysPath, Address + KeyFileExt);
end;

procedure TKeystore.ReadKeys(const Address: string);
var
  Seed, RestoredKey: string;
begin

  var KeyFileName: string;

  if Address.IsEmpty then
  begin

    var Filenames := TDirectory.GetFiles(FKeysPath, '*' + KeyFileExt);

    if Length(Filenames) = 0 then begin
      GenNewKeys(Seed, FPrKey, FPubKey, FAddress);
      UI.DoMessage('No keys found. New keys generated and saved in the "keys" folder');
      Exit;
    end else
      KeyFileName := Filenames[0];

  end else
     KeyFileName := GetKeyFileNameFor(Address);

  ReadKeyFile(KeyFileName, FPubKey, FPrKey);

  Require(RestorePublicKey(FPrKey, RestoredKey) and (CompareText(RestoredKey, FPubKey) = 0),
    'Invalid key in file "' + ExtractFileName(KeyFileName) + '"');

  FAddress := RestoreAddressAsStr(FPubKey);

  UI.DoMessage('Keys from the file "' + ExtractFileName(KeyFileName) + '" successfully read');

end;

procedure TKeystore.GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
var
  Keys: IAsymmetricCipherKeyPair;
  BytesArray: TCryptoLibByteArray;
begin
  ASeedPhrase := GenSeedPhrase;
  GenECDSAKeysOnPhrase(ASeedPhrase, Keys);

  SetLength(BytesArray, 0);
  BytesArray := (Keys.Private as IECPrivateKeyParameters).D.ToByteArrayUnsigned;
  APrKey := BytesToHex(BytesArray).ToLower;
  BytesArray := (Keys.Public as IECPublicKeyParameters).Q.GetEncoded;
  APubKey := BytesToHex(BytesArray).ToLower;
  AAddress := RestoreAddressAsStr(APubKey);

  SaveKeyFile(GetKeyFileNameFor(AAddress), ASeedPhrase, APubKey, APrKey, AAddress);

end;

function TKeystore.ChangePrivateKey(const PrKey: string): string;
begin

  var PubKeyStr: string;

  if not RestorePublicKey(PrKey, PubKeyStr) then
    raise EKeyException.Create('Restore public key error', EKeyException.INVALID_KEY);

  Result := RestoreAddressAsStr(PubKeyStr);

  var KeyFileName := GetKeyFileNameFor(Result);

  if TFile.Exists(KeyFileName) then
    raise EKeyException.Create('Private key already exists', EKeyException.KEYFILE_EXISTS);

  SaveKeyFile(KeyFileName, '', PubKeyStr, PrKey, Result);

end;

function TKeystore.DoRecoverKeys(ASeed: string; out APubKey: string;
  out APrKey: string; out AAddress: string): string;
var
  Keys: IAsymmetricCipherKeyPair;
  BytesArray: TCryptoLibByteArray;
begin

  if (Length(ASeed.Split([' '])) <> 12) then
    raise EValidError.Create('incorrect seed phrase');

  GenECDSAKeysOnPhrase(ASeed, Keys);

  SetLength(BytesArray, 0);
  BytesArray := (Keys.Private as IECPrivateKeyParameters).D.ToByteArrayUnsigned;
  APrKey := BytesToHex(BytesArray).ToLower;
  BytesArray := (Keys.Public as IECPublicKeyParameters).Q.GetEncoded;
  APubKey := BytesToHex(BytesArray).ToLower;
  AAddress := RestoreAddressAsStr(APubKey);

end;

end.
