program lnodeconsole;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Net.Socket,
  System.Net.HttpClient,
  IdHTTPServer,
  App.Constants in 'Core\App.Constants.pas',
  App.Exceptions in 'Core\App.Exceptions.pas',
  App.Logs in 'Core\App.Logs.pas',
  App.Intf in 'Core\App.Intf.pas',
  App.Core in 'Core\App.Core.pas',
  App.Mutex in 'Core\App.Mutex.pas',
  App.Types in 'Core\App.Types.pas',
  App.Settings in 'Core\App.Settings.pas',
  App.Keystore in 'Core\App.Keystore.pas',
  Crypto in 'Crypto\Crypto.pas',
  WordsPool in 'Crypto\SeedPhrase\WordsPool.pas',
  EthereumSigner in 'Crypto\EthereumSigner.pas',
  Server.HTTP in 'Web\server\server.HTTP.pas',
  Server.Types in 'Web\server\server.Types.pas',
  endpoints.Node in 'Web\endpoints\endpoints.Node.pas',
  endpoints.Base in 'Web\endpoints\endpoints.Base.pas',
  endpoints.Account in 'Web\endpoints\endpoints.Account.pas',
  endpoints.Coin in 'Web\endpoints\endpoints.Coin.pas',
  Blockchain.Address in 'Blockchain\Blockchain.Address.pas',
  Blockchain.Data in 'Blockchain\Blockchain.Data.pas',
  Blockchain.Txn in 'Blockchain\Blockchain.Txn.pas',
  Blockchain.Validation in 'Blockchain\Blockchain.Validation.pas',
  BlockChain.DataCache in 'Blockchain\BlockChain.DataCache.pas',
  Blockchain.Reward in 'Blockchain\Blockchain.Reward.pas',
  Blockchain.Utils in 'Blockchain\Blockchain.Utils.pas',
  Net.Client in 'Net\Net.Client.pas',
  Net.ClientConnection in 'Net\Net.ClientConnection.pas',
  Net.CommandHandler in 'Net\Net.CommandHandler.pas',
  Net.Connection in 'Net\Net.Connection.pas',
  Net.Data in 'Net\Net.Data.pas',
  Net.Server in 'Net\Net.Server.pas',
  Net.ServerConnection in 'Net\Net.ServerConnection.pas',
  Net.Core in 'Net\Net.Core.pas',
  Net.ClientHandler in 'Net\Net.ClientHandler.pas',
  Net.CustomHandler in 'Net\Net.CustomHandler.pas',
  Net.Intf in 'Net\Net.Intf.pas',
  Net.ServerHandler in 'Net\Net.ServerHandler.pas',
  Net.Types in 'Net\Net.Types.pas',
  Console in 'UI\Console.pas',
  Update.Core in 'Update\Update.Core.pas',
  Update.Utils in 'Update\Update.Utils.pas';

begin

  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown:=True;
  {$ENDIF}

  if TUpdateCore.RunAsUpdater then Exit;

  AppCore := TAppCore.Create;
  UI := TConsoleCore.Create;

  UI.Run;

end.
