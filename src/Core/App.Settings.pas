unit App.Settings;

interface

uses
  App.Constants,
  App.Logs,
  IniFiles,
  IOUtils,
  Net.Data,
  SysUtils;

type
  TSettingsFile = class
    private
      FPath: string;
      FIni: TIniFile;

      function GetFullPath: string;
      function CheckAddress(const AAddress: string): Boolean;
      procedure FillNodesList(AAddresses: string);
      procedure SetHTTPPort(APort: string);

      function GetHTTPEnabled: Boolean;
      function GetAutoUpdate: Boolean;
      function GetLogsLevel: Byte;
      function GetAddress: string;
    public
      constructor Create;
      destructor Destroy; override;

      procedure Init;
      procedure SetAddress(const Address: string);

      property EnabledHTTP: Boolean read GetHTTPEnabled;
      property AutoUpdate: Boolean read GetAutoUpdate;
      property LogsLevel: Byte read GetLogsLevel;
      property Address: string read GetAddress;
  end;

implementation

{ TSettingsFile }

function TSettingsFile.CheckAddress(const AAddress: string): Boolean;
var
  i, j: Integer;
  Splitted: TArray<string>;
begin
  if not(AAddress.Contains('.') and AAddress.Contains(':')) then
    exit(False);
  Splitted := AAddress.Split(['.', ':']);
  if (Length(Splitted) <> 5) then
    exit(False);
  for i := 0 to Length(Splitted) - 1 do
    if not TryStrToInt(Splitted[i], j) then
      exit(False);

  Result := True;
end;

constructor TSettingsFile.Create;
begin
  FPath := ExtractFilePath(ParamStr(0));

  FIni := TIniFile.Create(GetFullPath);
  if not FileExists(GetFullPath) then  //initialize the .ini file if it doesn’t already exist
  begin
    FIni.WriteString('connections', 'listen_to', DefaultTCPListenTo);
    FIni.WriteString('connections', 'nodes', Format('[%s]', [DefaultNodeAddress]));
    FIni.WriteString('http', 'enabled', BoolToStr(True, True));
    FIni.WriteString('http', 'port', DefaultPortHTTP.ToString);
    FIni.WriteString('settings', 'auto_update', BoolToStr(True, True));
    FIni.WriteInteger('settings', 'logs_level', CmnLvlLogs);
    FIni.UpdateFile;
  end;
end;

destructor TSettingsFile.Destroy;
begin
  FIni.Free;

  inherited;
end;

procedure TSettingsFile.FillNodesList(AAddresses: string);
var
  i: Integer;
  Splitted: TArray<string>;
begin
  Splitted := AAddresses.Trim(['[', ']']).Split([',']);
  if Length(Splitted) = 0 then
    exit;

  for i := 0 to Length(Splitted) - 1 do
    if Splitted[i] <> ListenTo then
      Nodes.AddNodeToPool(Splitted[i]);
end;

function TSettingsFile.GetAddress: string;
begin
  Result := FIni.ReadString('settings', 'address', '');
end;

function TSettingsFile.GetAutoUpdate: Boolean;
begin
  Result := StrToBool(FIni.ReadString('settings', 'auto_update', 'True'));
end;

function TSettingsFile.GetFullPath: string;
begin
  Result := TPath.Combine(FPath, ConstStr.SettingsFileName);
end;

function TSettingsFile.GetHTTPEnabled: Boolean;
begin
  Result := StrToBool(FIni.ReadString('http', 'enabled', 'True'));
end;

function TSettingsFile.GetLogsLevel: Byte;
begin
  Result := FIni.ReadInteger('settings', 'logs_level', CmnLvlLogs);
end;

procedure TSettingsFile.Init;
var
  Value: string;
begin
  if not FileExists(GetFullPath) then
    raise Exception.Create('Settings file not found. Please, restart the application');

  Value := FIni.ReadString('connections', 'listen_to', '');
  if Value.IsEmpty then
    raise Exception.Create('incorrect settings file');
  if CheckAddress(Value) then
    ListenTo := Value
  else
    raise Exception.Create(Format('address "%s" is invalid', [Value]));

  Value := FIni.ReadString('connections', 'nodes', '');
  FillNodesList(Value);

  Value := FIni.ReadString('http', 'port', '');
  if Value.IsEmpty then
    raise Exception.Create('incorrect settings file');
  SetHTTPPort(Value);
end;

procedure TSettingsFile.SetHTTPPort(APort: string);
var
  PortValue: Integer;
begin
  if (not TryStrToInt(APort, PortValue)) or (PortValue > 65535) or (PortValue < 0) then
    raise Exception.Create(Format('HTTP port "%s" is invalid', [APort]));

  HTTPPort := PortValue;
end;

procedure TSettingsFile.SetAddress(const Address: string);
begin
  FIni.WriteString('settings', 'address', Address);
end;

end.
