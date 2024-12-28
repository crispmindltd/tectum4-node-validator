unit Blockchain.TETDynamic;

interface

uses
  App.Constants,
  Blockchain.BaseTypes,
  Blockchain.Intf,
  Classes,
  Generics.Collections,
  IOUtils,
  Math,
  SysUtils;

type
  TBlockchainTETDynamic = class(TChainFileBase)
  private
    FFile: file of TTokenBase;
    FIsOpened: Boolean;
  public
    constructor Create;
    destructor Destroy;
    function DoOpen: Boolean;
    procedure DoClose;

    function GetBlockSize: Integer; override;
    function GetBlocksCount: Integer; override;
    procedure WriteBlocksAsBytes(ASkipBlocks: Integer; ABytes: TBytes); override;
    procedure WriteBlock(ASkip: Integer; ABlock: TTokenBase);
    function TryReadBlock(ASkip: Integer; out ABlock: TTokenBase): Boolean;
    function ReadBlocksAsBytes(ASkipBlocks: Integer;
      ANumber: Integer = MaxBlocksNumber): TBytes; override;

    procedure GetTETAddresses(var ADict: TDictionary<Integer, string>);
    function TryGet(AUserID: Integer; out ABlockNum: Integer;
      var ATETDyn: TTokenBase): Boolean; overload;
    function TryGet(ATETAddress: string; out ABlockNum: Integer;
      out ATETDyn: TTokenBase): Boolean; overload;
  end;

implementation

{ TBlockchainTETDynamic }

constructor TBlockchainTETDynamic.Create;
begin
  inherited Create(ConstStr.DBCPath, ConstStr.Token64FileName);

  FIsOpened := False;
  if not FileExists(FFullFilePath) then
    TFile.WriteAllBytes(FFullFilePath, []);
end;

destructor TBlockchainTETDynamic.Destroy;
begin

  inherited;
end;

procedure TBlockchainTETDynamic.DoClose;
begin
  if FIsOpened then
  begin
    CloseFile(FFile);
    FIsOpened := False;
    FLock.Leave;
  end;
end;

function TBlockchainTETDynamic.DoOpen: Boolean;
begin
  Result := not FIsOpened;
  if Result then
  begin
    FLock.Enter;
    AssignFile(FFile, FFullFilePath);
    Reset(FFile);
    FIsOpened := True;
  end;
end;

function TBlockchainTETDynamic.GetBlocksCount: Integer;
var
  NeedClose: Boolean;
begin
  NeedClose := DoOpen;
  try
    Result := FileSize(FFile);
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTETDynamic.GetBlockSize: Integer;
begin
  Result := SizeOf(TTokenBase);
end;

procedure TBlockchainTETDynamic.GetTETAddresses(
  var ADict: TDictionary<Integer, string>);
var
  NeedClose: Boolean;
  i: Integer;
  TokenBaseBlock: TTokenBase;
begin
  NeedClose := DoOpen;
  try
    for i := FileSize(FFile) - 1 downto 0 do
    begin
      Seek(FFile, i);
      Read(FFile, TokenBaseBlock);
      if TokenBaseBlock.TokenDatID <> 1 then
        continue;

      if ADict.ContainsKey(TokenBaseBlock.OwnerID) then
        ADict.AddOrSetValue(TokenBaseBlock.OwnerID, TokenBaseBlock.Token);
      if not ADict.ContainsValue('') then
        break;
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTETDynamic.ReadBlocksAsBytes(ASkipBlocks,
  ANumber: Integer): TBytes;
var
  NeedClose: Boolean;
  BlockBytes: array[0..SizeOf(TTokenBase) - 1] of Byte;
  TokenBaseBlock: TTokenBase absolute BlockBytes;
  i: Integer;
begin
  Result := [];
  NeedClose := DoOpen;
  try
    if (ASkipBlocks >= FileSize(FFile)) or
      (ASkipBlocks < 0) then
      exit;

    Seek(FFile, ASkipBlocks);
    SetLength(Result, Min(ANumber, FileSize(FFile) - ASkipBlocks) * GetBlockSize);
    for i := 0 to (Length(Result) div GetBlockSize) - 1 do
    begin
      Read(FFile, TokenBaseBlock);
      Move(BlockBytes[0], Result[i * GetBlockSize], GetBlockSize);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTETDynamic.TryReadBlock(ASkip: Integer;
  out ABlock: TTokenBase): Boolean;
var
  NeedClose: Boolean;
begin
  NeedClose := DoOpen;
  try
    Result := (ASkip >= 0) and (ASkip < GetBlocksCount);
    if Result then
    begin
      Seek(FFile, ASkip);
      Read(FFile, ABlock);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

procedure TBlockchainTETDynamic.WriteBlocksAsBytes(ASkipBlocks: Integer;
  ABytes: TBytes);
var
  NeedClose: Boolean;
  BlockBytes: array[0..SizeOf(TTokenBase) - 1] of Byte;
  TokenBaseBlock: TTokenBase absolute BlockBytes;
  i: Integer;
begin
  if (Length(ABytes) mod GetBlockSize <> 0) or (ASkipBlocks < 0) then
    exit;

  NeedClose := DoOpen;
  try
    Seek(FFile, ASkipBlocks);
    for i := 0 to (Length(ABytes) div GetBlockSize) - 1 do
    begin
      Move(ABytes[i * GetBlockSize], BlockBytes[0], GetBlockSize);
      Write(FFile, TokenBaseBlock);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTETDynamic.TryGet(ATETAddress: string;
  out ABlockNum: Integer; out ATETDyn: TTokenBase): Boolean;
var
  NeedClose: Boolean;
  i: Integer;
begin
  Result := False;
  NeedClose := DoOpen;
  try
    Seek(FFile, 0);
    for i := 0 to FileSize(FFile) - 1 do
    begin
      Read(FFile, ATETDyn);
      if (ATETDyn.Token = ATETAddress) and (ATETDyn.TokenDatID = 1) then
      begin
        ABlockNum := i;
        exit(True);
      end;
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

procedure TBlockchainTETDynamic.WriteBlock(ASkip: Integer; ABlock: TTokenBase);
var
  NeedClose: Boolean;
begin
  if ASkip < 0 then
    exit;

  NeedClose := DoOpen;
  try
    Seek(FFile, ASkip);
    Write(FFile, ABlock);
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTETDynamic.TryGet(AUserID: Integer; out ABlockNum: Integer;
  var ATETDyn: TTokenBase): Boolean;
var
  NeedClose: Boolean;
  i: Integer;
begin
  Result := False;
  NeedClose := DoOpen;
  try
    Seek(FFile, 0);
    for i := 0 to FileSize(FFile) - 1 do
    begin
      Read(FFile, ATETDyn);
      if (ATETDyn.OwnerID = AUserID) and (ATETDyn.TokenDatID = 1) then
      begin
        ABlockNum := i;
        exit(True);
      end;
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

end.
