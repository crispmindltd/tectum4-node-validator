unit Crypto;

interface

uses
  SysUtils,
  SyncObjs,
  SbpBase58,

  HlpHashFactory,

  ClpBigInteger,
  ClpCryptoLibTypes,
  ClpIECKeyPairGenerator,
  ClpIAsymmetricCipherKeyPair,
  ClpIECPrivateKeyParameters,
  ClpIECPublicKeyParameters,
  ClpECKeyPairGenerator,
  ClpISigner,
  ClpIECC,
  ClpSignerUtilities,
  ClpIX9ECParameters,
  ClpSecureRandom,
  ClpISecureRandom,
  ClpCustomNamedCurves,
  ClpECDomainParameters,
  ClpIECDomainParameters,
  ClpIECKeyGenerationParameters,
  ClpECKeyGenerationParameters,
  ClpECPrivateKeyParameters,
  ClpECPublicKeyParameters,
  ClpIAsymmetricCipherKeyPairGenerator,
  ClpGeneratorUtilities,
  ClpConverters,
  ClpIIESCipher,
  ClpIESCipher,
  ClpIAsymmetricKeyParameter,
  ClpIBufferedBlockCipher,
  ClpIAesEngine,
  ClpIBlockCipherModes,
  ClpIECDHBasicAgreement,
  ClpIPascalCoinECIESKdfBytesGenerator,
  ClpIMac,
  ClpIPascalCoinIESEngine,
  ClpECDHBasicAgreement,
  ClpPascalCoinECIESKdfBytesGenerator,
  ClpDigestUtilities,
  ClpMacUtilities,
  ClpAesEngine,
  ClpBlockCipherModes,
  ClpPaddedBufferedBlockCipher,
  ClpPaddingModes,
  ClpIPaddingModes,
  ClpPascalCoinIESEngine,
  ClpIIESParameterSpec,
  ClpIESParameterSpec,
  ClpEncoders,
  ClpIParametersWithIV,
  ClpIBufferedCipher,
  ClpIDigest,
  ClpCipherUtilities,
  ClpParametersWithIV,
  ClpParameterUtilities,
  ClpArrayUtils;

const
  SigningAlgorithmECDSA = 'SHA-1withECDSA';
  SigningAlgo: string = SigningAlgorithmECDSA;
  CurveName: string = 'secp256k1';
  PKCS5_SALT_LEN = Int32(8);
  SALT_MAGIC_LEN = Int32(8);
  SALT_SIZE = Int32(8);
  SALT_MAGIC: string = 'Salted__';

//Sign
procedure GenECDSARandomKeys(out KeyPair: IAsymmetricCipherKeyPair);
procedure GenECDSAKeysOnPhrase(const Phrase: string; out KeyPair: IAsymmetricCipherKeyPair); overload;
procedure GenECDSAKeysOnPhrase(const Phrase: string; out PrivKey: string; out PubKey: string); overload;
function RestorePublicKey(const PrivKey: string; out PubKey: string): Boolean;

function RestoreAddress(const PubKeyStr: string; out HexAddrStr: string; const Prefix:string = ''): Boolean;

procedure ECDSASignText(const InputText: string; const PrivKey: TBytes; out Sign: string); overload;
procedure ECDSASignText(const InputText: string; const PrivKeyBase58: string; out Sign: string); overload;
function ECDSACheckTextSign(const InputText: string; const Sign: string; const PubKey: TBytes): Boolean; overload;
function ECDSACheckTextSign(const InputText: string; const Sign: string; const PubKeyBase58: string): Boolean; overload;

function ECDSASignBytes(const InputBytes: TBytes; const PrivKey: TBytes):TBytes;
function ECDSACheckBytesSign(const InputBytes: TBytes; const Sign: TBytes; const PubKey: TBytes): Boolean;

//Symmetric encryption
procedure ECDSAEncryptTextSymmetric(const InputText: string; const Password: string; out EncryptedText: string);
procedure ECDSAEncryptBytesSymmetric(const InputBytes: TBytes; const PasswordBytes: TBytes; out EncryptedBytes: TBytes);
procedure ECDSADecryptTextSymmetric(const EncryptedText: string; const Password: string; out DecryptedText: string);
procedure ECDSADecryptBytesSymmetric(const EncryptedBytes: TBytes; const PasswordBytes: TBytes; out DecryptedBytes: TBytes);

