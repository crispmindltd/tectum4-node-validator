unit App.Settings;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.IniFiles,
  Net.Data,
  App.Types,
  App.Logs;

type
  TSettings = class
  private
    FPath: string;
    FFileName: string;
    FIni: TIniFile;
    function GetHTTPPort: Word;
    function GetHTTPEnabled: Boolean;
    function GetAutoUpdate: Boolean;
    function GetLogsLevel: TLogLevel;
    function GetAddress: string;
    function GetNodes: TArray<string>;
    function GetServers: TArray<string>;
    procedure SetAddress(const Address: string);
    function GetMinerEnabled: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property AutoUpdate: Boolean read GetAutoUpdate;
    property LogsLevel: TLogLevel read GetLogsLevel;
    property Address: string read GetAddress write SetAddress;
    property Nodes: TArray<string> read GetNodes;
    property Servers: TArray<string> read GetServers;
    property HTTPEnabled: Boolean read GetHTTPEnabled;
    property HTTPPort: Word read GetHTTPPort;
    property MinerEnabled: Boolean read GetMinerEnabled;
  end;

implementation

{ TSettings }

constructor TSettings.Create;
begin
  TrueBoolStrs := [DefaultTrueBoolStr, 'yes', 'y', '1'];
  FalseBoolStrs := [DefaultFalseBoolStr, 'no', 'n', '0'];
  FPath := TPath.GetAppPath;
  FFileName := TPath.Combine(FPath, 'settings.ini');
  FIni := TIniFile.Create(FFileName);
  if not FileExists(FFileName) then  //initialize the .ini file if it doesn’t already exist
  begin
    FIni.WriteString('connections', 'listen_to', DefaultTCPListenTo);
    FIni.WriteString('connections', 'nodes', '[' + DefaultNodeAddress + ']');
    FIni.WriteString('http', 'enabled', 'y');
    FIni.WriteInteger('http', 'port', DefaultPortHTTP);
    FIni.WriteString('settings', 'auto_update', 'y');
    FIni.WriteString('settings', 'logs_level', 'info');
    FIni.WriteString('miner', 'enabled', 'false');
    FIni.UpdateFile;
  end;
end;

destructor TSettings.Destroy;
begin
  FIni.Free;
  inherited;
end;

function TSettings.GetAddress: string;
begin
  Result := FIni.ReadString('settings', 'address', '');
end;

function TSettings.GetAutoUpdate: Boolean;
begin
  Result := StrToBool(FIni.ReadString('settings', 'auto_update', DefaultTrueBoolStr));
end;

function TSettings.GetHTTPEnabled: Boolean;
begin
  Result := StrToBool(FIni.ReadString('http', 'enabled', DefaultTrueBoolStr));
end;

function TSettings.GetHTTPPort: Word;
begin
  Result := FIni.ReadInteger('http', 'port', DefaultPortHTTP);
end;

function TSettings.GetLogsLevel: TLogLevel;
const
  LevelMapEntry: array[TLogLevel] of TIdentMapEntry = (
    (Value: 0; Name: 'none'),
    (Value: 1; Name: 'info'),
    (Value: 2; Name: 'debug'),
    (Value: 3; Name: 'trace'));
begin
  var Ident := FIni.ReadString('settings', 'logs_level', 'info');
  var Value := Byte(TLogLevel.LOG_INFO);
  if not IdentToInt(Ident, Value, LevelMapEntry) then
    Value := StrToIntDef(Ident, Value);
  if Value < Byte(LOG_NONE) then
    Result := LOG_NONE
  else if Value > Byte(LOG_TRACE) then
    Result := LOG_TRACE
  else
    Result := TLogLevel(Value);
end;

function TSettings.GetNodes: TArray<string>;
begin
  var Value := FIni.ReadString('connections', 'nodes', DefaultNodeAddress).
    TrimLeft(['[']).TrimRight([']']);
  Result := TCode.TrimValues(Value.Split([',']));
end;

function TSettings.GetServers: TArray<string>;
begin
  var Value := FIni.ReadString('connections', 'listen_to', DefaultTCPListenTo).
    TrimLeft(['[']).TrimRight([']']);
  Result := TCode.TrimValues(Value.Split([',']));
end;

procedure TSettings.SetAddress(const Address: string);
begin
  FIni.WriteString('settings', 'address', Address);
end;

function TSettings.GetMinerEnabled: Boolean;
begin
  Result := StrToBool(FIni.ReadString('miner', 'enabled', DefaultFalseBoolStr));
end;

end.
