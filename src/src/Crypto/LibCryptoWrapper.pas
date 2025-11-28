unit LibCryptoWrapper;

interface

const
  {$IF Defined(WIN32)}
  LIB_CRYPTO = 'libcrypto-1_1.dll';
  LIB_SSL = 'libssl-1_1.dll';
  {$ELSEIF Defined(WIN64)}
  LIB_CRYPTO = 'libcrypto-3-x64.dll'; // LIB_CRYPTO = 'libcrypto-1_1-x64.dll';
  LIB_SSL = 'libssl-1_1-x64.dll';
  {$ELSEIF Defined(ANDROID64)}
  LIB_CRYPTO = 'libcrypto-android64.a';
  LIB_SSL = 'libssl-android64.a';
  {$ELSEIF Defined(ANDROID32)}
  LIB_CRYPTO = 'libcrypto-android32.a';
  LIB_SSL = 'libssl-android32.a';
  {$ELSEIF Defined(IOS)}
  LIB_CRYPTO = 'libcrypto-ios.a';
  LIB_SSL = 'libssl-ios.a';
  {$ELSEIF Defined(MACOS32)}
  LIB_CRYPTO = 'libssl-merged-osx32.dylib'; { We unify LibSsl and LibCrypto into a common shared library on macOS }
  LIB_SSL = 'libssl-merged-osx32.dylib';
  {$ELSEIF Defined(MACOS64)}
  LIB_CRYPTO = 'libcrypto-osx64.a';
  LIB_SSL = 'libssl-osx64.a';
  {$ELSEIF Defined(LINUX)}
  LIB_CRYPTO = 'libcrypto.so';
  LIB_SSL = 'libssl.so';
  {$ELSE}
    {$MESSAGE Error 'Unsupported platform'}
  {$ENDIF}

  NID_secp256k1 = 714;

  constPstr = AnsiString('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F');
  constNstr = AnsiString('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141');

  POINT_CONVERSION_UNCOMPRESSED = 4;
  POINT_CONVERSION_COMPRESSED = 2;

type
  BIGNUM = record end;
  EC_POINT = record end;

  PEC_GROUP = Pointer;
  PEC_POINT = ^EC_POINT;
  PBIGNUM = ^BIGNUM;
  PBN_CTX = Pointer;
  PEVP_MD_CTX = Pointer;
  PEVP_MD = Pointer;

function EVP_MD_CTX_new(): PEVP_MD_CTX; cdecl; external LIB_CRYPTO;
procedure EVP_MD_CTX_free(ctx: PEVP_MD_CTX); cdecl; external LIB_CRYPTO;

function EC_GROUP_new_by_curve_name(nid: Integer): PEC_GROUP; cdecl; external LIB_CRYPTO;
procedure EC_GROUP_free(EC_GROUP: PEC_GROUP); cdecl; external LIB_CRYPTO;

function EC_POINT_new(group: PEC_GROUP): PEC_POINT; cdecl; external LIB_CRYPTO;
procedure EC_POINT_free(EC_POINT: PEC_POINT); cdecl; external LIB_CRYPTO;

function BN_new(): PBIGNUM; cdecl; external LIB_CRYPTO;
procedure BN_free(bn: PBIGNUM); cdecl; external LIB_CRYPTO;

function BN_CTX_new(): PBN_CTX; cdecl; external LIB_CRYPTO;
procedure BN_CTX_free(ctx: PBN_CTX); cdecl; external LIB_CRYPTO;

function BN_dec2bn(bn: PBIGNUM; const str: PAnsiChar): Integer; cdecl; external LIB_CRYPTO;
function BN_hex2bn(bn: PBIGNUM; const str: PAnsiChar): Integer; cdecl; external LIB_CRYPTO;
function BN_bin2bn(s: PByte; len: Integer; ret: PBIGNUM): PBIGNUM; cdecl; external LIB_CRYPTO;
function BN_bn2bin(const bn: PBIGNUM; {out} s: PByte): Integer; cdecl; external LIB_CRYPTO;
function BN_bn2binpad(const bn: PBIGNUM; s: PByte; len:Integer): Integer; cdecl; external LIB_CRYPTO;
function BN_num_bits(const bn: PBIGNUM): Integer; cdecl; external LIB_CRYPTO;

// The string must be freed later using OPENSSL_free()
function BN_bn2dec(bn: PBIGNUM): PAnsiChar; cdecl; external LIB_CRYPTO;
function BN_bn2hex(bn: PBIGNUM): PAnsiChar; cdecl; external LIB_CRYPTO;

