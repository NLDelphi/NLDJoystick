unit NLDJoystick;

interface

uses
  MMSystem, Windows, Messages, SysUtils, Classes;

const
  JoyBtn1 = 1;
  JoyBtn2 = 2;
  JoyBtn3 = 3;
  JoyBtn4 = 4;
  JoyBtn5 = 5;
  JoyBtn6 = 6;
  JoyBtn7 = 7;
  JoyBtn8 = 8;
  JoyBtn9 = 9;
  JoyBtn10 = 10;
  JoyBtn11 = 11;
  JoyBtn12 = 12;
  JoyBtn13 = 13;
  JoyBtn14 = 14;
  JoyBtn15 = 15;
  JoyBtn16 = 16;
  JoyBtn17 = 17;
  JoyBtn18 = 18;
  JoyBtn19 = 19;
  JoyBtn20 = 20;
  JoyBtn21 = 21;
  JoyBtn22 = 22;
  JoyBtn23 = 23;
  JoyBtn24 = 24;
  JoyBtn25 = 25;
  JoyBtn26 = 26;
  JoyBtn27 = 27;
  JoyBtn28 = 28;
  JoyBtn29 = 29;
  JoyBtn30 = 30;
  JoyBtn31 = 31;
  JoyBtn32 = 32;

type
  TNLDJoystick = class;

  TJoyID = JOYSTICKID1..JOYSTICKID2;

  TJoyRelPos = record
    X: Double;
    Y: Double;
    Z: Double;
    R: Double;
    U: Double;
    V: Double;
  end;

  TJoyAbsPos = packed record
    X: Word;
    Y: Word;
    Z: Word;
    R: Word;
    U: Word;
    V: Word;
  end;

  TJoyButton = JoyBtn1..JoyBtn32;
  TJoyButtons = set of TJoyButton;

  TJoyAxis = (axX, axY, axZ, axR, axU, axV);
  TJoyAxises = set of TJoyAxis;

  TJoyButtonEvent = procedure(Sender: TNLDJoystick;
    const Buttons: TJoyButtons) of object;
  TJoyMoveEvent = procedure(Sender: TNLDJoystick; const JoyPos: TJoyRelPos;
    const Buttons: TJoyButtons) of object;
  TJoyPOVChangedEvent = procedure(Sender: TNLDJoystick;
    const Degrees: Single) of object;

  TMMJoyMsg = packed record
    Msg: Cardinal;
    Buttons: Cardinal; {wParam}
    XZPos: Word;       {LoWord(lParam)}
    YPos: Word;        {HiWord(lParam)}
    Result: Longint;
  end;

  TJoyRanges = packed record
    XDown: Word;
    XUp: Word;
    YDown: Word;
    YUp: Word;
    ZDown: Word;
    ZUp: Word;
    RDown: Word;
    RUp: Word;
    UDown: Word;
    UUp: Word;
    VDown: Word;
    VUp: Word;
  end;

  ENLDJoystickError = class(EComponentError);

  TNLDJoystick = class(TComponent)
  private
    FActive: Boolean;
    FAdvanced: Boolean;
    FAxisCount: Byte;
    FAxises: TJoyAxises;
    FButtonCount: Byte;
    FCenter: TJoyAbsPos;
    FHasPOV: Boolean;
    FID: TJoyID;
    FInterval: Cardinal;
    FMax: TJoyAbsPos;
    FMin: TJoyAbsPos;
    FOnButtonDown: TJoyButtonEvent;
    FOnButtonUp: TJoyButtonEvent;
    FOnMove: TJoyMoveEvent;
    FOnPOVChanged: TJoyPOVChangedEvent;
    FPrevButtons: UINT;
    FPrevPos: TJoyRelPos;
    FPrevPOV: Cardinal;
    FPrevButtonTick: Cardinal;
    FPrevMoveTick: Cardinal;
    FProcessedButtonOnce: Boolean;
    FProcessedMoveOnce: Boolean;
    FRanges: TJoyRanges;
    FRepeatButtonDelay: Cardinal;
    FRepeatMoveDelay: Cardinal;
    FThreshold: Double;
    FWindowHandle: HWND;
    function GetButtons(const Buttons: Cardinal): TJoyButtons;
    function Initialize(const NeedAdvanced: Boolean = False): Boolean;
    procedure InitTimer;
    procedure ProcessAdvanced;
    procedure ProcessSimple(var Message: TMMJoyMsg);
    procedure SetActive(const Value: Boolean);
    procedure SetAdvanced(const Value: Boolean);
    procedure SetInterval(const Value: Cardinal);
    procedure SetThreshold(const Value: Double);
  protected
    procedure DoButtonDown(const Buttons: TJoyButtons); virtual;
    procedure DoButtonUp(const Buttons: TJoyButtons); virtual;
    procedure DoMove(const JoyPos: TJoyRelPos;
      const Buttons: TJoyButtons); virtual;
    procedure DoPOVChanged(const JoyPOV: Cardinal); virtual;
    procedure WndProc(var Message: TMessage); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property AbsCenter: TJoyAbsPos read FCenter;
    property AbsMax: TJoyAbsPos read FMax;
    property AbsMin: TJoyAbsPos read FMin;
    property Active: Boolean read FActive write SetActive default False;
    property Advanced: Boolean read FAdvanced write SetAdvanced default False;
    property AxisCount: Byte read FAxisCount;
    property Axises: TJoyAxises read FAxises;
    property ButtonCount: Byte read FButtonCount;
    property HasPOV: Boolean read FHasPOV;
    property ID: TJoyID read FID;
    property OnButtonDown: TJoyButtonEvent read FOnButtonDown
      write FOnButtonDown;
    property OnButtonUp: TJoyButtonEvent read FOnButtonUp write FOnButtonUp;
    property OnMove: TJoyMoveEvent read FOnMove write FOnMove;
    property OnPOVChanged: TJoyPOVChangedEvent read FOnPOVChanged
      write FOnPOVChanged;
    property PollingInterval: Cardinal read FInterval write SetInterval
      default 40;
    property RepeatButtonDelay: Cardinal read FRepeatButtonDelay
      write FRepeatButtonDelay default 350;
    property RepeatMoveDelay: Cardinal read FRepeatMoveDelay
      write FRepeatMoveDelay default 350;
    property ThresholdFactor: Double read FThreshold write SetThreshold;
  end;

