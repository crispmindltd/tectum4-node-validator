unit endpoints.Account;

interface

uses
  App.Exceptions,
  App.Intf,
  Classes,
  endpoints.Base,
  JSON,
  IdCustomHTTPServer,
  IOUtils,
  server.Types,
  SyncObjs,
  SysUtils,
  WordsPool;

type
  TMainEndpoints = class(TEndpointsBase)
  public
    constructor Create;
    destructor Destroy; override;


  end;

implementation

{ TMainEndpoints }

constructor TMainEndpoints.Create;
begin
  inherited;
end;

destructor TMainEndpoints.Destroy;
begin

  inherited;
end;

end.
