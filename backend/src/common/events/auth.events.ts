export class OtpRequestedEvent {
  constructor(
    public readonly contact: string,
    public readonly code: string,
    public readonly method: 'EMAIL' | 'SMS',
    public readonly purpose: 'VERIFICATION' | 'PASSWORD_RESET' = 'VERIFICATION',
  ) {}
}
