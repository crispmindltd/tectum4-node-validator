unit App.Types;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs;

type
  ERequireException = class(Exception)
  private
    FCode: Integer;
  public
    constructor Create(const Msg: string; Code: Integer);
    property Code: Integer read FCode;
  end;

  TCode = class
    class procedure Shuffle<T>(var A: TArray<T>);
    class function B(Value: UInt64): TBytes; inline;
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

class function TCode.B(Value: UInt64): TBytes;
begin
  Result := BytesOf(@Value, SizeOf(Value));
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