function Joystick: TNLDJoystick;
function Joystick1: TNLDJoystick;
function Joystick2: TNLDJoystick;

procedure Register;

implementation

uses
  Math;

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDJoystick]);
end;

var
  FJoystick1: TNLDJoystick = nil;
  FJoystick2: TNLDJoystick = nil;

function Joystick: TNLDJoystick;
begin
  Result := Joystick1;
end;

function Joystick1: TNLDJoystick;
begin
  if FJoystick1 = nil then
    FJoystick1 := TNLDJoystick.Create(nil);
  Result := FJoystick1;
end;

function Joystick2: TNLDJoystick;
begin
  if FJoystick2 = nil then
    FJoystick2 := TNLDJoystick.Create(nil);
  Result := FJoystick2;
end;

{ TNLDJoystick }

const
  DefTimerID = 1;

resourcestring
  SErrNoTimersAvail = 'Not enough timers available for joystick support';
  SErrNoJoystickAvail = 'Not enough joysticks available for another ' +
    'TNLDJoystick instance. Maximum joystick count is two.';

constructor TNLDJoystick.Create(AOwner: TComponent);
begin
  if FJoystick1 = nil then
  begin
    FJoystick1 := Self;
    FID := JOYSTICKID1;
  end else if FJoystick2 = nil then
  begin
    FJoystick2 := Self;
    FID := JOYSTICKID2;
  end else
    raise ENLDJoystickError.Create(SErrNoJoystickAvail);
  inherited Create(AOwner);
  FInterval := 40;
  FRepeatButtonDelay := 350;
  FRepeatMoveDelay := 350;
  FWindowHandle := AllocateHWnd(WndProc);
  FActive := Initialize(FAdvanced);
end;

destructor TNLDJoystick.Destroy;
begin
  SetActive(False);
  DeallocateHWnd(FWindowHandle);
  if FJoystick1 = Self then
    FJoystick1 := nil
  else
    FJoystick2 := nil;
  inherited Destroy;
end;

procedure TNLDJoystick.DoButtonDown(const Buttons: TJoyButtons);
begin
  if Assigned(FOnButtonDown) then
    FOnButtonDown(Self, Buttons);
end;

