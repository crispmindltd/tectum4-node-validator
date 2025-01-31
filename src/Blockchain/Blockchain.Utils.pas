unit Blockchain.Utils;

interface

uses
  System.SysUtils,
  System.DateUtils,
  Blockchain.Data;

function AmountToStr(const Amount: Int64; WithName: Boolean=False): string;
function StrToAmount(S: string; Digits: Byte=8): UInt64;
function DateTimeUTC(DateTime: TDateTime): TDateTime;
function NowUTC: TDateTime;
function SafeSub(V,S: UInt64): UInt64;

implementation

function AmountToStr(const Amount: Int64; WithName: Boolean=False): string;
const Name: array[Boolean] of string = ('', ' TET');
begin
  Result := FormatFloat('0.########' + Name[WithName], Amount/_1_TET);
end;

function StrToAmount(S: string; Digits: Byte=8): UInt64;
begin
  var I := S.IndexOfAny(['.',',']);
  if I = -1 then
    I := S.Length
  else
    S := S.Remove(I,1);
  Result := (S + ''.Create('0', Digits)).Substring(0, I+Digits).ToInt64;
end;

function DateTimeUTC(DateTime: TDateTime): TDateTime;
begin
  Result := TTimeZone.Local.ToUniversalTime(DateTime);
end;

function NowUTC: TDateTime;
begin
  Result := DateTimeUTC(Now);
end;

function SafeSub(V,S: UInt64): UInt64;
begin
  if V > S then Result := V-S else Result := 0;
end;

end.