//Asymmetric encryption
procedure ECDSAEncryptTextAsymmetric(const InputText: string; const PubKey: string; out EncryptedText: string); overload;
procedure ECDSAEncryptTextAsymmetric(const InputText: string; const PubKey: IECPublicKeyParameters; out EncryptedBytes: TArray<Byte>); overload;
procedure ECDSAEncryptTextAsymmetric(const InputBytes: TArray<Byte>; const PubKey: IECPublicKeyParameters; out EncryptedBytes: TArray<Byte>); overload;
procedure ECDSADecryptTextAsymmetric(const EncryptedText: string; const PrivKey: string; out DecryptedText: string); overload;
procedure ECDSADecryptTextAsymmetric(const EncryptedBytes: TArray<Byte>; const PrivKey: IECPrivateKeyParameters; out DecryptedText: string); overload;
procedure ECDSADecryptTextAsymmetric(const EncryptedBytes: TArray<Byte>; const PrivKey: IECPrivateKeyParameters; out DecryptedBytes: TArray<Byte>); overload;

//Byte conversion functions
function HexToBytes(const HexStr: string): TBytes;
function BytesToHex(const Bytes: TBytes): string;

implementation

var LCS:TCriticalSection;

function HexToBytes(const HexStr: string): TBytes;
var
  i,k,j: Integer;
  d: string;
begin
  SetLength(Result, Length(HexStr) div 2);
  k := -1;
  j := 1;
  d := '**';
  for i := 1 to Length(HexStr) do
  begin
    d[j] := HexStr[i];
    Inc(j);
    if j > 2 then
    begin
      j := 1;
      Inc(k);
      Result[k] := StrToInt('$'+d);
    end;
  end;
end;

function BytesToHex(const Bytes: TBytes): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Length(Bytes)-1 do
    Result := Result + IntToHex(Bytes[i],2);
end;

function ECDSASignBytes(const InputBytes: TBytes; const PrivKey: TBytes):TBytes;
var
  FCurve: IX9ECParameters;
  domain: IECDomainParameters;
  D: TBigInteger;
  RegeneratedPrivateKey: IECPrivateKeyParameters;
  Signer: ISigner;
begin
  LCS.Enter;
  try
    FCurve := TCustomNamedCurves.GetByName(CurveName);
    domain := TECDomainParameters.Create(FCurve.Curve, FCurve.G, FCurve.N,
      FCurve.H, FCurve.GetSeed);
    try
      D := TBigInteger.Create(1, PrivKey);
      RegeneratedPrivateKey := TECPrivateKeyParameters.Create('ECDSA', D, domain);

      Signer := TSignerUtilities.GetSigner(SigningAlgo);
      Signer.Init(True, RegeneratedPrivateKey);
      Signer.BlockUpdate(InputBytes, 0, System.Length(InputBytes));
      Result := Signer.GenerateSignature();

    except
      Result := [];
    end;
  finally
    LCS.Leave
  end;
end;

procedure ECDSASignText(const InputText: string; const PrivKey: TBytes; out Sign: string); overload
var
  FCurve: IX9ECParameters;
  domain: IECDomainParameters;
  D: TBigInteger;
  RegeneratedPrivateKey: IECPrivateKeyParameters;
  Signer: ISigner;
  sigBytes: TBytes;
  &b: TCryptoLibByteArray;
begin
  LCS.Enter;
  try
    FCurve := TCustomNamedCurves.GetByName(CurveName);
    domain := TECDomainParameters.Create(FCurve.Curve, FCurve.G, FCurve.N,
      FCurve.H, FCurve.GetSeed);
    try
      D := TBigInteger.Create(PrivKey);
      RegeneratedPrivateKey := TECPrivateKeyParameters.Create('ECDSA', D, domain);

      &b := TEncoding.ANSI.GetBytes(InputText);
      Signer := TSignerUtilities.GetSigner(SigningAlgo);
      Signer.Init(True, RegeneratedPrivateKey);
      Signer.BlockUpdate(&b, 0, System.Length(&b));
      sigBytes := Signer.GenerateSignature();

      Sign := BytesToHex(sigBytes);
    except
      Sign := '';
      exit;
    end;
  finally
    LCS.Leave
  end;
