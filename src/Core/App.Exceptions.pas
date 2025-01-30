unit App.Exceptions;

interface

uses
  SysUtils;

type
  EVersionDidNotMatchError = class(Exception);
  ERequestTimeout = class(Exception);
  EUnknownError = class(Exception);
  ENotFoundError = class(Exception);
  ENotSupportedError = class(Exception);
  EValidError = class(Exception);
  EAddressNotExistsError = class(Exception);
  EInsufficientFundsError = class(Exception);
  ESameAddressesError = class(Exception);
  EValidatorDidNotAnswerError = class(Exception);
  EInvalidSignError = class(Exception);
  ERequestInProgressError = class(Exception);
  EConnectionClosed = class(Exception);
  ENoArchiversAvailableError = class(Exception);
  EKeyException = class(Exception)
  public const
    INVALID_KEY = 0;
    KEYFILE_EXISTS = 1;
  private
    FErrorCode: Integer;
  public
    constructor Create(ErrMsg: string; ErrCode: Integer);
    property ErrorCode: Integer read FErrorCode;
  end;

const
  NewVersionAvailableText = 'New node version available!';
  AddressNotExistsErrorText = 'Address does not exists';
  InsufficientFundsErrorText = 'Insufficient funds';
  UnableSendToYourselfErrorText = 'Unable to send to yourself';
  InvalidSignErrorText = 'Validator did not confirm the signature';
  ValidatorFailedErrorText = 'Validator returned an error with code 41501';
  ValidatorDidNotRespondErrorText = 'Validator did not respond. Try later';

implementation

{ EKeyException }

constructor EKeyException.Create(ErrMsg: string; ErrCode: Integer);
begin
  FErrorCode := ErrCode;
  inherited Create(ErrMsg);
end;

end.
