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
      'arch1-41.open.tectum.io:50001,'
    + 'arch2-41.open.tectum.io:50001,'
    + 'arch3-41.open.tectum.io:50001,'
    + 'arch4-41.open.tectum.io:50001,'
    + 'arch5-41.open.tectum.io:50001,'
    + 'arch6-41.open.tectum.io:50001,'
    + 'arch7-41.open.tectum.io:50001,'
    + 'arch8-41.open.tectum.io:50001,'
    + 'arch9-41.open.tectum.io:50001,'
    + 'arch10-41.open.tectum.io:50001,'
    + 'arch11-41.open.tectum.io:50001,'
    + 'arch12-41.open.tectum.io:50001';

  DefaultTCPListenTo = ':50000';
  DefaultPortHTTP = 8917;
  IconURLDomain = 'https://src.open.tectum.io/icons';

  ResponseWithResultCodes = [ptTransaction, ptValidTransaction];

  ResultCode: array[Boolean] of TNetPacketType = (ptError, ptSuccess);

implementation

end.
