unit OpenURL;

interface

type
   TOpenURL = class
   public
     class procedure Open(const AURL:string);
   end;

implementation

uses
{$IF Defined(MSWINDOWS)}
Winapi.ShellAPI;
{$ELSE}
Posix.Stdlib;
{$ENDIF}

{ TOpenURL }

class procedure TOpenURL.Open(const AURL: string);
begin
{$IF Defined(MSWINDOWS)}
  ShellExecute({FmxHandleToHWND(Handle)} 0, 'open', PChar(AURL), '', '', 0);
{$ELSE}
  _system(PAnsiChar('open ' + AnsiString(AURL)))
{$ENDIF}
end;

end.
