program ctectumnode;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Net.Socket,
  System.Net.HttpClient,
  App.Logs in 'src\Core\App.Logs.pas',
  App.Intf in 'src\Core\App.Intf.pas',
  App.Core in 'src\Core\App.Core.pas',
  App.Types in 'src\Core\App.Types.pas',
  App.Settings in 'src\Core\App.Settings.pas',
  App.DateUtils in 'src\Core\App.DateUtils.pas',
  App.Keystore in 'src\Core\App.Keystore.pas',
  App.Exceptions in 'src\Core\App.Exceptions.pas',
  App.Measure in 'src\Core\App.Measure.pas',
  Crypto in 'src\Crypto\Crypto.pas',
  Crypto.Types in 'src\Crypto\Crypto.Types.pas',
  Crypto.WordsPool in 'src\Crypto\Crypto.WordsPool.pas',
  Crypto.EthereumSigner in 'src\Crypto\Crypto.EthereumSigner.pas',
  Database.Core in 'src\Database\Database.Core.pas',
  Database.Types in 'src\Database\Database.Types.pas',
  Blockchain.Core in 'src\Blockchain\Blockchain.Core.pas',
  Blockchain.Utils in 'src\Blockchain\Blockchain.Utils.pas',
  Blockchain.Data in 'src\Blockchain\Blockchain.Data.pas',
  Blockchain.Cache in 'src\Blockchain\Blockchain.Cache.pas',
  Blockchain.Types in 'src\Blockchain\Blockchain.Types.pas',
  Cache.Dictionary in 'src\Blockchain\Cache.Dictionary.pas',
  Cache.Data in 'src\Blockchain\Cache.Data.pas',
  HTTP.Types in 'src\Web\HTTP.Types.pas',
  HTTP.Server in 'src\Web\HTTP.Server.pas',
  Web.Base in 'src\Web\Web.Base.pas',
  Web.Coin in 'src\Web\Web.Coin.pas',
  Web.Node in 'src\Web\Web.Node.pas',
  Web.Core in 'src\Web\Web.Core.pas',
  Net.ClientHandler in 'src\Net\Net.ClientHandler.pas',
  Net.CustomHandler in 'src\Net\Net.CustomHandler.pas',
  Net.Intf in 'src\Net\Net.Intf.pas',
  Net.ServerHandler in 'src\Net\Net.ServerHandler.pas',
  Net.Core in 'src\Net\Net.Core.pas',
  Net.Event in 'src\Net\Net.Event.pas',
  Net.List in 'src\Net\Net.List.pas',
  Net.Peer in 'src\Net\Net.Peer.pas',
  Net.SocketA in 'src\Net\Net.SocketA.pas',
  Net.Data in 'src\Net\Net.Data.pas',
  Console in 'src\UI\Console.pas',
  Update.Core in 'src\Update\Update.Core.pas',
  Update.Utils in 'src\Update\Update.Utils.pas',
  Miner.Core in 'src\Miner\Miner.Core.pas',
  Miner.Utils in 'src\Miner\Miner.Utils.pas',
  LibCryptoSigner in 'src\Crypto\LibCryptoSigner.pas',
  LibCryptoWrapper in 'src\Crypto\LibCryptoWrapper.pas',
  Web.Token in 'src\Web\Web.Token.pas',
  IconUtils in 'src\UI\IconUtils.pas';

begin

  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}

  UI := TConsoleCore.Create;
  AppCore := TAppCore.Create;
  UI.Run;

end.
