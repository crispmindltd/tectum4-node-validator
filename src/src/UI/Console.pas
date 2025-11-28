unit Console;

interface

uses
  App.Logs,
  App.Types,
  App.Intf,
  System.SysUtils,
  System.SyncObjs,
  System.Classes,
{$IFDEF MSWINDOWS}
  Winapi.Windows;
{$ELSE}
  Posix.Unistd,
  Posix.StdLib,
  Posix.Signal;
{$ENDIF}

type
  TConsoleCore = class(TInterfacedObject, IUI)
  public
    constructor Create;
    destructor Destroy; override;
    procedure DoTerminate;
    procedure Run;
    procedure ShowMainForm;
    procedure DataChange;
    procedure DoConnectionFailed(const Address: string);
    procedure DoSynchronize(const Position, Count: UInt64);
    procedure DoMessage(const AMessage: string);
    procedure ShowMessage(const AMessage: string; OnCloseProc: TProc);
    procedure ShowException(const Reason: string; OnCloseProc: TProc);
    procedure ShowWarning(const Reason: string; OnCloseProc: TProc);
  end;

implementation

var
  Terminated: Boolean = False;

{$IFDEF MSWINDOWS}

function CtrlHandler(CtrlType: DWORD): BOOL; stdcall;
begin
  if Assigned(Logs) then
    Logs.DoLog('CtrlHandler ' + CtrlType.ToString, DEBUG)
  else
    UI.DoMessage('CtrlHandler ' + CtrlType.ToString);

  case CtrlType of
    CTRL_C_EVENT, CTRL_BREAK_EVENT, CTRL_CLOSE_EVENT: begin
      Result := True;
      UI.DoTerminate;
      Sleep(10000); // It will not sleep, but it will allow the program to end correctly.
  end else
    Result := False;
  end;
end;

{$ELSE}

procedure SignalHandler(Sig: Integer); cdecl;
begin
  if Assigned(Logs) then
    Logs.DoLog('SignalHandler ' + Sig.ToString, DEBUG)
  else
    UI.DoMessage('SignalHandler ' + Sig.ToString);

  case Sig of
    SIGINT, SIGTERM: begin
      UI.DoTerminate;
//      Sleep(10000);
    end;
  end;
end;

{$ENDIF}

{ TConsoleCore }

constructor TConsoleCore.Create;
begin
{$IFDEF MSWINDOWS}
  SetConsoleCtrlHandler(@CtrlHandler, True);
{$ELSE}
  signal(SIGINT, @SignalHandler);
  signal(SIGTERM, @SignalHandler);
{$ENDIF}
end;

destructor TConsoleCore.Destroy;
begin
  inherited;
end;

procedure TConsoleCore.DoMessage(const AMessage: string);
begin
  Lock(Self);
  Writeln(AMessage);
end;

procedure TConsoleCore.ShowMessage(const AMessage: string; OnCloseProc: TProc);
begin
  DoMessage(AMessage);
  if Assigned(OnCloseProc) then OnCloseProc;
end;

procedure TConsoleCore.ShowException(const Reason: string; OnCloseProc: TProc);
begin
  DoMessage(Reason);
  if Assigned(OnCloseProc) then OnCloseProc;
end;

procedure TConsoleCore.ShowWarning(const Reason: string; OnCloseProc: TProc);
begin
  DoMessage(Reason);
  if Assigned(OnCloseProc) then OnCloseProc;
end;

procedure TConsoleCore.DoTerminate;
begin
  Terminated := True;
end;

procedure TConsoleCore.DataChange;
begin

end;

procedure TConsoleCore.DoSynchronize(const Position, Count: UInt64);
begin

end;

procedure TConsoleCore.DoConnectionFailed(const Address: string);
begin

end;

procedure TConsoleCore.Run;
begin
  DoMessage(Format('Tectum Node %s. Copyright (c) 2024 CrispMind.',
    [AppCore.GetAppVersionText]));
  DoMessage('Node is running. Press Ctrl-C to stop.');
  AppCore.Start;
  while not Terminated do CheckSynchronize(100);
  DoMessage('Terminating node...');
end;

procedure TConsoleCore.ShowMainForm;
begin

end;

end.
