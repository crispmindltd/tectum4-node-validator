unit LibCryptoSigner;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  LibCryptoWrapper,
  ClpIX9ECParametersHolder;

function ComputeKeccak256(const Input: TBytes): TBytes;
function RecoverAddress(const Msg, Sign: TBytes): TBytes;
function HexToBytes(const HexStr: string): TBytes;
function BytesToHex(const Bytes: TBytes): string;

implementation

function HexToBytes(const HexStr: string): TBytes;
begin
  var lHexStr := HexStr;
  const strLen = Length(lHexStr);
  if (strLen mod 2) <> 0 then
    lHexStr := '0' + lHexStr;
  const len = Length(lHexStr) div 2;
  SetLength(Result, len);
  HexToBin(PChar(lHexStr), Result, len);
end;

function BytesToHex(const Bytes: TBytes): string;
begin
  const len = Length(Bytes);
  SetLength(Result, len * 2);
  BinToHex(Bytes[0], PChar(Result), len);
end;

function ComputeKeccak256(const Input: TBytes): TBytes;
var
  Ctx: PEVP_MD_CTX;
  Digest: PEVP_MD;
  HashSize: Cardinal;
begin
  Digest := EVP_MD_fetch(nil, 'keccak-256', nil);
  if Digest = nil then
    raise Exception.Create('Keccak256 not found');
  Ctx := EVP_MD_CTX_new();
  if Ctx = nil then begin
    EVP_MD_free(Digest);
    raise Exception.Create('Hash context create error');
  end;
  try
    if EVP_DigestInit_ex(Ctx, Digest, nil) <> 1 then
      raise Exception.Create('Hash initialize error');
    if EVP_DigestUpdate(Ctx, @Input[0], Length(Input)) <> 1 then
      raise Exception.Create('Hash update error');
    SetLength(Result, 32);
    HashSize := 0;
    if EVP_DigestFinal_ex(Ctx, @Result[0], @HashSize) <> 1 then
      raise Exception.Create('Hash finalize error');
    if HashSize <> 32 then
      raise Exception.Create('Invalid hash size');
  finally
    EVP_MD_CTX_free(Ctx);
    EVP_MD_free(Digest);
  end;
end;

function RecoverAddress(const Msg, Sign: TBytes): TBytes;
var
  Curve: PEC_GROUP;
  BNCtx: PBN_CTX;
  S_R, S_S, S_Rec, N, P, i, x, tmp, e, eInv, e_mod_n, rInv, srInv, eInvrInv: PBIGNUM;
  R, tmp_ec, q:PEC_POINT;

  function DecompressKey(xBn: PBIGNUM; yBit: Byte): PEC_POINT;
  begin
    Result := nil;
    const Len = 32;
    var compressedPointData: TBytes;
    SetLength(compressedPointData, Len + 1);
    Assert(Len = BN_bn2binPad(xBn, @compressedPointData[1], Len));
    compressedPointData[0] := $02 + yBit;
    Result := EC_POINT_new(Curve);
    const res = EC_POINT_oct2point(Curve, Result, @compressedPointData[0], Length(compressedPointData), BNCtx);
  end;

begin
  if Length(Sign) < 65 then
    raise Exception.Create('sign is out of range');
  const data = ComputeKeccak256(Msg);
  S_R := nil;
  S_S := nil;
  S_Rec := nil;
  N := nil;
  P := nil;
  i := nil;
  x := nil;
  tmp := nil;
  e := nil;
  eInv := nil;
  e_mod_n := nil;
  rInv := nil;
  srInv := nil;
  eInvrInv := nil;
  R := nil;
  tmp_ec := nil;
  q := nil;
  Curve := nil;
  BNCtx := nil;
  try
    Curve := EC_GROUP_new_by_curve_name(NID_secp256k1);
    BNCtx := BN_CTX_new();

    S_R := BN_new();
    BN_bin2bn(@Sign[0], 32, S_R);

    S_S := BN_new();
    BN_bin2bn(@Sign[32], 32, S_S);

    S_Rec := BN_new();
    BN_bin2bn(@Sign[64], 1, S_Rec);

    Assert(Sign[64] >= 27);
    const recId: Byte = Sign[64] - 27;

    N := BN_new();
    BN_hex2bn(@N, constNstr);

    P := BN_new();
    BN_hex2bn(@P, constPstr);

    i := BN_new();
    const halfRecId: Byte = recId div 2;
    BN_bin2bn(@halfRecId, 1, i);

    x := BN_new();
    tmp := BN_new();
    BN_mul(tmp, i, N, BNCtx);
    BN_add(x, S_R, tmp);

    if BN_cmp(x, P) >= 0 then
      raise Exception.Create('an unknown error occurred');

    R := DecompressKey(x, recId and 1);

    tmp_ec := EC_POINT_new(Curve);

    EC_POINT_mul(Curve, tmp_ec, nil, R, N, BNCtx);

    if EC_POINT_is_at_infinity(Curve, tmp_ec) = 0 then
      raise Exception.Create('an unknown error occurred');

    e := BN_new();
    BN_bin2bn(@data[0], Length(data), e);

    eInv := BN_new();
    e_mod_n := BN_new();
    BN_div(nil, e_mod_n, e, N, BNCtx);
    BN_sub(eInv, N, e_mod_n);

    rInv := BN_new();
    BN_mod_inverse(rInv, S_R, N, BNCtx);

    srInv := BN_new();
    BN_mod_mul(srInv, rInv, S_S, N, BNCtx);

    eInvrInv := BN_new();
    BN_mod_mul(eInvrInv, rInv, eInv, N, BNCtx);

    q := EC_POINT_new(Curve);

    const ecp: TArray<PEC_POINT> = [EC_GROUP_get0_generator(Curve), R];
    const bna: TArray<PBIGNUM> = [eInvrInv, srInv];

    EC_POINTs_mul(Curve, q, nil, 2, @ecp[0], @bna[0], BNCtx);

    var PubKey: TBytes;
    const xLen = 65;
    SetLength(PubKey, xLen);
    EC_POINT_point2oct(Curve, q, POINT_CONVERSION_UNCOMPRESSED, @PubKey[0], xLen, BNCtx);

    Result := Copy(ComputeKeccak256(Copy(PubKey, 1)), 12);

  finally
    BN_free(S_R);
    BN_free(S_S);
    BN_free(S_Rec);
    BN_free(N);
    BN_free(P);
    BN_free(i);
    BN_free(x);
    BN_free(tmp);
    BN_free(e);
    BN_free(eInv);
    BN_free(e_mod_n);
    BN_free(rInv);
    BN_free(srInv);
    BN_free(eInvrInv);

    EC_POINT_free(R);
    EC_POINT_free(tmp_ec);
    EC_POINT_free(q);

    BN_CTX_free(BNCtx);
    EC_GROUP_free(Curve);
  end;
end;

end.
