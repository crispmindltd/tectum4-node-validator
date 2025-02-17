program lnodeconsole;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  App.Mutex in 'Core\App.Mutex.pas',
  App.Intf in 'Core\App.Intf.pas',
  App.Types in 'Core\App.Types.pas',
  App.Core in 'Core\App.Core.pas',
  Console in 'UI\Console.pas',
  App.Logs in 'Core\App.Logs.pas',
  App.Exceptions in 'Core\App.Exceptions.pas',
  App.Settings in 'Core\App.Settings.pas',
  Net.Data in 'Net\Net.Data.pas',
  Crypto in 'Crypto\Crypto.pas',
  Net.Client in 'Net\Net.Client.pas',
  Net.Server in 'Net\Net.Server.pas',
  server.HTTP in 'Web\server\server.HTTP.pas',
  server.Types in 'Web\server\server.Types.pas',
  endpoints.Coin in 'Web\endpoints\endpoints.Coin.pas',
  endpoints.Base in 'Web\endpoints\endpoints.Base.pas',
  WordsPool in 'Crypto\SeedPhrase\WordsPool.pas',
  App.Constants in 'Core\App.Constants.pas',
  endpoints.Node in 'Web\endpoints\endpoints.Node.pas',
  Update.Core in 'Update\Update.Core.pas',
  Blockchain.Address in 'Blockchain\Blockchain.Address.pas',
  Blockchain.Data in 'Blockchain\Blockchain.Data.pas',
  Blockchain.Txn in 'Blockchain\Blockchain.Txn.pas',
  Blockchain.Validation in 'Blockchain\Blockchain.Validation.pas',
  Blockchain.Reward in 'Blockchain\Blockchain.Reward.pas',
  BlockChain.DataCache in 'Blockchain\BlockChain.DataCache.pas',
  BlockChain.Utils in 'Blockchain\BlockChain.Utils.pas',
  Net.CommandHandler in 'Net\Net.CommandHandler.pas',
  Net.ServerConnection in 'Net\Net.ServerConnection.pas',
  Net.Connection in 'Net\Net.Connection.pas',
  Net.ClientConnection in 'Net\Net.ClientConnection.pas',
  Update.Utils in 'Update\Update.Utils.pas',
  EthereumSigner in 'Crypto\EthereumSigner.pas';

begin

  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown:=True;
  {$ENDIF}

  if TUpdateCore.RunAsUpdater then Exit;

  try

    AppCore := TAppCore.Create;
    UI := TConsoleCore.Create;

    UI.Run;

  except on E:Exception do
    UI.DoMessage(E.Message);
  end;

  AppCore.Stop;

end.
