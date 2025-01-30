unit Update.Utils;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Zip,
  App.Types;

type

  TFolder = record

    class function Combine(const Path,FileName: string): string; static;
    class function GetAppPath: string; static;
    class function GetShareDataPath: string; static;
    class function GetDataPath(const AppName: string): string; static;
    class function GetLibraryPath: string; static;
    class function GetProgramsPath: string; static;
    class function GetTempPath: string; static;

    class function GetHomePath: string; static;
    class function GetSharedHomePath: string; static;
    class function GetDocumentsPath: string; static;
    class function GetSharedDocumentsPath: string; static;
    class function GetPicturesPath: string; static;
    class function GetSharedPicturesPath: string; static;
    class function GetDownloadsPath: string; static;
    class function GetSharedDownloadsPath: string; static;

  end;

procedure OpenLink(const FileLink: string);
function GetAppVersion: string;
function IsInstalledFromStore: Boolean;
function InstallPackage(const PackageApp: string): Boolean;
function UpdatePackage(const ExecuteApp,PackageApp: string): Boolean;

implementation

{$IFDEF MSWINDOWS}

uses
  Winapi.Windows, Winapi.ActiveX, Winapi.ShlObj, Winapi.ShellAPI,
  Winapi.KnownFolders, System.Win.ComObj;

function GetKnownFolderPath(const rfid: TIID): string;
var LStr: PChar;
begin
  if SHGetKnownFolderPath(rfid,0,0,LStr)=0 then
  begin
    Result:=LStr;
    CoTaskMemFree(LStr);
  end else
    Result := '';
end;

function GetFileVersion(const AFileName: string): string;
var
  FileName: string;
  InfoSize, Wnd: DWORD;
  VerBuf: Pointer;
  FI: PVSFixedFileInfo;
  VerSize: DWORD;
