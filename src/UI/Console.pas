unit Console;

interface

uses
  App.Exceptions,
  App.Intf,
  App.Updater,
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

    procedure DoMessage(const AMessage: string);
    procedure DoTerminate;
    procedure Run;
    procedure ShowVersionDidNotMatch;
    procedure ShowMainForm;
    procedure NotifyNewTETBlocks;
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
  Writeln(AMessage)
end;

procedure TConsoleCore.DoTerminate;
begin
  ExitFlag := True;
end;

procedure TConsoleCore.NotifyNewTETBlocks;
begin

end;

procedure TConsoleCore.Run;
begin
  DoMessage(Format('Tectum Light Node version %s. Copyright (c) 2024 CrispMind.',
    [Updater.CurVersion]));
  AppCore.Run;
  DoMessage('Lite node is running. Press Ctrl-C to stop.');

  {$IFDEF MSWINDOWS}
  var Msg: TMsg;
  while not ExitFlag do
  begin
    if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end else
      CheckSynchronize(100);
  end;
  {$ELSE}
  while not ExitFlag do
  begin
    CheckSynchronize(100);
  end;
  {$ENDIF}

  DoMessage('Terminating node...');
end;

procedure TConsoleCore.ShowMainForm;
begin
end;

procedure TConsoleCore.ShowVersionDidNotMatch;
begin
  DoMessage(NewVersionAvailableText);
end;

end.
