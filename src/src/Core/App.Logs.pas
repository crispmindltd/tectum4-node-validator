unit App.Logs;

interface

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  App.Types;

type
  TLogLevel = (LOG_NONE = 0, LOG_INFO = 1, LOG_DEBUG = 2, LOG_TRACE = 3);

  TLog = class
    const
      KByte = 1024;
      MByte = KByte * 1024;
      MaxLogFileSize = 20 * MByte;
      MainLogsFolderName = 'logs';
    private
      FLogLevel: TLogLevel;
      FPath: string;
      FLogNum: UInt64;
      function CutLogString(const ALogStr: string): string;
      function IsValidLevel(Level: TLevel): Boolean;
      function GetFileName: string;
    public
      constructor Create(LogLevel: TLogLevel);
      procedure DoLog(const AText: string; Level: TLevel);
  end;

var
  Logs: TLog;

implementation

uses
  App.Intf;

constructor TLog.Create(LogLevel: TLogLevel);
begin
  FLogLevel := LogLevel;
  FPath := TPath.Combine(TPath.GetAppPath, MainLogsFolderName);
  FLogNum := 0;
end;

function TLog.CutLogString(const ALogStr: string): string;
begin
  var len := Length(ALogStr);
  if len <= 800 then
    Result := ALogStr
  else
    Result := Format('%s ... %s', [ALogStr.Substring(0, 400),
      ALogStr.Substring(len - 400, 400)]);
end;

function TLog.IsValidLevel(Level: TLevel): Boolean;
begin
  case FLogLevel of
    LOG_INFO:  Result := Level in [TLevel.INFO, TLevel.ERROR, TLevel.FATAL];
    LOG_DEBUG: Result := Level in [TLevel.INFO, TLevel.DEBUG, TLevel.ERROR, TLevel.FATAL];
    LOG_TRACE: Result := True;
    else       Result := False;
  end;
end;

function TLog.GetFileName: string;
begin
  var Name := FormatDateTime('yyyy-mm-dd', Now);
  Result := TPath.Combine(FPath, Name + '.log');
  if TFile.GetSize(Result) >= MaxLogFileSize then begin
    var I := 0;
    repeat
      Inc(I);
      Result := Format('%s(%d).log', [TPath.Combine(FPath, Name), I]);
    until not TFile.Exists(Result) or (TFile.GetSize(Result) < MaxLogFileSize);
  end;
end;

procedure TLog.DoLog(const AText: string; Level: TLevel);
begin
  if not Assigned(self) then Exit;
  if not IsValidLevel(Level) then Exit;

  Lock(Self);

  ForceDirectories(FPath);

  Inc(FLogNum);

  var ToLog := TStringBuilder.Create;
  AddRelease(ToLog);

  ToLog.Append(FLogNum);
  ToLog.Append(#9);
  ToLog.Append(FormatDateTime('dd.mm.yy hh:mm:ss.zzz', Now));

  case Level of
  TLevel.ERROR, TLevel.FATAL:
    ToLog.Append(' ! ');
  else
    ToLog.Append(' - ');
  end;

  ToLog.Append(CutLogString(AText));

  if Assigned(UI) then UI.DoMessage(ToLog.ToString);

  TFile.AppendAllText(GetFileName, ToLog.ToString + sLineBreak, TEncoding.ANSI);

end;

end.

