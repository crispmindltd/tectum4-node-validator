unit Console;

interface

uses
  App.Logs,
  App.Exceptions,
  App.Types,
  App.Intf,
  System.SysUtils,
  System.SyncObjs,
  Classes,
{$IF Defined(MSWINDOWS)}
  Winapi.Windows;
{$ELSE}
  Posix.Unistd,
  Posix.StdLib,
  Posix.Signal;
{$ENDIF}

type
  TConsoleCore = class(TInterfacedObject, IUI)
  private
    FTotalBlocksNumberToLoad: UInt64;
  public
    constructor Create;
    destructor Destroy; override;

    procedure DoTerminate;
    procedure Run;
    procedure ShowMainForm;
    procedure NotifyNewTETBlocks;
    procedure DoConnectionFailed(const Address: string);
    procedure DoSynchronize(const Position, Count: UInt64);
    procedure DoMessage(const AMessage: string);
    procedure ShowMessage(const AMessage: string; OnCloseProc: TProc);
    procedure ShowException(const Reason: string; OnCloseProc: TProc);
    procedure ShowWarning(const Reason: string; OnCloseProc: TProc);
  end;

implementation

var
  ExitFlag: Boolean = False;

{$IF Defined(MSWINDOWS)}
function CtrlHandler(CtrlType: DWORD): BOOL; stdcall;
begin
  case CtrlType of
    CTRL_C_EVENT, //
      CTRL_BREAK_EVENT, //
      CTRL_CLOSE_EVENT: begin
        ExitFlag := True;
//        Logs.DoLog('Close event', DbgLvlLogs, ltNone);
        Result := True;
      end;
  else
    Result := False;
  end;
end;
{$ELSE}
procedure SignalHandler(Sig: Integer); cdecl;
begin
  case Sig of
    SIGINT, SIGTERM:
    begin
//      Logs.DoLog('Close event', DbgLvlLogs, ltNone);
      ExitFlag := True;
    end;
  end;
end;
{$ENDIF}

{ TConsoleCore }

constructor TConsoleCore.Create;
begin
{$IF Defined(MSWINDOWS)}
  SetConsoleCtrlHandler(@CtrlHandler, True);
{$ELSE}
  signal(SIGINT, @SignalHandler);
  signal(SIGTERM, @SignalHandler);
{$ENDIF}

  FTotalBlocksNumberToLoad := 0;
end;

destructor TConsoleCore.Destroy;
begin
  DoMessage('');
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
  ExitFlag := True;
end;

procedure TConsoleCore.NotifyNewTETBlocks;
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
  try
    while not ExitFlag do begin
      CheckSynchronize(100);

      if not Assigned(AppCore) then begin
        Logs.DoLog('AppCore = nil. Exiting.', DbgLvlLogs, ltNone);
        Break;
      end;

    end;
  finally
    Logs.DoLog('Terminating node...', DbgLvlLogs, ltNone);
  end;
end;

procedure TConsoleCore.ShowMainForm;
begin
end;

end.