end;

procedure ECDSASignText(const InputText: string; const PrivKeyBase58: string;
  out Sign: string);
begin
  ECDSASignText(InputText,Base58ToBytes(PrivKeyBase58),Sign);
end;

procedure GenECDSARandomKeys(out KeyPair: IAsymmetricCipherKeyPair);
var
  generator: IECKeyPairGenerator;
  FRandom: ISecureRandom;
  FCurve: IX9ECParameters;
  domain: IECDomainParameters;
  keygenParams: IECKeyGenerationParameters;
begin
  LCS.Enter;
  try
    FRandom := TSecureRandom.Create();
    FCurve := TCustomNamedCurves.GetByName(CurveName);
    domain := TECDomainParameters.Create(FCurve.Curve, FCurve.G, FCurve.N,
      FCurve.H, FCurve.GetSeed);
    generator := TECKeyPairGenerator.Create('ECDSA');
    keygenParams := TECKeyGenerationParameters.Create(domain, FRandom);
    generator.Init(keygenParams);

    KeyPair := generator.GenerateKeyPair();
  finally
    LCS.Leave
  end;
end;

procedure GenECDSAKeysOnPhrase(const Phrase: string; out KeyPair: IAsymmetricCipherKeyPair); overload;
var
  generator: IECKeyPairGenerator;
  FRandom: ISecureRandom;
  FCurve: IX9ECParameters;
  domain: IECDomainParameters;
  keygenParams: IECKeyGenerationParameters;
begin
  LCS.Enter;
  try
    FRandom := TSecureRandom.Create();
    FCurve := TCustomNamedCurves.GetByName(CurveName);
    domain := TECDomainParameters.Create(FCurve.Curve, FCurve.G, FCurve.N,
      FCurve.H, FCurve.GetSeed);
    generator := TECKeyPairGenerator.Create('ECDSA');
    keygenParams := TECKeyGenerationParameters.Create(domain, FRandom);
    generator.Init(keygenParams);

    KeyPair := generator.GeneratePhraseKeyPair(Phrase);
  finally
    LCS.Leave
  end;
end;

procedure GenECDSAKeysOnPhrase(const Phrase: string; out PrivKey: string; out PubKey: string);
var
  generator: IECKeyPairGenerator;
  FRandom: ISecureRandom;
  FCurve: IX9ECParameters;
  domain: IECDomainParameters;
  keygenParams: IECKeyGenerationParameters;
  KeyPair: IAsymmetricCipherKeyPair;
begin
  LCS.Enter;
  try
    FRandom := TSecureRandom.Create();
    FCurve := TCustomNamedCurves.GetByName(CurveName);
    domain := TECDomainParameters.Create(FCurve.Curve, FCurve.G, FCurve.N,
      FCurve.H, FCurve.GetSeed);
    generator := TECKeyPairGenerator.Create('ECDSA');
    keygenParams := TECKeyGenerationParameters.Create(domain, FRandom);
    generator.Init(keygenParams);

    KeyPair := generator.GeneratePhraseKeyPair(Phrase);

    PrivKey := BytesToBase58((KeyPair.Private as IECPrivateKeyParameters).D.ToByteArray);
    PubKey := BytesToBase58((KeyPair.Public as IECPublicKeyParameters).Q.GetEncoded);
  finally
    LCS.Leave
  end;
end;

function RestorePublicKey(const PrivKey: string; out PubKey: string): Boolean;
var
  FCurve: IX9ECParameters;
  domain: IECDomainParameters;
  D: TBigInteger;
  RegeneratedPrivateKey: IECPrivateKeyParameters;
  recreatedPubKeyParameters: IECPublicKeyParameters;