procedure TNLDJoystick.DoButtonUp(const Buttons: TJoyButtons);
begin
  if Assigned(FOnButtonUp) then
    FOnButtonUp(Self, Buttons);
end;

procedure TNLDJoystick.DoMove(const JoyPos: TJoyRelPos;
  const Buttons: TJoyButtons);
begin
  if Assigned(FOnMove) then
    FOnMove(Self, JoyPos, Buttons);
end;

procedure TNLDJoystick.DoPOVChanged(const JoyPOV: Cardinal);
begin
  if Assigned(FOnPOVChanged) then
    FOnPOVChanged(Self, JoyPOV/100);
end;

function TNLDJoystick.GetButtons(const Buttons: Cardinal): TJoyButtons;
const
  MaxButton: array[Boolean] of TJoyButton = (JoyBtn4, High(TJoyButton));
var
  iButton: TJoyButton;
begin
  Result := [];
  for iButton := Low(TJoyButton) to MaxButton[FAdvanced] do
    if (Buttons and (1 shl (iButton - 1))) <> 0 then
      Include(Result, iButton);
end;

function TNLDJoystick.Initialize(const NeedAdvanced: Boolean = False): Boolean;
var
  JoyInfoEx: TJoyInfoEx;
  JoyCaps: TJoyCaps;
begin
  joyReleaseCapture(FID);
  FillChar(JoyInfoEx, SizeOf(JoyInfoEx), 0);
  JoyInfoEx.dwSize := SizeOf(JoyInfoEx);
  JoyInfoEx.dwFlags := JOY_RETURNCENTERED;
  if (joyGetNumDevs <= FID) or
    (joyGetPosEx(FID, @JoyInfoEx) <> JOYERR_NOERROR) then
    Result := False
  else
  begin
    joyGetDevCaps(FID, @JoyCaps, SizeOf(JoyCaps));
    FAxisCount := Min(JoyCaps.wNumAxes, JoyCaps.wMaxAxes);
    FButtonCount := Min(JoyCaps.wNumButtons, JoyCaps.wMaxButtons);
    FAxises := [axX, axY];
    FCenter.X := JoyInfoEx.wXpos;
    FCenter.Y := JoyInfoEx.wYpos;
    FMax.X := JoyCaps.wXmax;
    FMax.Y := JoyCaps.wYmax;
    FMin.X := JoyCaps.wXmin;
    FMin.Y := JoyCaps.wYmin;
    FRanges.XDown := FCenter.X - FMin.X;
    FRanges.XUp := FMax.X - FCenter.X;
    FRanges.YDown := FCenter.Y - FMin.Y;
    FRanges.YUp := FMax.Y - FCenter.Y;
    if JOYCAPS_HASZ and JoyCaps.wCaps = JOYCAPS_HASZ then
    begin
      Include(FAxises, axZ);
      FCenter.Z := JoyInfoEx.wZpos;
      FMax.Z := JoyCaps.wZmax;
      FMin.Z := JoyCaps.wZmin;
      FRanges.ZDown := FCenter.Z - FMin.Z;
      FRanges.ZUp := FMax.Z - FCenter.Z;
    end;
    if (not NeedAdvanced) or ((FButtonCount <= 4) and (FAxisCount <= 3)) then
    begin
      FAdvanced := False;
      FHasPOV := False;
      joySetCapture(FWindowHandle, FID, 0, True);
    end else begin
      FAdvanced := True;
      if JOYCAPS_HASR and JoyCaps.wCaps = JOYCAPS_HASR then
      begin
        Include(FAxises, axR);
        FCenter.R := JoyInfoEx.dwRpos;
        FMax.R := JoyCaps.wRmax;
        FMin.R := JoyCaps.wRmin;
        FRanges.RDown := FCenter.R - FMin.R;
        FRanges.RUp := FMax.R - FCenter.R;
      end;
      if JOYCAPS_HASU and JoyCaps.wCaps = JOYCAPS_HASU then
      begin
        Include(FAxises, axU);
        FCenter.U := JoyInfoEx.dwUpos;
        FMax.U := JoyCaps.wUmax;
        FMin.U := JoyCaps.wUmin;
        FRanges.UDown := FCenter.U - FMin.U;
        FRanges.UUp := FMax.U - FCenter.U;
      end;
      if JOYCAPS_HASV and JoyCaps.wCaps = JOYCAPS_HASV then
      begin
        Include(FAxises, axV);
        FCenter.V := JoyInfoEx.dwVpos;
        FMax.V := JoyCaps.wVmax;
        FMin.V := JoyCaps.wVmin;
        FRanges.VDown := FCenter.V - FMin.V;
        FRanges.VUp := FMax.V - FCenter.V;
      end;
      FHasPOV := JOYCAPS_HASPOV and JoyCaps.wCaps = JOYCAPS_HASPOV;
      InitTimer;
    end;
    Result := True;
  end;
