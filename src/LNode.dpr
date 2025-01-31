program LNode;

uses
  System.StartUpCopy,
  SysUtils,
  Classes,
  IOUtils,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Types,
  Types,
  App.Intf in 'Core\App.Intf.pas',
  App.Core in 'Core\App.Core.pas',
  App.Mutex in 'Core\App.Mutex.pas',
  App.Logs in 'Core\App.Logs.pas',
  server.HTTP in 'Web\server\server.HTTP.pas',
  endpoints.Node in 'Web\endpoints\endpoints.Node.pas',
  Desktop in 'UI\Desktop.pas',
  App.Settings in 'Core\App.Settings.pas',
  Crypto in 'Crypto\Crypto.pas',
  server.Types in 'Web\server\server.Types.pas',
  endpoints.Base in 'Web\endpoints\endpoints.Base.pas',
  endpoints.Account in 'Web\endpoints\endpoints.Account.pas',
  App.Exceptions in 'Core\App.Exceptions.pas',
  endpoints.Coin in 'Web\endpoints\endpoints.Coin.pas',
  Form.Main in 'UI\Forms\Form.Main.pas' {MainForm},
  Styles in 'UI\Forms\Styles.pas' {StylesForm},
  WordsPool in 'Crypto\SeedPhrase\WordsPool.pas',
  Frame.Ticker in 'UI\Forms\Frame.Ticker.pas' {TickerFrame: TFrame},
  Frame.Explorer in 'UI\Forms\Frame.Explorer.pas' {ExplorerTransactionFrame: TFrame},
  Frame.History in 'UI\Forms\Frame.History.pas' {HistoryTransactionFrame: TFrame},
  Form.EnterKey in 'UI\Forms\Form.EnterKey.pas' {EnterPrivateKeyForm},
  App.Constants in 'Core\App.Constants.pas',
  OpenURL in 'UI\OpenURL.pas',
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
  Update.Core in 'Update\Update.Core.pas',
  App.Types in 'Core\App.Types.pas',
  Update.Utils in 'Update\Update.Utils.pas',
  Desktop.Controls in 'UI\Desktop.Controls.pas',
  Frame.Reward in 'UI\Forms\Frame.Reward.pas' {RewardFrame: TFrame},
  Frame.Transaction in 'UI\Forms\Frame.Transaction.pas' {TransactionFrame: TFrame},
  Frame.StakingTransaction in 'UI\Forms\Frame.StakingTransaction.pas' {StakingTransactionFrame: TFrame},
  Frame.Navigation in 'UI\Forms\Frame.Navigation.pas' {NavigationFrame: TFrame};

{$R *.res}

var
  LPidFileName: string;
begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown:=True;
  {$ENDIF}

  LPidFileName := 'LNode';
  try
//    with TMutex.Create(LPidFileName) do
    try
      UI := TUICore.Create;
      try
        AppCore := TAppCore.Create;
        AppCore.Run;
        UI.Run;
      except
        on Exception do exit;
      end;
    finally
      AppCore.Stop;
//      Free;
    end;
  except
    on E:EFOpenError do
      ShowMessage('LNode is already started');
  end;
end.
