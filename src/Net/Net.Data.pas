unit Net.Data;

interface

uses
  Classes,
  SysUtils;

const
  DefaultNodeAddress = //
    'arch1.open.tectum.io:50000,arch2.open.tectum.io:50000,arch3.open.tectum.io:50000,' //
    + 'arch4.open.tectum.io:50000,arch5.open.tectum.io:50000,arch6.open.tectum.io:50000,' //
    + 'arch7.open.tectum.io:50000,arch8.open.tectum.io:50000,arch9.open.tectum.io:50000,' //
    + 'arch10.open.tectum.io:50000,arch11.open.tectum.io:50000,arch12.open.tectum.io:50000';

  DefaultTCPListenTo = '0.0.0.0:50000';
  DefaultPortHTTP = 8917;

  ResponseCode = 1;
  SuccessCode = 2;
  ErrorCode = 3;
  CheckVersionCommandCode = 4;
  InitConnectCode = 5;
  InfoCommandCode = 6;
  PingCommandCode = 7;

  NewTransactionCommandCode = 100;
  ValidateCommandCode = 101;
  ValidationDoneCode = 102;
  NewValidatedTransactionCommandCode = 103;

  GetTxnsCommandCode = 104;
  GetAddressesCommandCode = 105;
  GetValidationsCommandCode = 106;
  GetRewardsCommandCode = 107;

  InitConnectErrorCode = 200;
  KeyAlreadyUsesErrorCode = 201;

  BlockchainCorruptedErrorCode = 255;

  CommandsCodes = [ResponseCode..InitConnectCode,
    CheckVersionCommandCode, NewTransactionCommandCode, ValidateCommandCode,
    ValidationDoneCode, NewValidatedTransactionCommandCode,
    GetTxnsCommandCode..GetRewardsCommandCode,
    InitConnectErrorCode, KeyAlreadyUsesErrorCode];

  NoAnswerNeedCodes = [CheckVersionCommandCode, InitConnectErrorCode,
    KeyAlreadyUsesErrorCode, SuccessCode, BlockchainCorruptedErrorCode];

  ResponseWithResultCodes = [NewTransactionCommandCode, ValidateCommandCode,
    ValidationDoneCode, NewValidatedTransactionCommandCode];

  ResultCode: Array[Boolean] of Byte = (ErrorCode, SuccessCode);

implementation

end.