begin
  LCS.Enter;
  try
    try
      FCurve := TCustomNamedCurves.GetByName(CurveName);
      domain := TECDomainParameters.Create(FCurve.Curve, FCurve.G, FCurve.N,
        FCurve.H, FCurve.GetSeed);
      D := TBigInteger.Create(1, HexToBytes(PrivKey));
      RegeneratedPrivateKey := TECPrivateKeyParameters.Create('ECDSA', D, domain);

      recreatedPubKeyParameters := TECKeyPairGenerator.GetCorrespondingPublicKey
        (RegeneratedPrivateKey);

      PubKey := BytesToHex(recreatedPubKeyParameters.Q.GetEncoded).ToLower;
      Result := True;
    except
      Result := False;
    end;
  finally
    LCS.Leave
  end;
end;

function RestoreAddress(const PubKeyStr: string; out HexAddrStr: string; const Prefix: string = ''): Boolean;
begin

  var PubKeyBytes:TBytes := HexToBytes(PubKeyStr);
  assert(Length(PubKeyBytes) in [64, 65], 'incorrect public Key Length');

  if Length(PubKeyBytes) = 65 then begin
    Assert(PubKeyBytes[0] = 4, 'incorrect public Key');
    PubKeyBytes := Copy(PubKeyBytes, 1);
  end;

  const HashInstance = THashFactory.TCrypto.CreateKeccak_256();
  const Keccak256 = HashInstance.ComputeBytes(PubKeyBytes);
  const HashBytes = Keccak256.GetBytes;
  HexAddrStr := Prefix + BytesToHex(copy(HashBytes, 12));

  Result := True;

end;

function ECDSACheckBytesSign(const InputBytes: TBytes; const Sign: TBytes; const PubKey: TBytes): Boolean;
var
  i: Integer;
  s: string;
  FCurve: IX9ECParameters;
  domain: IECDomainParameters;
  RegeneratedPublicKey: IECPublicKeyParameters;
  Signer: ISigner;
begin
  LCS.Enter;
  try
    try
      FCurve := TCustomNamedCurves.GetByName(CurveName);
      domain := TECDomainParameters.Create(FCurve.Curve, FCurve.G, FCurve.N,
        FCurve.H, FCurve.GetSeed);
      RegeneratedPublicKey := TECPublicKeyParameters.Create('ECDSA',
        FCurve.Curve.DecodePoint(PubKey), domain);

      Signer := TSignerUtilities.GetSigner(SigningAlgo);
      Signer.Init(False, RegeneratedPublicKey);

      Signer.BlockUpdate(InputBytes, 0, System.Length(InputBytes));
      Result := Signer.VerifySignature(Sign);
    except
      Result := False;
    end;
  finally
    LCS.Leave
  end;
end;


function ECDSACheckTextSign(const InputText: string; const Sign: string; const PubKey: TBytes): Boolean; overload;
var
  i: Integer;
  s: string;
  FCurve: IX9ECParameters;
  domain: IECDomainParameters;
  RegeneratedPublicKey: IECPublicKeyParameters;
  Signer: ISigner;
  sigBytes: TBytes;
  &b: TCryptoLibByteArray;
begin
  LCS.Enter;
  try
    try
      FCurve := TCustomNamedCurves.GetByName(CurveName);
      domain := TECDomainParameters.Create(FCurve.Curve, FCurve.G, FCurve.N,
        FCurve.H, FCurve.GetSeed);
      RegeneratedPublicKey := TECPublicKeyParameters.Create('ECDSA',
        FCurve.Curve.DecodePoint(PubKey), domain);

      Signer := TSignerUtilities.GetSigner(SigningAlgo);
      Signer.Init(False, RegeneratedPublicKey);
      SetLength(sigBytes,0);
      i := 0;
      while (i < Length(Sign) div 2) do
      begin
        s := Copy(Sign, i * 2 + 1, 2);
        sigBytes := sigBytes + [StrToInt('$' + s)];
        Inc(i)
      end;

      &b := TEncoding.ANSI.GetBytes(InputText);
      Signer.BlockUpdate(&b, 0, System.Length(&b));
      Result := Signer.VerifySignature(sigBytes);
    except
      Result := False;
    end;
  finally
    LCS.Leave
  end;
end;

function ECDSACheckTextSign(const InputText: string; const Sign: string;
  const PubKeyBase58: string): Boolean;
begin
  try
    Result := ECDSACheckTextSign(InputText,Sign,Base58ToBytes(PubKeyBase58));
  except
    Result := False;
  end;
