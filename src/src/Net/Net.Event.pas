unit Net.Event;

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs;

type
  IWait = interface
    procedure SetSuccess(Value: Boolean);
    function GetSuccess: Boolean;
    procedure SetResultBytes(Value: TBytes);
    function GetResultBytes: TBytes;
    function WaitFor(Timeout: Cardinal = INFINITE): Boolean;
    procedure Complete;
    property Success: Boolean read GetSuccess write SetSuccess;
    property ResultBytes: TBytes read GetResultBytes write SetResultBytes;
  end;

  TWait = class(TInterfacedObject, IWait)
  private
    FEvent: TEvent;
    FSuccess: Boolean;
    FResultBytes: TBytes;
    function WaitFor(Timeout: Cardinal = INFINITE): Boolean;
    procedure Complete;
    procedure SetSuccess(Value: Boolean);
    function GetSuccess: Boolean;
    procedure SetResultBytes(Value: TBytes);
    function GetResultBytes: TBytes;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TWait.Create;
begin
  FSuccess := False;
  FResultBytes := TEncoding.ANSI.GetBytes('Timeout');
  FEvent := TEvent.Create;
end;

destructor TWait.Destroy;
begin
  FEvent.Free;
  inherited;
end;

function TWait.GetResultBytes: TBytes;
begin
  Result := FResultBytes;
end;

function TWait.GetSuccess: Boolean;
begin
  Result := FSuccess;
end;

procedure TWait.Complete;
begin
  FEvent.SetEvent;
end;

procedure TWait.SetResultBytes(Value: TBytes);
begin
  FResultBytes := Value;
end;

procedure TWait.SetSuccess(Value: Boolean);
begin
  FSuccess := Value;
end;

function TWait.WaitFor(Timeout: Cardinal): Boolean;
begin
  FEvent.ResetEvent;
  Result := FEvent.WaitFor(Timeout) = wrSignaled;
end;

end.


