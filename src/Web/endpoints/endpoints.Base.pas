unit endpoints.Base;

interface

uses
  JSON,
  SysUtils;

type
  TEndpointsBase = class
  private
  protected
    function GetBodyParamsFromJSON(AJSON: TJSONObject): TArray<string>;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TEndpointsBase }

constructor TEndpointsBase.Create;
begin

end;

destructor TEndpointsBase.Destroy;
begin

  inherited;
end;

function TEndpointsBase.GetBodyParamsFromJSON(AJSON: TJSONObject): TArray<string>;
var
  JSONEnum: TJSONObject.TEnumerator;
  ParamStr: string;
begin
  Result := [];
  try
    JSONEnum := AJSON.GetEnumerator;
    while JSONEnum.MoveNext do
    begin
      ParamStr := JSONEnum.Current.ToString.Replace(':', '=');
      ParamStr := ParamStr.Replace('"', '', [rfReplaceAll]);
      ParamStr := ParamStr.Replace('[', '', [rfReplaceAll]);
      ParamStr := ParamStr.Replace(']', '', [rfReplaceAll]);
      Result := Result + [ParamStr];
    end;
  finally
    JSONEnum.Free;
  end;
end;

end.
