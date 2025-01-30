unit App.Types;

interface

uses
  System.SysUtils;

type
  ERequireException = class(Exception)
  private
    FCode: Integer;
  public
    constructor Create(const Msg: string; Code: Integer);
    property Code: Integer read FCode;
  end;

procedure Require(Condition: Boolean; const ExceptMessage: string; Code: Integer=0);
procedure Stop(const ExceptMessage: string);

function AddRelease(Obj: TObject): IInterface;
function AddFinally(Proc: TProc): IInterface;

implementation

constructor ERequireException.Create(const Msg: string; Code: Integer);
begin
  inherited Create(Msg);
  FCode:=Code;
end;

procedure Require(Condition: Boolean; const ExceptMessage: string; Code: Integer);
begin
  if not Condition then raise ERequireException.Create(ExceptMessage,Code);
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
  FReleaseObject:=ReleaseObject;
end;

constructor TDefer.Create(FinallyProc: TProc);
begin
  FFinallyProc:=FinallyProc;
end;

destructor TDefer.Destroy;
begin
  FReleaseObject.Free;
  if Assigned(FFinallyProc) then FFinallyProc;
end;

function AddRelease(Obj: TObject): IInterface;
begin
  Result:=TDefer.Create(Obj);
end;

function AddFinally(Proc: TProc): IInterface;
begin
  Result:=TDefer.Create(Proc);
end;

end.