end;

procedure TNLDJoystick.InitTimer;
begin
  KillTimer(FWindowHandle, DefTimerID);
  if SetTimer(FWindowHandle, DefTimerID, FInterval, nil) = 0 then
    raise ENLDJoystickError.Create(SErrNoTimersAvail);
end;

procedure TNLDJoystick.ProcessAdvanced;
const
  JOY_RETURN = JOY_RETURNX or JOY_RETURNY or JOY_RETURNZ or
    JOY_RETURNR or JOY_RETURNU or JOY_RETURNV or JOY_RETURNPOVCTS or
    JOY_RETURNBUTTONS;
  CenterJoyPos: TJoyRelPos = (X:0.0; Y:0.0; Z:0.0; R:0.0; U:0.0; V:0.0);
var
  JoyInfoEx: TJoyInfoEx;
  JoyPos: TJoyRelPos;
  JoyButtons: TJoyButtons;
  CurrentTick: Cardinal;
  MustDelayButton: Boolean;
  MustDelayMove: Boolean;
begin
  FillChar(JoyInfoEx, SizeOf(TJoyInfoEx), 0);
  JoyInfoEx.dwSize := SizeOf(TJoyInfoEx);
  JoyInfoEx.dwFlags := JOY_RETURN;
  if joyGetPosEx(FID, @JoyInfoEx) = JOYERR_NOERROR then
    with JoyInfoEx do
    begin
      JoyButtons := GetButtons(wButtons);
      FillChar(JoyPos, SizeOf(TJoyRelPos), 0);
      if LoWord(wXpos) < FCenter.X then
        JoyPos.X := (LoWord(wXpos) - FCenter.X) / FRanges.XDown
      else
        JoyPos.X := (LoWord(wXpos) - FCenter.X) / FRanges.XUp;
      if LoWord(wYpos) < FCenter.Y then
        JoyPos.Y := (LoWord(wYpos) - FCenter.Y) / FRanges.YDown
      else
        JoyPos.Y := (LoWord(wYpos) - FCenter.Y) / FRanges.YUp;
      if axZ in FAxises then
        if LoWord(wZpos) < FCenter.Z then
          JoyPos.Z := (LoWord(wZpos) - FCenter.Z) / FRanges.ZDown
        else
          JoyPos.Z := (LoWord(wZpos) - FCenter.Z) / FRanges.ZUp;
      if axR in FAxises then
        if LoWord(dwRpos) < FCenter.R then
          JoyPos.R := (LoWord(dwRpos) - FCenter.R) / FRanges.RDown
        else
          JoyPos.R := (LoWord(dwRpos) - FCenter.R) / FRanges.RUp;
      if axU in FAxises then
        if LoWord(dwUpos) < FCenter.U then
          JoyPos.U := (LoWord(dwUpos) - FCenter.U) / FRanges.UDown
        else
          JoyPos.U := (LoWord(dwUpos) - FCenter.U) / FRanges.UUp;
      if axV in FAxises then
        if LoWord(dwVpos) < FCenter.V then
          JoyPos.V := (LoWord(dwVpos) - FCenter.V) / FRanges.VDown
        else
          JoyPos.V := (LoWord(dwVpos) - FCenter.V) / FRanges.VUp;
      CurrentTick := GetTickCount;
      MustDelayButton := CurrentTick < FPrevButtonTick + FRepeatButtonDelay;
      MustDelayMove := CurrentTick < FPrevMoveTick + FRepeatMoveDelay;
      if wButtons > 0 then
      begin
        if (not MustDelayButton) or (not FProcessedButtonOnce) then
        begin
          if FPrevButtons < wButtons then
            DoButtonDown(JoyButtons)
          else
            DoButtonUp(JoyButtons);
          FProcessedButtonOnce := True;
        end;
      end else begin
        FPrevButtonTick := CurrentTick;
        FProcessedButtonOnce := False;
      end;
      if not CompareMem(@JoyPos, @CenterJoyPos, SizeOf(TJoyRelPos)) then
      begin
        if (not MustDelayMove) or (not FProcessedMoveOnce) then
        begin
          DoMove(JoyPos, JoyButtons);
          FProcessedMoveOnce := True;
        end;
      end else begin
        FPrevMoveTick := CurrentTick;
        FProcessedMoveOnce := False;
      end;
      if FHasPOV and (dwPOV <> FPrevPOV) then
      begin
        FPrevPOV := dwPOV;
        DoPOVChanged(dwPOV);
      end;
    end;