begin
  Result:='';
  // GetFileVersionInfo modifies the filename parameter data while parsing.
  // Copy the string const into a local variable to create a writeable copy.
  FileName:=AFileName;
  UniqueString(FileName);
  InfoSize:=GetFileVersionInfoSize(PChar(FileName),Wnd);
  if InfoSize<>0 then
  begin
    GetMem(VerBuf,InfoSize);
    try
      if GetFileVersionInfo(PChar(FileName),Wnd,InfoSize,VerBuf) then
      if VerQueryValue(VerBuf,'\',Pointer(FI),VerSize) then
        Result:=Format('%d.%d.%d',[HiWord(FI.dwFileVersionMS),LoWord(FI.dwFileVersionMS),HiWord(FI.dwFileVersionLS)]);
    finally
      FreeMem(VerBuf);
    end;
  end;
end;

{$ENDIF}

{$IFDEF ANDROID}

uses
  Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.JavaTypes, Androidapi.JNI.Webkit, Androidapi.JNI.Net, Androidapi.JNIBridge,
  Androidapi.JNI.App, Androidapi.JNI.Support, FMX.Platform.Android, Androidapi.JNI.Provider,
  Androidapi.JNI.Widget, Androidapi.JNI.Embarcadero, Androidapi.IOUtils,
  Dialogs.Android, SaveDialog.Android;

{$ENDIF}

{$IFDEF MACOS}

{$IFDEF IOS}

uses
  iOSapi.Foundation, FMX.Helpers.iOS, iOSapi.UIKit, Macapi.CoreFoundation,
  Macapi.Helpers, SaveDialog.iOS, Dialogs.iOS;

{$ELSE}

uses
  Macapi.Foundation, Macapi.AppKit, Macapi.CoreFoundation, Macapi.Helpers,
  Macapi.IOKit;

{$ENDIF}

function GetMacApplicationSupportDirectory: string;
var
  URL: NSURL;
  BundleIdentifier: string;
begin

  URL:=TNSFileManager.Wrap(TNSFileManager.OCClass.defaultManager).URLForDirectory(
    NSApplicationSupportDirectory,NSUserDomainMask,nil,True,nil);

  if URL<>nil then
    Result:=UTF8ToString(URL.path.UTF8String)
  else
    Result:=TPath.GetLibraryPath;

  BundleIdentifier:=NSStrToStr(TNSBundle.Wrap(TNSBundle.OCClass.mainBundle).bundleIdentifier);

  Panic(BundleIdentifier='','undefined CFBundleIdentifier');

  Result:=TPath.Combine(Result,BundleIdentifier);

end;

{$ENDIF}

{$IFDEF LINUX}

uses
  Posix.Fcntl,Posix.Stdlib,Posix.SysStatvfs, Posix.Unistd;

{$ENDIF}

class function TFolder.Combine(const Path,FileName: string): string;
begin
  Result:=TPath.Combine(Path,FileName);
end;

class function TFolder.GetAppPath: string;
{$IFDEF LINUX}
var Buffer: array [0..MAX_PATH] of Char;
begin
  SetString(Result,Buffer,GetModuleFileName(0,Buffer,Length(Buffer)));
end;
{$ELSE}
begin
  {$IFDEF ANDROID}
  Result:=JStringToString(SharedActivityContext.getPackageCodePath);
  {$ELSE}
  Result:=ParamStr(0);
  {$ENDIF}
end;
{$ENDIF}

class function TFolder.GetShareDataPath: string;
begin

  {$IFDEF MSWINDOWS}
  Result:=TPath.GetPublicPath;
  {$ELSE}
  Result:=TFolder.GetSharedDownloadsPath;
  {$ENDIF}

end;

class function TFolder.GetDataPath(const AppName: string): string;
begin

  {$IFDEF MSWINDOWS}
  Result:=TPath.GetLibraryPath;
  {$ENDIF}

  {$IFDEF ANDROID}
  Result:=TPath.GetDocumentsPath;
  {$ENDIF}

  {$IFDEF MACOS}{$IFDEF IOS}
  Result:=TPath.GetDocumentsPath;
  {$ELSE}
  Result:=GetMacApplicationSupportDirectory;
  {$ENDIF}{$ENDIF}

  {$IFDEF LINUX}
  Result:=Combine(GetHomePath,'.'+AppName);
  {$ENDIF}

end;

class function TFolder.GetLibraryPath: string;
begin
  Result:=TPath.GetLibraryPath;
end;

class function TFolder.GetTempPath: string;
begin
  Result:=TPath.GetTempPath;
end;

class function TFolder.GetProgramsPath: string;
begin
  Result:='';
  {$IFDEF MSWINDOWS}
  Result:='C:\Programs';
  {$ENDIF}
  {$IFDEF LINUX}
  Result:=Combine(TPath.GetHomePath,'Programs');
  {$ENDIF}
end;

class function TFolder.GetHomePath: string;
begin
  Result:='';
  {$IFDEF MSWINDOWS}
  Result:=GetKnownFolderPath(FOLDERID_Profile);
  {$ENDIF}
  if Result='' then Result:=TPath.GetHomePath;
end;

class function TFolder.GetSharedHomePath: string;
begin
  Result:=GetHomePath;
end;

class function TFolder.GetDocumentsPath: string;
begin
  Result:='';
  {$IFDEF MSWINDOWS}
  Result:=GetKnownFolderPath(FOLDERID_Documents);
  {$ENDIF}
  if Result='' then Result:=TPath.GetDocumentsPath;
end;

class function TFolder.GetSharedDocumentsPath: string;
begin
  Result:='';
  {$IFDEF MSWINDOWS}
  Result:=GetKnownFolderPath(FOLDERID_Documents);
  {$ENDIF}
  if Result='' then Result:=TPath.GetSharedDocumentsPath;
end;

class function TFolder.GetPicturesPath: string;
begin
  Result:='';
  {$IFDEF MSWINDOWS}
  Result:=GetKnownFolderPath(FOLDERID_Pictures);
  {$ENDIF}
  if Result='' then Result:=TPath.GetPicturesPath;
end;

class function TFolder.GetSharedPicturesPath: string;
begin
  Result:='';
  {$IFDEF MSWINDOWS}
  Result:=GetKnownFolderPath(FOLDERID_Pictures);
  {$ENDIF}
  if Result='' then Result:=TPath.GetSharedPicturesPath;
end;

class function TFolder.GetDownloadsPath: string;
begin
  Result:='';
  {$IFDEF MSWINDOWS}
  Result:=GetKnownFolderPath(FOLDERID_Downloads);
  {$ENDIF}
  if Result='' then Result:=TPath.GetDownloadsPath;
end;

class function TFolder.GetSharedDownloadsPath: string;
begin
  Result:='';
  {$IFDEF MSWINDOWS}
  Result:=GetKnownFolderPath(FOLDERID_Downloads);
  {$ENDIF}
  {$IFDEF IOS}
  Result:=TPath.GetCachePath;
  {$ENDIF}
  if Result='' then Result:=TPath.GetSharedDownloadsPath;
end;

function IsInstalledFromStore: Boolean;
begin

  Result:=False;

  {$IFDEF ANDROID}

  // https://stackoverflow.com/questions/10809438/how-to-know-an-application-is-installed-from-google-play-or-side-load

  var AppContext:=TAndroidHelper.Context;

  if AppContext<>nil then
  begin
    var PackageManager:=AppContext.getPackageManager;
    if PackageManager<>nil then
      Result:=not JStringToString(AppContext.getPackageManager.getInstallerPackageName(AppContext.getPackageName)).isEmpty;
  end;

  {$ENDIF}

  {$IFDEF IOS}

  Result:=True;

  {$ENDIF}

end;

{$IFDEF MSWINDOWS}

function GetAppVersion: string;
begin
  Result:=GetFileVersion(TFolder.GetAppPath);
end;

{$ELSE}

{$IFDEF LINUX}

function GetAppVersion: string;
begin
  Result:={$I linux-version.inc};
end;

{$ELSE}

function GetAppVersion: string;
begin
  Result:=IFMXApplicationService(TPlatformServices.Current.GetPlatformService(IFMXApplicationService)).AppVersion;
end;

{$ENDIF}

{$ENDIF}

{$IFDEF MSWINDOWS}

function Exec(const Command: string): Boolean;
var
  ProcessInformation: TProcessInformation;
  StartupInfo: TStartupInfo;
begin

  StartupInfo:=Default(TStartupInfo);

  StartupInfo.lpDesktop:=nil;
  StartupInfo.lpTitle:=nil;
  StartupInfo.dwFlags:=STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow:=SW_SHOW;

  Result:=CreateProcess(nil,PWideChar(Command),nil,nil,False,CREATE_DEFAULT_ERROR_MODE,
    nil,nil,StartupInfo,ProcessInformation);

end;

procedure OpenLink(const FileLink: string);
begin
  ShellExecute(0,'open',PChar(FileLink),nil,nil,SW_SHOWDEFAULT);
end;

{$ENDIF}

{$IFDEF ANDROID}

function InstallPackage(const PackageApp: string): Boolean;
begin
  Result:=True;
  OpenIntent(PackageApp,TJIntent.JavaClass.ACTION_INSTALL_PACKAGE);
end;

function UpdatePackage(const ExecuteApp,PackageApp: string): Boolean;
begin
  Result:=True;
end;

procedure OpenLink(const FileLink: string);
begin
  OpenIntent(FileLink,TJIntent.JavaClass.ACTION_VIEW);
end;

{$ENDIF}

{$IFDEF MACOS}

{$IFDEF IOS}

procedure OpenLink(const FileLink: string);
begin
  iOSPreviewFile(FileLink);
end;

function InstallPackage(const PackageApp: string): Boolean;
begin
  Result:=False;
end;

function UpdatePackage(const ExecuteApp,PackageApp: string): Boolean;
begin
  Result:=False;
end;

{$ELSE}

procedure OpenLink(const FileLink: string);
begin
  TNSWorkspace.Wrap(TNSWorkspace.OCClass.sharedWorkspace).openFile(NSStr(FileLink));
end;

function InstallPackage(const PackageApp: string): Boolean;
begin

  Result:=True;

  OpenLink(PackageApp);

end;

function UpdatePackage(const ExecuteApp,PackageApp: string): Boolean;
begin
  Result:=False;
end;

{$ENDIF}

{$ENDIF}

{$IFDEF LINUX}

function Exec(const FileLink: string): Boolean;
var M: TMarshaller;
begin
  Result:=_system(M.AsUtf8(FileLink+' &').ToPointer)<>-1;
end;

procedure OpenLink(const FileLink: string);
var M: TMarshaller;
begin
 _system(M.AsUtf8(FileLink+' &').ToPointer);
end;

{$ENDIF}

{$IF DEFINED(LINUX) OR DEFINED(MSWINDOWS)}

procedure Unzip(const ZipFileName,DestPath: string);
begin

  var ZipFile:=TZipFile.Create;

  AddRelease(ZipFile);

  ZipFile.Open(ZipFileName,TZipMode.zmRead);

  for var FileName in ZipFile.FileNames do ZipFile.Extract(FileName,DestPath);

end;

function UnzipThis(const ZipFileName,ThisFileName,DestPath: string): Boolean;
begin

  var ZipFile:=TZipFile.Create;

  AddRelease(ZipFile);

  ZipFile.Open(ZipFileName,TZipMode.zmRead);

  for var FileName in ZipFile.FileNames do
  if string.Compare(FileName,ThisFileName,True)=0 then
  begin
    ZipFile.Extract(FileName,DestPath);
    Exit(True);
  end;

  Result:=False;

end;

procedure DeleteFile(const FilePath: string);
begin
  try
    TFile.Delete(FilePath);
  except begin
    Sleep(3000);
    TFile.Delete(FilePath); // second attempt
  end;
  end;
end;

function FileIsZip(const FileName: string): Boolean;
begin
  Result:=FileName.EndsWith('.zip',True);
end;

function InstallZipPackage(const PackageApp: string): Boolean;
begin

  var AppPath:=TFolder.GetAppPath;
  var ExeFileName:=ExtractFileName(AppPath);
  var PackagePath:=ExtractFilePath(PackageApp);
  var PackageExeFile:=TFolder.Combine(PackagePath,ExeFileName);

  Result:=UnzipThis(PackageApp,ExeFileName,PackagePath);

  if Result then
  begin
    TFile.SetAttributes(PackageExeFile,TFile.GetAttributes(AppPath));
    Result:=Exec(string.Join(' ',[PackageExeFile,'update',AppPath,PackageApp]));
  end;

end;

function InstallExePackage(const PackageApp: string): Boolean;
begin
  var ExecutePath:=TFolder.GetAppPath;
  TFile.SetAttributes(PackageApp,TFile.GetAttributes(ExecutePath));
  Result:=Exec(PackageApp+' update '+ExecutePath);
end;


function InstallPackage(const PackageApp: string): Boolean;
begin
  if FileIsZip(PackageApp) then
    Result:=InstallZipPackage(PackageApp)
  else
    Result:=InstallExePackage(PackageApp);
end;

function UpdatePackage(const ExecuteApp,PackageApp: string): Boolean;
begin

  Result:=True;

  var ExeAttributes:=TFile.GetAttributes(ExecuteApp);

  DeleteFile(ExecuteApp);

  if FileIsZip(PackageApp) then
    Unzip(PackageApp,ExtractFilePath(ExecuteApp))
  else
    TFile.Copy(PackageApp,ExecuteApp);

  TFile.SetAttributes(ExecuteApp,ExeAttributes);

  Result:=Exec(ExecuteApp+' updated');

end;

{$ENDIF}

end.
