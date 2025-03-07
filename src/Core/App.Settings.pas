unit App.Settings;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.IniFiles,
  Net.Data,
  App.Constants,
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
    function GetLogsLevel: Byte;
    function GetAddress: string;
    function GetNodes: TArray<string>;
    function GetServers: TArray<string>;
    procedure SetAddress(const Address: string);
  public
    constructor Create;
    destructor Destroy; override;
    property AutoUpdate: Boolean read GetAutoUpdate;
    property LogsLevel: Byte read GetLogsLevel;
    property Address: string read GetAddress write SetAddress;
    property Nodes: TArray<string> read GetNodes;
    property Servers: TArray<string> read GetServers;
    property HTTPEnabled: Boolean read GetHTTPEnabled;
    property HTTPPort: Word read GetHTTPPort;
  end;

implementation

{ TSettings }

constructor TSettings.Create;
begin
  TrueBoolStrs := [DefaultTrueBoolStr, 'yes', 'y', '1'];
  FalseBoolStrs := [DefaultFalseBoolStr, 'no', 'n', '0'];
  FPath := TPath.GetAppPath;
  FFileName := TPath.Combine(FPath, ConstStr.SettingsFileName);
  FIni := TIniFile.Create(FFileName);
  if not FileExists(FFileName) then  //initialize the .ini file if it doesn’t already exist
  begin
    FIni.WriteString('connections', 'listen_to', DefaultTCPListenTo);
    FIni.WriteString('connections', 'nodes', '[' + DefaultNodeAddress + ']');
    FIni.WriteString('http', 'enabled', BoolToStr(True, True));
    FIni.WriteInteger('http', 'port', DefaultPortHTTP);
    FIni.WriteString('settings', 'auto_update', BoolToStr(True, True));
    FIni.WriteInteger('settings', 'logs_level', CmnLvlLogs);
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

function TSettings.GetLogsLevel: Byte;
begin
  Result := FIni.ReadInteger('settings', 'logs_level', CmnLvlLogs);
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

end.
