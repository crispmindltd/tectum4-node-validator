unit Net.Data;

interface

type
  TNetPacketType = (
    ptResponse = 1,
    ptSuccess = 2,
    ptError = 3,
    ptCheckVersion = 4,
    ptInitConnect = 5,
    ptInfo= 6,
    ptPing = 7,
    ptTransaction = 50,
    ptValidTransaction = 51,
    ptGetRawData = 60,
    ptRawData = 61,
    ptInitConnectError = 200,
    ptKeyAlreadyUsed = 201);

const
  DefaultNodeAddress =
      'arch1.open.tectum.io:50000,'
    + 'arch2.open.tectum.io:50000,'
    + 'arch3.open.tectum.io:50000,'
    + 'arch4.open.tectum.io:50000,'
    + 'arch5.open.tectum.io:50000,'
    + 'arch6.open.tectum.io:50000,'
    + 'arch7.open.tectum.io:50000,'
    + 'arch8.open.tectum.io:50000,'
    + 'arch9.open.tectum.io:50000,'
    + 'arch10.open.tectum.io:50000,'
    + 'arch11.open.tectum.io:50000,'
    + 'arch12.open.tectum.io:50000';

  DefaultTCPListenTo = ':50000';
  DefaultPortHTTP = 8917;
  IconURLDomain = 'https://src.open.tectum.io/icons';

  ResponseWithResultCodes = [ptTransaction, ptValidTransaction];

  ResultCode: array[Boolean] of TNetPacketType = (ptError, ptSuccess);

implementation

end.