end;

function EVP_GetKeyIV(PasswordBytes, SaltBytes: TBytes; out KeyBytes, IVBytes: TBytes): Boolean;
var
  LKey, LIV: integer;
  LDigest: IDigest;
begin
  LKey := 32; // AES256 CBC Key Length
  LIV := 16; // AES256 CBC IV Length
  System.SetLength(KeyBytes, LKey);
  System.SetLength(IVBytes, LKey);
  // Max size to start then reduce it at the end
  LDigest := TDigestUtilities.GetDigest('SHA-256'); // SHA2_256
  System.Assert(LDigest.GetDigestSize >= LKey);
  System.Assert(LDigest.GetDigestSize >= LIV);
  // Derive Key First
  LDigest.BlockUpdate(PasswordBytes, 0, System.Length(PasswordBytes));
  if SaltBytes <> Nil then
  begin
    LDigest.BlockUpdate(SaltBytes, 0, System.Length(SaltBytes));
  end;
  LDigest.DoFinal(KeyBytes, 0);
  // Derive IV Next
  LDigest.Reset();
  LDigest.BlockUpdate(KeyBytes, 0, System.Length(KeyBytes));
  LDigest.BlockUpdate(PasswordBytes, 0, System.Length(PasswordBytes));
  if SaltBytes <> Nil then
  begin
    LDigest.BlockUpdate(SaltBytes, 0, System.Length(SaltBytes));
  end;
  LDigest.DoFinal(IVBytes, 0);
  System.SetLength(IVBytes, LIV);
  result := True;
end;

function AES256CBCPascalCoinEncrypt(PlainText,PasswordBytes: TBytes): TBytes;
var
  SaltBytes, KeyBytes, IVBytes, Buf: TBytes;
  KeyParametersWithIV: IParametersWithIV;
  cipher: IBufferedCipher;
  LBlockSize, LBufStart, Count: Int32;
  FRandom: ISecureRandom;
begin
  FRandom := TSecureRandom.Create();
  SetLength(SaltBytes, PKCS5_SALT_LEN);
  FRandom.NextBytes(SaltBytes);
  EVP_GetKeyIV(PasswordBytes, SaltBytes, KeyBytes, IVBytes);
  cipher := TCipherUtilities.GetCipher('AES/CBC/PKCS7PADDING');
  KeyParametersWithIV := TParametersWithIV.Create
    (TParameterUtilities.CreateKeyParameter('AES', KeyBytes), IVBytes);
  cipher.Init(True, KeyParametersWithIV); // init encryption cipher
  LBlockSize := cipher.GetBlockSize;
  System.SetLength(Buf, System.Length(PlainText) + LBlockSize + SALT_MAGIC_LEN +
    PKCS5_SALT_LEN);
  LBufStart := 0;
  System.Move(TEncoding.ANSI.GetBytes(SALT_MAGIC)[0],
    Buf[LBufStart], SALT_MAGIC_LEN * System.SizeOf(Byte));
  System.Inc(LBufStart, SALT_MAGIC_LEN);
  System.Move(SaltBytes[0], Buf[LBufStart],
    PKCS5_SALT_LEN * System.SizeOf(Byte));
  System.Inc(LBufStart, PKCS5_SALT_LEN);
  Count := cipher.ProcessBytes(PlainText, 0, System.Length(PlainText), Buf,
    LBufStart);
  System.Inc(LBufStart, Count);
  Count := cipher.DoFinal(Buf, LBufStart);
  System.Inc(LBufStart, Count);
  System.SetLength(Buf, LBufStart);
  result := Buf;
end;

procedure ECDSAEncryptBytesSymmetric(const InputBytes: TBytes; const PasswordBytes: TBytes; out EncryptedBytes: TBytes);
begin
  EncryptedBytes := AES256CBCPascalCoinEncrypt(InputBytes, PasswordBytes);
end;

procedure ECDSAEncryptTextSymmetric(const InputText: string; const Password: string; out EncryptedText: string);
var
  InputTextBytes, PasswordBytes, EncryptedBytes: TBytes;
