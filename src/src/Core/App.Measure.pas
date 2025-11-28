unit App.Measure;

interface

uses
  System.SysUtils,
  System.Classes;

type
  TMeasure = record
    V: TArray<string>;
    StartTime: Cardinal;
    StopTime: Cardinal;
    class function Start: TMeasure; static;
    function Step(Text: string): TMeasure;
    procedure Stop;
    function Elapsed: Cardinal;
    function ToString: string;
  end;

implementation

class function TMeasure.Start: TMeasure;
begin
  Result:= Default(TMeasure);
  Result.Stop;
  Result.StartTime := Result.StopTime;
end;

function TMeasure.Step(Text: string): TMeasure;
begin
  var Time := StopTime;
  Stop;
  V := V + [Format(Text, [StopTime - Time])];
  Result := Self;
end;

procedure TMeasure.Stop;
begin
  StopTime := TThread.GetTickCount;
end;

function TMeasure.Elapsed: Cardinal;
begin
  Result := StopTime - StartTime;
end;

function TMeasure.ToString: string;
begin
  Result := ''.Join(', ', V);
end;

end.
