unit App.Types;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs;

type
  TLevel = (TRACE = 0, DEBUG = 1, INFO = 2, ERROR = 3, FATAL = 4);

  ERequireException = class(Exception)
  private
    FCode: Integer;
  public
    constructor Create(const Msg: string; Code: Integer);
    property Code: Integer read FCode;
  end;

  TCode = class
    class procedure Shuffle<T>(var A: TArray<T>);
    class function ValueOf<T>(var P: PByte): T; overload;
    class function ValueOf<T>(const Bytes: TBytes; var Offset: Integer): T; overload;
    class function ValueOf<T>(const Bytes: TBytes): T; overload;
    class function StringOf(var P: PByte): string; overload;
    class function BytesOf<T>(const Value: T): TBytes; overload; //inline;
    class function StringOf(const Bytes: TBytes; var Offset: Integer): string; overload;
    class function BytesOf(const S: string): TBytes; overload;
    class function TrimValues(const Values: TArray<string>): TArray<string>;
    class procedure InMainThread(Proc: TThreadProcedure);
  end;

procedure Require(Condition: Boolean; const ExceptMessage: string; Code: Integer = 0);
procedure Stop(const ExceptMessage: string);

function AddRelease(Obj: TObject): IInterface;
function AddFinally(Proc: TProc): IInterface;
function Lock(Obj: TObject): IInterface;

implementation

constructor ERequireException.Create(const Msg: string; Code: Integer);
begin
  inherited Create(Msg);
  FCode := Code;
end;

procedure Require(Condition: Boolean; const ExceptMessage: string; Code: Integer);
begin
  if not Condition then
    raise ERequireException.Create(ExceptMessage,Code);
end;

procedure Stop(const ExceptMessage: string);
begin
  raise Exception.Create(ExceptMessage);
end;

type
  TDefer = class(TInterfacedObject)
  private
    FReleaseObject: TObject;
    FFinallyProc: TProc;
  public
    constructor Create(ReleaseObject: TObject); overload;
    constructor Create(FinallyProc: TProc); overload;
    destructor Destroy; override;
  end;

constructor TDefer.Create(ReleaseObject: TObject);
begin
  FReleaseObject := ReleaseObject;
end;

constructor TDefer.Create(FinallyProc: TProc);
begin
  FFinallyProc := FinallyProc;
end;

destructor TDefer.Destroy;
begin
  FReleaseObject.Free;
  if Assigned(FFinallyProc) then FFinallyProc;
end;

function AddRelease(Obj: TObject): IInterface;
begin
  Result := TDefer.Create(Obj);
end;

function AddFinally(Proc: TProc): IInterface;
begin
  Result := TDefer.Create(Proc);
end;

function Lock(Obj: TObject): IInterface;
begin
  TMonitor.Enter(Obj);
  Result := AddFinally(procedure
  begin
    TMonitor.Exit(Obj);
  end);
end;

class procedure TCode.Shuffle<T>(var A: TArray<T>);
begin
  Randomize;
  for var I := High(A) downto 1 do
  begin
    var J := Random(I);
    var V := A[I]; A[I] := A[J]; A[J] := V; // replace
  end;
end;

class function TCode.ValueOf<T>(var P: PByte): T;
type
  PT = ^T;
begin
  Result := PT(P)^;
  Inc(P, SizeOf(T));
end;

class function TCode.ValueOf<T>(const Bytes: TBytes; var Offset: Integer): T;
begin
  var P: PByte := @Bytes[Offset];
  var L := P;
  Result := ValueOf<T>(P);
  Inc(Offset, P - L);
end;

class function TCode.ValueOf<T>(const Bytes: TBytes): T;
type
  PT = ^T;
begin
  Result := PT(Bytes)^;
end;

class function TCode.StringOf(var P: PByte): string;
begin
  var Len := PInteger(P)^;
  Inc(P, SizeOf(Len));
  Result := TEncoding.UTF8.GetString(System.SysUtils.BytesOf(P, Len));
  Inc(P, Len);
end;

class function TCode.BytesOf<T>(const Value: T): TBytes;
begin
  Result := System.SysUtils.BytesOf(@Value, SizeOf(T));
end;

class function TCode.StringOf(const Bytes: TBytes; var Offset: Integer): string;
begin
  var P: PByte := @Bytes[Offset];
  var L := P;
  Result := StringOf(P);
  Inc(Offset, P - L);
end;

class function TCode.BytesOf(const S: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(S);
  var Len: Integer := Length(Result);
  Result := TCode.BytesOf(Len) + Result;
end;

class function TCode.TrimValues(const Values: TArray<string>): TArray<string>;
begin
  SetLength(Result, Length(Values));
  for var I := 0 to High(Values) do Result[I] := Values[I].Trim;
end;

class procedure TCode.InMainThread(Proc: TThreadProcedure);
begin
  TThread.Queue(nil, Proc);
end;

end.