begin
  InputTextBytes := TEncoding.ANSI.GetBytes(InputText);
  PasswordBytes := TEncoding.ANSI.GetBytes(Password);
  ECDSAEncryptBytesSymmetric(InputTextBytes,PasswordBytes,EncryptedBytes);
  EncryptedText := THex.Encode(EncryptedBytes);
end;

function AES256CBCPascalCoinDecrypt(CipherText, PasswordBytes: TBytes; out PlainText: TBytes): Boolean;
var
  SaltBytes, KeyBytes, IVBytes, Buf, Chopped: TBytes;
  KeyParametersWithIV: IParametersWithIV;
  cipher: IBufferedCipher;
  LBufStart, LSrcStart, Count: Int32;
begin
  result := False;
  System.SetLength(SaltBytes, SALT_SIZE);
  // First read the magic text and the salt - if any
  Chopped := System.Copy(CipherText, 0, SALT_MAGIC_LEN);
  if (System.Length(CipherText) >= SALT_MAGIC_LEN) and
    (TArrayUtils.AreEqual(Chopped, TEncoding.ANSI.GetBytes(SALT_MAGIC))) then
  begin
    System.Move(CipherText[SALT_MAGIC_LEN], SaltBytes[0], SALT_SIZE);
    If not EVP_GetKeyIV(PasswordBytes, SaltBytes, KeyBytes, IVBytes) then
    begin
      Exit;
    end;
    LSrcStart := SALT_MAGIC_LEN + SALT_SIZE;
  end
  else
  begin
    If Not EVP_GetKeyIV(PasswordBytes, Nil, KeyBytes, IVBytes) then
    begin
      Exit;
    end;
    LSrcStart := 0;
  end;
  cipher := TCipherUtilities.GetCipher('AES/CBC/PKCS7PADDING');
  KeyParametersWithIV := TParametersWithIV.Create
    (TParameterUtilities.CreateKeyParameter('AES', KeyBytes), IVBytes);
  cipher.Init(False, KeyParametersWithIV); // init decryption cipher
  System.SetLength(Buf, System.Length(CipherText));
  LBufStart := 0;
  Count := cipher.ProcessBytes(CipherText, LSrcStart, System.Length(CipherText)
    - LSrcStart, Buf, LBufStart);
  System.Inc(LBufStart, Count);
  Count := cipher.DoFinal(Buf, LBufStart);
  System.Inc(LBufStart, Count);
  System.SetLength(Buf, LBufStart);
  PlainText := System.Copy(Buf);
  result := True;
end;

procedure ECDSADecryptBytesSymmetric(const EncryptedBytes: TBytes; const PasswordBytes: TBytes; out DecryptedBytes: TBytes);
begin
  AES256CBCPascalCoinDecrypt(EncryptedBytes, PasswordBytes, DecryptedBytes);
end;

procedure ECDSADecryptTextSymmetric(const EncryptedText: string; const Password: string; out DecryptedText: string);
var
  PasswordBytes, EncodedBytes, DecryptedBytes: TBytes;
begin
  try
    EncodedBytes := THex.Decode(EncryptedText);
    PasswordBytes := TEncoding.ANSI.GetBytes(Password);
    ECDSADecryptBytesSymmetric(EncodedBytes, PasswordBytes, DecryptedBytes);
  except
    SetLength(DecryptedBytes,0);
  end;
  DecryptedText := TEncoding.ANSI.GetString(DecryptedBytes);
end;

function GetECIESPascalCoinCompatibilityEngine: IPascalCoinIESEngine;
var
  cipher: IBufferedBlockCipher;
  AesEngine: IAesEngine;
  blockCipher: ICbcBlockCipher;
  ECDHBasicAgreementInstance: IECDHBasicAgreement;
  KDFInstance: IPascalCoinECIESKdfBytesGenerator;
  DigestMACInstance: IMac;