end;

procedure TNLDJoystick.ProcessSimple(var Message: TMMJoyMsg);
var
  JoyPos: TJoyRelPos;
begin
  with Message do
    case Msg of
      MM_JOY1BUTTONDOWN, MM_JOY2BUTTONDOWN:
        begin
          DoButtonDown(GetButtons(Buttons));
        end;
      MM_JOY1BUTTONUP, MM_JOY2BUTTONUP:
        begin
          DoButtonUp(GetButtons(Buttons));
        end;
      MM_JOY1MOVE, MM_JOY2MOVE:
        begin
          JoyPos := FPrevPos;
          if XZPos < FCenter.X then
            JoyPos.X := (XZPos - FCenter.X) / FRanges.XDown
          else
            JoyPos.X := (XZPos - FCenter.X) / FRanges.XUp;
          if YPos < FCenter.Y then
            JoyPos.Y := (YPos - FCenter.Y) / FRanges.YDown
          else
            JoyPos.Y := (YPos - FCenter.Y) / FRanges.YUp;
          FPrevPos := JoyPos;
          DoMove(JoyPos, GetButtons(Buttons));
        end;
      MM_JOY1ZMOVE, MM_JOY2ZMOVE:
        begin
          JoyPos := FPrevPos;
          if XZPos < FCenter.Z then
            JoyPos.Z := (XZPos - FCenter.Z) / FRanges.ZDown
          else
            JoyPos.Z := (XZPos - FCenter.Z) / FRanges.ZUp;
          FPrevPos := JoyPos;
          DoMove(JoyPos, GetButtons(Buttons));
        end;
      else
        Dispatch(Message);
    end;
end;

procedure TNLDJoystick.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    if Value then
      FActive := Initialize(FAdvanced)
    else
    begin
      joyReleaseCapture(FID);
      KillTimer(FWindowHandle, DefTimerID);
      FActive := False;
    end;
  end;
end;

procedure TNLDJoystick.SetAdvanced(const Value: Boolean);
begin
  if FAdvanced <> Value then
  begin
    if not Value then
      FAdvanced := Value
    else
      if FActive then
        Initialize(Value)
      else
        FAdvanced := Value;
  end;
end;

procedure TNLDJoystick.SetInterval(const Value: Cardinal);
var
  JoyCaps: TJoyCaps;
begin
  if Value <> FInterval then
  begin
    if (Value <> 0) and FAdvanced then
    begin
      joyGetDevCaps(FID, @JoyCaps, SizeOf(JoyCaps));
      FInterval := Max(JoyCaps.wPeriodMin, Min(Value, JoyCaps.wPeriodMax));
      InitTimer;
    end else
      FInterval := 0;
  end;
end;

procedure TNLDJoystick.SetThreshold(const Value: Double);
var
  JoyThreshold: UINT;
begin
  if FThreshold <> Value then
  begin
    FThreshold := Max(0.0, Min(Value, 1.0));
    joySetThreshold(FID, Round(FThreshold * FRanges.XUp));
    if joyGetThreshold(FID, @JoyThreshold) = JOYERR_NOERROR then
      FThreshold := JoyThreshold / FRanges.XUp;
  end;
end;

procedure TNLDJoystick.WndProc(var Message: TMessage);
begin
  if not FAdvanced then
    ProcessSimple(TMMJoyMsg(Message))
  else if Message.Msg = WM_TIMER then
    ProcessAdvanced
  else
    Dispatch(Message);
end;

initialization

finalization
  if FJoystick1 <> nil then
    FJoystick1.Free;
  if FJoystick2 <> nil then
    FJoystick2.Free;

end.
