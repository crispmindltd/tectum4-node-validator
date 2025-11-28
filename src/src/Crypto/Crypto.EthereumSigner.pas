{******************************************************************************}
{                             This unit is based on                            }
{                                  Delphereum                                  }
{             Copyright(c) 2018 Stefan van As <svanas@runbox.com>              }
{           Github Repository <https://github.com/svanas/delphereum>           }
{******************************************************************************}
unit Crypto.EthereumSigner;

interface

uses
  Crypto,
  System.Classes,
  System.SysUtils,
  ClpICipherParameters,
  ClpIX9ECParameters,
  ClpIECDomainParameters,
  ClpIECKeyParameters,
  ClpIECPrivateKeyParameters,
  ClpIECPublicKeyParameters,
  ClpIHMacDsaKCalculator,
  HlpSHA3,
  ClpECAlgorithms,
  ClpX9ECC,
  ClpDigestUtilities,
  ClpHMacDsaKCalculator,
  ClpCryptoLibTypes,
  ClpBigInteger,
  ClpBigIntegers,
  ClpECPrivateKeyParameters,
  ClpECPublicKeyParameters,
  ClpIECC,
  ClpMultipliers,
  ClpECKeyPairGenerator,
  ClpECDomainParameters,
  ClpCustomNamedCurves;

function TryUseOpenSSL:Boolean;
function SignWithKey(const Msg, PrivKey: TBytes): TBytes;
function TryRecoverAddress(const Msg, Sign: TBytes; out AAddress: TBytes): Boolean;

var
  RecoverAddress: function (const Msg, Sign: TBytes): TBytes = nil;
  Keccack256:  function (const Buf: TBytes): TBytes = nil;

implementation

uses LibCryptoWrapper, LibCryptoSigner;

const CurveName = 'secp256k1';
const algorithm = 'ECDSA';
const orderHex = 'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141';

type
  TECDsaSignature = record
    r  : TBigInteger;
    s  : TBigInteger;
    rec: TBigInteger;
  end;

var
  curve : IX9ECParameters;
  domain: IECDomainParameters;
  curveOrder,halfCurveOrder : TBigInteger;
  FkCalculator:IHMacDsaKCalculator;

function Keccak256Internal(const Buf: TBytes): TBytes;
begin
  LCS.Enter;
  try
    const Lkeccak256 = TKeccak_256.Create;
    try
      Result := Lkeccak256.ComputeBytes(Buf).GetBytes;
    finally
      Lkeccak256.Free;
    end;
  finally
    LCS.Leave;
  end;
end;

function GenerateSignature(const msg, AprivKey:TBytes): TECDsaSignature;
  function CalculateE(const n: TBigInteger;  const &message: TCryptoLibByteArray): TBigInteger;
  var
    messageBitLength: Int32;
    trunc: TBigInteger;
  begin
    messageBitLength := System.Length(&message) * 8;
    trunc := TBigInteger.Create(1, &message);
    if (n.BitLength < messageBitLength) then begin
      trunc := trunc.ShiftRight(messageBitLength - n.BitLength);
    end;
    Result := trunc;
  end;
  function isLowS(const s: TBigInteger): Boolean;
  begin
    Result := s.CompareTo(halfCurveOrder) <= 0;
  end;
  procedure makeCanonical(var aSignature: TECDsaSignature);
  begin
    if not isLowS(aSignature.s) then
      aSignature.s := curveOrder.Subtract(aSignature.s);
  end;
begin
  const privD = TBigInteger.Create(1, AprivKey);
  const Fkey:IECKeyParameters = TECPrivateKeyParameters.Create(algorithm, privD, domain);
  const ec: IECDomainParameters = Fkey.parameters;
  const n = ec.n;
  const e = CalculateE(n, msg);
  const d = (Fkey as IECPrivateKeyParameters).d;
  FkCalculator.Init(n, d, msg);
  const base: IECMultiplier = TFixedPointCombMultiplier.Create();
  var p: IECPoint;
  repeat
    var k: TBigInteger;
    repeat
      k := FkCalculator.NextK;
      p := base.Multiply(ec.G, k).Normalize;
      Result.r := p.AffineXCoord.ToBigInteger.&Mod(n);
    until not(Result.r.SignValue = 0);
    Result.s := k.ModInverse(n).Multiply(e.Add(d.Multiply(Result.r))).&Mod(n);
  until not(Result.s.SignValue = 0);
  Result.rec := p.AffineYCoord.ToBigInteger.&And(TBigInteger.One);
  if Result.s.CompareTo(n.Divide(TBigInteger.Two)) = 1 then
    Result.rec := Result.rec.&Xor(TBigInteger.One);
  makeCanonical(Result);
end;

function SignWithKey(const msg, PrivKey: TBytes): TBytes;
begin
  LCS.Enter;
  try
    const Signature = GenerateSignature(Keccack256(msg), PrivKey);
    var signBytes:TBytes;
    SetLength(signBytes, 65);
    const rBytes = Signature.r.ToByteArrayUnsigned;
    const sBytes = Signature.s.ToByteArrayUnsigned;
    var recBytes := Signature.rec.ToByteArrayUnsigned;
    if Length(recBytes) < 1 then recBytes := [0];
    const rLength = Length(rBytes);
    const sLength = Length(sBytes);
    const recLength = Length(recBytes);
    assert(rLength <= 32);
    assert(sLength <= 32);
    assert(recLength <= 1);
    recBytes[0] := recBytes[0] + 27;
    System.Move(rBytes[0], signBytes[32 - rLength], rlength);
    System.Move(sBytes[0], signBytes[64 - sLength], slength);
    System.Move(recBytes[0], signBytes[65 - recLength], reclength);
    Result := signBytes;
  finally
    LCS.Leave;
  end;
end;

function RecoverAddressInternal(const Msg, Sign: TBytes): TBytes;
  function decompressKey(curve: IECCurve; xBN: TBigInteger; yBit: Boolean): IECPoint;
  begin
    const compEnc = TX9IntegerConverter.IntegerToBytes(xBN, 1 + TX9IntegerConverter.GetByteLength(curve));
    if yBit then
      compEnc[0] := $03
    else
      compEnc[0] := $02;
    Result := curve.DecodePoint(compEnc);
  end;
  function publicKeyToByteArray(const aPubKey: IECPublicKeyParameters): TBytes;
  begin
    Result := TBigIntegers.BigIntegerToBytes(aPubKey.Q.AffineXCoord.ToBigInteger, 32)
            + TBigIntegers.BigIntegerToBytes(aPubKey.Q.AffineYCoord.ToBigInteger, 32);
  end;
begin
  LCS.Enter;
  try
    const data = Keccack256(msg);
    if Length(Sign) < 65 then
      raise Exception.Create('out of range');
    var Signature:TECDsaSignature;
    Signature.r := TBigInteger.Create(1, copy(Sign, 0, 32));
    Signature.s := TBigInteger.Create(1, copy(Sign, 32, 32));
    Signature.rec := TBigInteger.Create(1, copy(Sign, 64, 1));
    const recId = Signature.rec.Int32ValueExact - 27;
    const n = curve.n;
    const prime = curve.Curve.Field.Characteristic;
    const i = TBigInteger.ValueOf(Int64(RecId) div 2);
    const x = signature.R.Add(i.Multiply(n));
    if x.CompareTo(prime) >= 0 then
      raise Exception.Create('an unknown error occurred');
    const R = decompressKey(curve.Curve, x, (recId and 1) = 1);
    if not R.Multiply(n).IsInfinity then
      raise Exception.Create('an unknown error occurred');
    const e        = TBigInteger.Create(1, data);
    const eInv     = TBigInteger.Zero.Subtract(e).&Mod(n);
    const rInv     = signature.R.ModInverse(n);
    const srInv    = rInv.Multiply(signature.S).&Mod(n);
    const eInvrInv = rInv.Multiply(eInv).&Mod(n);
    const q = TECAlgorithms.SumOfTwoMultiplies(curve.G, eInvrInv, R, srInv).Normalize;
    const vch = q.GetEncoded;
    const yu = curve.curve.DecodePoint(vch);
    const pubKey:IECPublicKeyParameters = TECPublicKeyParameters.Create('EC', yu, domain);
    const buffer = Keccack256(publicKeyToByteArray(pubKey));
    Result := copy(buffer, 12);
  finally
    LCS.Leave;
  end;
end;

function TryRecoverAddress(const Msg, Sign: TBytes; out AAddress: TBytes): Boolean;
begin
  try
    Result := True;
    AAddress := RecoverAddress(Msg, Sign);
  except
    Result := False;
  end;
end;

function TryUseOpenSSL:Boolean;
begin
  try
    const Digest = EVP_MD_fetch(nil, 'keccak-256', nil);
    Result := Assigned(Digest);
    EVP_MD_free(Digest);

    if Result then begin
      RecoverAddress := LibCryptoSigner.RecoverAddress;
      Keccack256 := LibCryptoSigner.ComputeKeccak256;
    end;
  except
    Result := False;
  end;
end;

initialization
  curve := TCustomNamedCurves.GetByName(curveName);
  domain := TECDomainParameters.Create(curve.Curve, curve.G, curve.N, curve.H, curve.GetSeed);
  curveOrder := TBigInteger.Create(orderHex, 16);
  halfCurveOrder := curveOrder.ShiftRight(1);
  FkCalculator := THMacDsaKCalculator.Create(TDigestUtilities.GetDigest('SHA-256'));
  RecoverAddress := RecoverAddressInternal;
  Keccack256 := Keccak256Internal;

finalization
  FkCalculator := nil;
  domain := nil;
  curve := nil;
end.