begin
  // Set up IES Cipher Engine For Compatibility With PascalCoin
  ECDHBasicAgreementInstance := TECDHBasicAgreement.Create();
  KDFInstance := TPascalCoinECIESKdfBytesGenerator.Create
    (TDigestUtilities.GetDigest('SHA-512'));
  DigestMACInstance := TMacUtilities.GetMac('HMAC-MD5');
  // Set Up Block Cipher
  AesEngine := TAesEngine.Create(); // AES Engine
  blockCipher := TCbcBlockCipher.Create(AesEngine); // CBC
  cipher := TPaddedBufferedBlockCipher.Create(blockCipher,
    TZeroBytePadding.Create() as IZeroBytePadding); // ZeroBytePadding
  result := TPascalCoinIESEngine.Create(ECDHBasicAgreementInstance, KDFInstance,
    DigestMACInstance, cipher);
end;

function GetIESParameterSpec: IIESParameterSpec;
var
  Derivation, Encoding, IVBytes: TBytes;
  MacKeySizeInBits, CipherKeySizeInBits: Int32;
  UsePointCompression: Boolean;
begin
  // Set up  IES Parameter Spec For Compatibility With PascalCoin Current Implementation
  // The derivation and encoding vectors are used when initialising the KDF and MAC.
  // They're optional but if used then they need to be known by the other user so that
  // they can decrypt the ciphertext and verify the MAC correctly. The security is based
  // on the shared secret coming from the (static-ephemeral) ECDH key agreement.
  Derivation := Nil;
  Encoding := Nil;
  System.SetLength(IVBytes, 16); // using Zero Initialized IV for compatibility
  MacKeySizeInBits := 32 * 8;
  // Since we are using AES256_CBC for compatibility
  CipherKeySizeInBits := 32 * 8;
  // whether to use point compression when deriving the octets string
  // from a point or not in the EphemeralKeyPairGenerator
  UsePointCompression := True; // for compatibility
  result := TIESParameterSpec.Create(Derivation, Encoding, MacKeySizeInBits,
    CipherKeySizeInBits, IVBytes, UsePointCompression);
end;

function ECIESPascalCoinEncrypt(const PublicKey: IAsymmetricKeyParameter; PlainText: TBytes): TBytes;
var
  CipherEncrypt: IIESCipher;
  FRandom: ISecureRandom;
begin
  FRandom := TSecureRandom.Create();
  CipherEncrypt := TIESCipher.Create(GetECIESPascalCoinCompatibilityEngine);
  CipherEncrypt.Init(True, PublicKey, GetIESParameterSpec, FRandom);
  result := CipherEncrypt.DoFinal(PlainText);
end;

procedure ECDSAEncryptTextAsymmetric(const InputText: string; const PubKey: string; out EncryptedText: string); overload;
var
  PublicKeyBytes, TextToEncodeBytes: TBytes;
  LCurve: IX9ECParameters;
  domain: IECDomainParameters;
  RegeneratedPublicKey: IECPublicKeyParameters;
begin
  Assert(PubKey <> '', 'Public key can not be empty');
  Assert(InputText <> '', 'Input text can not be empty');
  try
    PublicKeyBytes := Base58ToBytes(PubKey);
    TextToEncodeBytes := TEncoding.ANSI.GetBytes(InputText);
    LCurve := TCustomNamedCurves.GetByName(CurveName);
    domain := TECDomainParameters.Create(Lcurve.Curve, Lcurve.G, Lcurve.N,
    Lcurve.H, Lcurve.GetSeed);
    RegeneratedPublicKey := TECPublicKeyParameters.Create('ECDSA',
      Lcurve.Curve.DecodePoint(PublicKeyBytes), domain);

    EncryptedText := THex.Encode(ECIESPascalCoinEncrypt(RegeneratedPublicKey, TextToEncodeBytes));
  except
    EncryptedText := '';
  end;
end;

procedure ECDSAEncryptTextAsymmetric(const InputText: string; const PubKey: IECPublicKeyParameters; out EncryptedBytes: TArray<Byte>); overload;
var
  TextToEncodeBytes: TBytes;
begin
  Assert(PubKey <> nil, 'Public key can not be empty');
  Assert(InputText <> '', 'Input text can not be empty');
  try
    TextToEncodeBytes := TEncoding.ANSI.GetBytes(InputText);
    EncryptedBytes := ECIESPascalCoinEncrypt(PubKey, TextToEncodeBytes);
  except
    SetLength(EncryptedBytes, 0);
  end;
end;