function BN_add(r: PBIGNUM; const a: PBIGNUM; const b: PBIGNUM): Integer; cdecl; external LIB_CRYPTO;
function BN_sub(r: PBIGNUM; const a: PBIGNUM; const b: PBIGNUM): Integer; cdecl; external LIB_CRYPTO;
function BN_mul(r: PBIGNUM; const a: PBIGNUM; const b: PBIGNUM; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;
function BN_cmp(const a: PBIGNUM; const b: PBIGNUM): Integer; cdecl; external LIB_CRYPTO;
function BN_div(dv: PBIGNUM; rem: PBIGNUM; const a: PBIGNUM; const b: PBIGNUM; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;

function BN_mod_inverse(r: PBIGNUM; const a: PBIGNUM; const n: PBIGNUM; ctx: PBN_CTX): PBIGNUM; cdecl; external LIB_CRYPTO;
function BN_mod_mul(r: PBIGNUM; const a: PBIGNUM; const b: PBIGNUM; const m: PBIGNUM; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;

function EC_POINT_mul(group: PEC_GROUP; r: PEC_POINT; n: PBIGNUM; p: PEC_POINT; m: PBIGNUM; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;
function EC_POINT_add(group: PEC_GROUP; r: PEC_POINT; a: PEC_POINT; b: PEC_POINT; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;
function EC_POINT_get_affine_coordinates_GFp(group: PEC_GROUP; p: PEC_POINT; x: PBIGNUM; y: PBIGNUM; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;
function EC_POINT_set_affine_coordinates_GFp(group: PEC_GROUP; p: PEC_POINT; x: PBIGNUM; y: PBIGNUM; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;
function EC_POINT_oct2point(group: PEC_GROUP;  r: PEC_POINT; const s: PByte; len: Integer; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;
function EC_POINT_is_at_infinity(group: PEC_GROUP; const p: PEC_POINT): Integer; cdecl; external LIB_CRYPTO;
function EC_POINTs_mul(group: PEC_GROUP; r: PEC_POINT; n: PBIGNUM; num: Integer;
  const points: Pointer{array of PEC_POINT}; const scalars: Pointer{array of PBIGNUM}; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;
function EC_POINT_is_on_curve(group: PEC_GROUP; const p: PEC_POINT; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;
function EC_POINT_point2oct(group: PEC_GROUP; const p: PEC_POINT;
  form: integer; out_: PByte; outlen: Cardinal; ctx: PBN_CTX): Cardinal; cdecl; external LIB_CRYPTO;

function EC_POINT_point2hex(group: PEC_GROUP; const p: PEC_POINT; form: integer; ctx: PBN_CTX): PAnsiChar; cdecl; external LIB_CRYPTO;

function EC_GROUP_get_order(group: PEC_GROUP; order: PBIGNUM; ctx: PBN_CTX): Integer; cdecl; external LIB_CRYPTO;
function EC_GROUP_get0_generator(group: PEC_GROUP): PEC_POINT; cdecl; external LIB_CRYPTO;

// Инициализация OpenSSL (вызвать один раз в начале программы)
function OpenSSL_version_num(): UInt64; cdecl; external LIB_CRYPTO;
procedure OpenSSL_add_all_digests(); cdecl; external LIB_CRYPTO;

function EVP_MD_fetch(libctx: Pointer; algorithm: PAnsiChar; properties: PAnsiChar): PEVP_MD; cdecl; external LIB_CRYPTO;
function EVP_get_digestbyname(name: PAnsiChar): PEVP_MD; cdecl; external LIB_CRYPTO;
function EVP_DigestInit_ex(ctx: PEVP_MD_CTX; md: PEVP_MD; impl: Pointer): Integer; cdecl; external LIB_CRYPTO;
function EVP_DigestUpdate(ctx: PEVP_MD_CTX; data: Pointer; len: NativeUInt): Integer; cdecl; external LIB_CRYPTO;
function EVP_DigestFinal_ex(ctx: PEVP_MD_CTX; md: PByte; size: PCardinal): Integer; cdecl; external LIB_CRYPTO;
procedure EVP_MD_free(md: PEVP_MD); cdecl; external LIB_CRYPTO;

function ERR_get_error: LongWord; cdecl; external LIB_CRYPTO;
function ERR_error_string(errCode: LongWord; buffer: PAnsiChar): PAnsiChar; cdecl; external LIB_CRYPTO;

implementation

end.

