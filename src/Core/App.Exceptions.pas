unit App.Exceptions;

interface

uses
  SysUtils;

type
  EVersionDidNotMatchError = class(Exception);
  EReceiveTimeout = class(Exception);
  EUnknownError = class(Exception);
  ENotFoundError = class(Exception);
  ENotSupportedError = class(Exception);
  EValidError = class(Exception);
  EAccAlreadyExistsError = class(Exception);
  EAuthError = class(Exception);
  EKeyExpiredError = class(Exception);
  EAddressNotExistsError = class(Exception);
  EInsufficientFundsError = class(Exception);
  ETokenAlreadyExists = class(Exception);
  ESameAddressesError = class(Exception);
  ESmartNotExistsError = class(Exception);
  ENoInfoForThisSmartError = class(Exception);
  EValidatorDidNotAnswerError = class(Exception);
  ENoInfoForThisAccountError = class(Exception);
  EFileNotExistsError = class(Exception);
  EDownloadingNotFinished = class(Exception);
  EInvalidSignError = class(Exception);
  ERequestInProgressError = class(Exception);
  ETickerIsProhibitedError = class(Exception);

const
  NewVersionAvailableText = 'New node version available!';
  AddressNotExistsErrorText = 'Address does not exists';
  InsufficientFundsErrorText = 'Insufficient funds';
  UnableSendToTyourselfErrorText = 'Unable to send to yourself';
  InvalidSignErrorText = 'Validator did not confirm the signature';
  ValidatorFailedErrorText = 'Validator returned an error with code 41501';
  ValidatorDidNotRespondErrorText = 'Validator did not respond. Try later';

implementation

end.