procedure ECDSAEncryptTextAsymmetric(const InputBytes: TArray<Byte>; const PubKey: IECPublicKeyParameters; out EncryptedBytes: TArray<Byte>); overload;
begin
  Assert(PubKey <> nil, 'Public key can not be empty');
  Assert(Length(InputBytes) <> 0, 'Input bytes can not be empty');
  try
    EncryptedBytes := ECIESPascalCoinEncrypt(PubKey, InputBytes);
  except
    SetLength(EncryptedBytes, 0);
  end;
end;

function ECIESPascalCoinDecrypt(const PrivateKey: IAsymmetricKeyParameter; CipherText: TBytes; out PlainText: string): Boolean; overload;
var
  CipherDecrypt: IIESCipher;
  FRandom: ISecureRandom;
begin
  FRandom := TSecureRandom.Create();
  CipherDecrypt := TIESCipher.Create(GetECIESPascalCoinCompatibilityEngine);
  CipherDecrypt.Init(False, PrivateKey, GetIESParameterSpec, FRandom);
  PlainText := TEncoding.ANSI.GetString(CipherDecrypt.DoFinal(CipherText));
  result := True;
end;

function ECIESPascalCoinDecrypt(const PrivateKey: IAsymmetricKeyParameter; CipherText: TBytes; out PlainText: TArray<Byte>): Boolean; overload;
var
  CipherDecrypt: IIESCipher;
  FRandom: ISecureRandom;
begin
  FRandom := TSecureRandom.Create();
  CipherDecrypt := TIESCipher.Create(GetECIESPascalCoinCompatibilityEngine);
  CipherDecrypt.Init(False, PrivateKey, GetIESParameterSpec, FRandom);
  PlainText := CipherDecrypt.DoFinal(CipherText);
  result := True;
end;

procedure ECDSADecryptTextAsymmetric(const EncryptedText: string; const PrivKey: string; out DecryptedText: string); overload;
var
  PrivateKeyBytes, PayloadToDecodeBytes: TBytes;
  LCurve: IX9ECParameters;
  domain: IECDomainParameters;
  RegeneratedPrivateKey: IECPrivateKeyParameters;
  PrivD: TBigInteger;
begin
  Assert(PrivKey <> '', 'Private key can not be empty');
  try
    PrivateKeyBytes := Base58ToBytes(PrivKey);
    PayloadToDecodeBytes := THex.Decode(EncryptedText);

    LCurve := TCustomNamedCurves.GetByName(CurveName);
    domain := TECDomainParameters.Create(Lcurve.Curve, Lcurve.G, Lcurve.N,
    Lcurve.H, Lcurve.GetSeed);
    PrivD := TBigInteger.Create(1, PrivateKeyBytes);
    RegeneratedPrivateKey := TECPrivateKeyParameters.Create('ECDSA',
      PrivD, domain);

    ECIESPascalCoinDecrypt(RegeneratedPrivateKey, PayloadToDecodeBytes, DecryptedText);
  except
    DecryptedText := '';
    exit;
  end;
end;

procedure ECDSADecryptTextAsymmetric(const EncryptedBytes: TArray<Byte>; const PrivKey: IECPrivateKeyParameters; out DecryptedText: string); overload;
begin
  Assert(PrivKey <> nil, 'Private key can not be empty');
  Assert(Length(EncryptedBytes) > 0, 'Encrypted bytes can not be empty');
  try
    ECIESPascalCoinDecrypt(PrivKey, EncryptedBytes, DecryptedText);
  except
    DecryptedText := '';
  end;
end;

procedure ECDSADecryptTextAsymmetric(const EncryptedBytes: TArray<Byte>; const PrivKey: IECPrivateKeyParameters; out DecryptedBytes: TArray<Byte>); overload;
begin
  Assert(PrivKey <> nil, 'Private key can not be empty');
  Assert(Length(EncryptedBytes) > 0, 'Encrypted bytes can not be empty');
  try
    ECIESPascalCoinDecrypt(PrivKey, EncryptedBytes, DecryptedBytes);
  except
    SetLength(DecryptedBytes, 0);
  end;
end;

initialization

LCS := TCriticalSection.Create;

finalization

LCS.Free;

end.
