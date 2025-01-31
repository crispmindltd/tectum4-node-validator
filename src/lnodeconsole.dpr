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
  Net.ClientConnection in 'Net\Net.ClientConnection.pas';

var
  LPidFileName: string;
begin

  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown:=True;
  {$ENDIF}

  if TUpdateCore.RunAsUpdater then Exit;

  LPidFileName := 'LNode';
  try
//    with TMutex.Create(LPidFileName) do
    try
      AppCore := TAppCore.Create;
      UI := TConsoleCore.Create;
      try
        UI.Run;
        Logs.DoLog('UI Run exit', DbgLvlLogs, ltNone);
      except
        on E:Exception do
        begin
          UI.DoMessage(E.Message);
          UI.DoMessage('Press Enter to exit');
          Readln;
          exit;
        end;
      end;
    finally
      AppCore.Stop;
//      Free;
    end;
  except
    on E:EFOpenError do
      Writeln('LNode is already started');
  end;
end.
