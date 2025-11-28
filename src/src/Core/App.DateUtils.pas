unit App.DateUtils;

interface

uses
  System.SysUtils,
  System.DateUtils;

type
  TUnixTime = type Int64;
  TUnixTimestamp = type Int64; // Unix time in milliseconds (GMT)

  TUnixTimestampHelper = record helper for TUnixTimestamp
    class function Now: TUnixTimestamp; static;
    class function FromDateTime(const Value: TDateTime; InputIsUTC: Boolean): TUnixTimestamp; static;
    procedure SetUnixTime(const Value: TUnixTime);
    function ToUnixTime: TUnixTime;
    procedure SetDateTime(const Value: TDateTime; InputIsUTC: Boolean);
    function ToDateTime(ReturnUTC: Boolean): TDateTime;
    function ToString(isFormatted:Boolean = False): string;
  end;

implementation

class function TUnixTimestampHelper.Now: TUnixTimestamp;
begin
  Result.SetDateTime(TDateTime.NowUtc, True);
end;

class function TUnixTimestampHelper.FromDateTime(const Value: TDateTime; InputIsUTC: Boolean): TUnixTimestamp;
begin
  Result.SetDateTime(Value, InputIsUTC);
end;

procedure TUnixTimestampHelper.SetUnixTime(const Value: TUnixTime);
begin
  Self := Value * 1000;
end;

function TUnixTimestampHelper.ToUnixTime: TUnixTime;
begin
  Result := Trunc(Self / 1000);
end;

procedure TUnixTimestampHelper.SetDateTime(const Value: TDateTime; InputIsUTC: Boolean);
var V: TDateTime;
begin
  if InputIsUTC then
    V := Value
  else
    V := TTimeZone.Local.ToUniversalTime(Value);
  Self := Round((V - UnixDateDelta) * 86400000);
end;

function TUnixTimestampHelper.ToDateTime(ReturnUTC: Boolean): TDateTime;
begin
  Result := (Self / 86400000) + UnixDateDelta;
  if not ReturnUTC then
    Result := TTimeZone.Local.ToLocalTime(Result);
end;

function TUnixTimestampHelper.ToString(isFormatted:Boolean = False): string;
begin
  if isFormatted then
    Result := FormatDateTime('yyyy-mm-dd-hh:nn:ss',Self.ToDateTime({isUTC}True))
  else
    Result := Int64.ToString(Self);
end;

initialization

end.
