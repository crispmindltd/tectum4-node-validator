unit Blockchain.Intf;

interface

uses
  IOUtils,
  SyncObjs,
  SysUtils;

const
  MaxBlocksNumber = 3000;  // max blocks number per request

type
  TChainFileBase = class abstract
  protected
    FFileName: string;
    FFileFolder: string;
    FFullFilePath: string;
    FLock: TCriticalSection;

    function GetBlockSize: Integer; virtual; abstract;
    function GetBlocksCount: Integer; virtual; abstract;
    procedure WriteBlocksAsBytes(ASkipBlocks: Integer; ABytes: TBytes);
      virtual; abstract;
    function ReadBlocksAsBytes(ASkipBlocks: Integer;
      ANumber: Integer = MaxBlocksNumber): TBytes; virtual; abstract;
  public
    constructor Create(AFolder, AFileName: string);
    destructor Destroy; override;

    property Name: string read FFileName;
    property FullPath: string read FFullFilePath;
  end;

implementation

{ TChainFileBase }

constructor TChainFileBase.Create(AFolder, AFileName: string);
begin
  FFileName := AFileName;
  FFileFolder := TPath.Combine(ExtractFilePath(ParamStr(0)), AFolder);
  if not DirectoryExists(FFileFolder) then
    TDirectory.CreateDirectory(FFileFolder);
  FFullFilePath := TPath.Combine(FFileFolder, AFileName);

  FLock := TCriticalSection.Create;
end;

destructor TChainFileBase.Destroy;
begin
  FLock.Free;

  inherited;
end;

end.
