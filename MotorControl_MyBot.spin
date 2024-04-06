CON
  'Clock Settings
  _clkmode = xtal1 + pll16x                                                     'Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000
  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  _Ms_001   = _ConClkFreq / 1_000

  'Motor Pins
  'M1 = 10, M2 = 11, M3 = 12, M4 = 13
  'M1 = 8, M2 = 9, M3 = 7, M4 = 6

  'servo pins
  Carrier_Pin = 13
  kicker_pin  = 14

  'Motor 0 Speed PWM Duty Cycles
  {M1_zero = 1520                                                               'RoboClaw initial pulse width for zero velocity
  M2_zero = 1520                                                                '1120 = Full Reverse
  M3_zero = 1520                                                                '1520 = Full Stop
  M4_zero = 1520}                                                               '1920 = Full Forward

  'Macros
  SPD = 50                                                                      'Speed setting from 0% to 100%
  DST = 10000                                                                   'Distance in milliseconds
  wtime = 2000
  'for servo
  servoSPD = 1500                                                               '1500 = Full stop, 2500 Anti-Clockwise Fastest speed, 500 Clockwise fastest speed
  par_timer = 500

VAR
  long MotorCogStack[64]
  long MotorCogID
  long speed

OBJ
  MDriver   : "Servo_Moto_Driver(32V9).spin"                                     'Clockwise fastest speed 500, stop 1500, Anti-Clockwise Fastest speed 2500 (using 306 srevo motor requires timing as well)
  SSComm    : "FDS4FC.spin"
  Def       : "RxBoardDef.spin"
  'Term      : "FullDuplexSerial.spin"                                            'Pins 31, 30 for Rx, Tx - For Debugging, use Term.Dec(var) to check value of a variable

PUB Main
  'Serial to PC
  'Term.Start(31,30,0,115200)
  'Pause(1000)
  repeat

PUB ActMC(StopFlagPtr,DirPtr,SpdPtr) 'Activate and initialise core for motor controls
  StopCore                                                                      'Prevent stacking drivers
  MotorCogID := cognew(StartMC(StopFlagPtr,DirPtr,SpdPtr), @MotorCogStack)                      'Start new cog with Start method
  return MotorCogID                                                             'Return cogID for tracking

PUB StopCore 'Stop active cog
  if MotorCogID                                                                 'Check for active cog
    cogstop(MotorCogID)                                                         'Stop the cog
  return

PUB StartMC(StopFlagPtr, DirPtr,SpdPtr) | i 'Track Selection

  Mdriver.start
  SSComm.AddPort(0, Def#R1S2, Def#R1S1, SSComm#PINNOTUSED, SSComm#PINNOTUSED, SSComm#DEFAULTTHRESHOLD, %000000, Def#SSBaud)
  SSComm.AddPort(1, Def#R2S2, Def#R2S1, SSComm#PINNOTUSED, SSComm#PINNOTUSED, SSComm#DEFAULTTHRESHOLD, %000000, Def#SSBaud)
  SSComm.Start                                                              'Calibrate RoboClaw to new zero point value
  Pause(1000)

  repeat
    Control(DirPtr)
    speed_control(SpdPtr)

{PUB Set(motor, speed) 'Set the speed of selected motor

 speed := speed * 4                                                             'Convert speed into value within range

 case motor                                                                     'Select motor & set the speed with respect to zero point
    1:
      MDriver.Set(M1, M1_zero + speed)
    2:
      MDriver.Set(M2, M2_zero + speed)
    3:
      MDriver.Set(M3, M3_zero + speed)
    4:
      MDriver.Set(M4, M4_zero + speed)

 return
}

PUB AllMotorStop | i    'Stops all motors

  repeat i from 0 to 1
    SSComm.Tx(i, 0)
  return

PUB Forward(DutyCycle) | compValue

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  - compValue )   ' Front Left Wheel
  SSComm.Tx(0, 192 - compValue )   ' Front Right Wheel
  SSComm.Tx(1, 64  - compValue )   ' Back Left Wheel
  SSComm.Tx(1, 192 - compValue )   ' Back Right Wheel
  return

PUB Reverse(DutyCycle) | compValue

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  + compValue )
  SSComm.Tx(0, 192 + compValue )
  SSComm.Tx(1, 64  + compValue )
  SSComm.Tx(1, 192 + compValue )
  return

PUB TurnRight(DutyCycle) | compValue 'Set motors to turn left

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  - compValue )
  SSComm.Tx(0, 192 + compValue )
  SSComm.Tx(1, 64  - compValue )
  SSComm.Tx(1, 192 + compValue )
  return

PUB TurnLeft(DutyCycle) | compValue 'Set motors to turn right

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  + compValue )
  SSComm.Tx(0, 192 - compValue )
  SSComm.Tx(1, 64  + compValue )
  SSComm.Tx(1, 192 - compValue )
  return

PUB MoveRight(DutyCycle) | compValue 'Side left

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  - compValue )
  SSComm.Tx(0, 192 + compValue )
  SSComm.Tx(1, 64  + compValue )
  SSComm.Tx(1, 192 - compValue )
  return

PUB MoveLeft(DutyCycle) | compValue 'Side Right

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  + compValue )
  SSComm.Tx(0, 192 - compValue )
  SSComm.Tx(1, 64  - compValue )
  SSComm.Tx(1, 192 + compValue )
  return

PUB Digonal_UR(DutyCycle) | compValue 'Diagonally top right

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  - compValue)
  SSComm.Tx(0, 192 )
  SSComm.Tx(1, 64  )
  SSComm.Tx(1, 192 - compValue)
  return

PUB Digonal_UL(DutyCycle) | compValue 'Diagonally top left

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64 )
  SSComm.Tx(0, 192 - compValue)
  SSComm.Tx(1, 64  - compValue)
  SSComm.Tx(1, 192)
  return

PUB Digonal_DR(DutyCycle) | compValue 'Diagonally bottom right

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64 )
  SSComm.Tx(0, 192 + compValue)
  SSComm.Tx(1, 64  + compValue)
  SSComm.Tx(1, 192)
  return

PUB Digonal_DL(DutyCycle) | compValue 'Diagonally bottom left

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  + compValue )
  SSComm.Tx(0, 192  )
  SSComm.Tx(1, 64 )
  SSComm.Tx(1, 192 + compValue  )
  return

PUB ArkRight_Forward(DutyCycle) | i, compValue' Bend Right Forvard

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  - compValue)         ' Front Left Wheel
  SSComm.Tx(0, 192)                     ' Front Right Wheel
  SSComm.Tx(1, 64  - compValue)         ' Back Left Wheel
  SSComm.Tx(1, 192)                     ' Back Right Wheel
  return

PUB ArkRight_Reverse(DutyCycle) | i, compValue' Bend Right Reverse

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  + compValue)         ' Front Left Wheel
  SSComm.Tx(0, 192)                     ' Front Right Wheel
  SSComm.Tx(1, 64  + compValue)         ' Back Left Wheel
  SSComm.Tx(1, 192)                     ' Back Right Wheel
  return

PUB ArkLeft_Forward(DutyCycle) | i, compValue' Bend Left Forvard

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64 )                     ' Front Left Wheel
  SSComm.Tx(0, 192 - compValue)         ' Front Right Wheel
  SSComm.Tx(1, 64)                      ' Back Left Wheel
  SSComm.Tx(1, 192 - compValue)         ' Back Right Wheel
  return

PUB ArkLeft_Reverse(DutyCycle) | i, compValue' Bend Left Reverse

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64 )                     ' Front Left Wheel
  SSComm.Tx(0, 192 + compValue)         ' Front Right Wheel
  SSComm.Tx(1, 64)                      ' Back Left Wheel
  SSComm.Tx(1, 192 + compValue)         ' Back Right Wheel
  return

PUB Pivot_Right_Front(DutyCycle) | i, compValue' Right Rotation Front

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  - compValue)         ' Front Left Wheel
  SSComm.Tx(0, 192 + compValue)         ' Front Right Wheel
  SSComm.Tx(1, 64)                      ' Back Left Wheel
  SSComm.Tx(1, 192)                     ' Back Right Wheel
  return

PUB Pivot_Left_Front(DutyCycle) | i, compValue' Left Rotation Front

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  + compValue)         ' Front Left Wheel
  SSComm.Tx(0, 192 - compValue)         ' Front Right Wheel
  SSComm.Tx(1, 64)                      ' Back Left Wheel
  SSComm.Tx(1, 192)                     ' Back Right Wheel
  return

PUB Pivot_Right_Rear(DutyCycle) | i, compValue 'Right Rotation  rear

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64 )                     ' Front Left Wheel
  SSComm.Tx(0, 192)                     ' Front Right Wheel
  SSComm.Tx(1, 64  + compValue)         ' Back Left Wheel
  SSComm.Tx(1, 192 - compValue)         ' Back Right Wheel
  return

PUB Pivot_Left_Rear(DutyCycle) | i, compValue 'Left Rotation  rear

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64 )                     ' Front Left Wheel
  SSComm.Tx(0, 192)                     ' Front Right Wheel
  SSComm.Tx(1, 64  - compValue)         ' Back Left Wheel
  SSComm.Tx(1, 192 + compValue)         ' Back Right Wheel
  return

PUB Ram_Forward(DutyCycle) | i, compValue' move foward fast

  DutyCycle := DutyCycle <#= 100
  DutyCycle := DutyCycle #>= 1
  compValue := (DutyCycle * 63)/100

  SSComm.Tx(0, 64  - compValue)         ' Front Left Wheel
  SSComm.Tx(0, 192 - compValue)         ' Front Right Wheel
  SSComm.Tx(1, 64  - compValue)         ' Back Left Wheel
  SSComm.Tx(1, 192 - compValue)         ' Back Right Wheel
  pause(1000)
  AllMotorStop
  return

{ PUB Clockwise(servoSPD, DirPtr)
  BYTE[DirPtr] := 0
  Mdriver.Set(servoPIN, servoSPD)
  Pause(2000)
  Mdriver.Set(servoPIN, servoSPD*5)
}{
  'Motors.Set(ServoM, 500 ) 'Clockwise fastest speed
  'Motors.Set(ServoM, 1400) 'Clockwise slowest speed
  'Motors.Set(ServoM, 1500) 'Stop
  'Motors.Set(ServoM, 1600) 'Anti-Clockwise slowest speed
  'Motors.Set(ServoM, 2500) 'Anti-Clockwise Fastest speed

  for 360 degree motors
  repeat
   Motors.Set(ServoM, 1400)
   Pause(800) 'How long to move before it stops spinning
   Motors.Set(ServoM, 1500)
   Pause(5000)
}{

  Old Motor 180 degree motors, Need find the range between 500 - 2500 for other degrees

  'Motors.Set(ServoM, 500) '180 Degree
  'Motors.Set(ServoM, 2500) '0 Degree
  }

PUB PutDown_Plate(ServoCycle, DirPtr)      ' need to go anti-clockwise
  'BYTE[DirPtr] := 0
  Mdriver.Set(Carrier_Pin, servoSPD + 100) 'putting down
  Pause(50)
  Mdriver.Set(Carrier_Pin, servoSPD)       ' hold plate position

PUB Carrry_Ball(ServoCycle, DirPtr)        ' need to go clockwise  to carry the ball

  BYTE[DirPtr] := 0
  Mdriver.Set(Carrier_Pin, servoSPD - 1000) ' cary ball
  Pause(300)
  Mdriver.Set(Carrier_Pin, servoSPD)       ' stop servo motion

{PUB PutDown_Ball(ServoCycle, DirPtr)      ' need to go anti-clockwise    to put down the ball slowly
  BYTE[DirPtr] := 0
  Mdriver.Set(Carrier_Pin, servoSPD + 50)  'slow drop to touch
  Pause(210)
  Mdriver.Set(Carrier_Pin, servoSPD)       ' hold ball position
  Pause(370)
  Mdriver.Set(Carrier_Pin, servoSPD + 50)  ' full ball release
  pause(100)
  Mdriver.Set(Carrier_Pin, servoSPD)       ' stop servo motion
}

PUB Kick_Ball(ServoCycle, DirPtr)          ' need to go clockwise then anti-clockwise  kicks ball and sets carrying plate to carring position

  BYTE[DirPtr] := 0
  pause(500)

  Mdriver.Set(Carrier_Pin, servoSPD + 80)  'slow drop to touch
  Pause(160)
  Mdriver.Set(Carrier_Pin, servoSPD)       ' hold ball position


  pause(250)

  Mdriver.Set(kicker_pin, servoSPD - 1000) ' kick the ball                     'Max speed for clockwise
  Pause(150)
  Mdriver.Set(kicker_pin, servoSPD)        ' hold the kick position for a bit
  Pause(100)
  Mdriver.Set(kicker_pin, servoSPD + 300)  ' bring back the kicker
  Pause(160)
  Mdriver.Set(kicker_pin, servoSPD)        ' stop servo motion

  'then reset the carrying the plate position
  Pause(150)
  Mdriver.Set(Carrier_Pin, servoSPD - 500) ' cary ball
  Pause(160)
  Mdriver.Set(Carrier_Pin, servoSPD)       ' stop servo motion

PUB Control(DirPtr)
  case BYTE[DirPtr]
    0:
      AllMotorStop
    1:
      Forward(speed)
    2:
      Reverse(speed)


    3:
      TurnRight(speed)
    4:
      TurnLeft(speed)


    5:
      MoveRight(speed)
    6:
      MoveLeft(speed)


    7:
      Digonal_UR(speed)
    8:
      Digonal_UL(speed)
    9:
      Digonal_DR(speed)
    10:
      Digonal_DL(speed)


    11:
      ArkRight_Forward(speed)
    12:
      ArkRight_Reverse(speed)
    13:
      ArkLeft_Forward(speed)
    14:
      ArkLeft_Reverse(speed)


    15:
      Pivot_Right_Front(speed)
    16:
      Pivot_Left_Front(speed)
    17:
     Pivot_Right_Rear(speed)
    18:
      Pivot_Left_Rear(speed)


    19:
      Ram_Forward(SPD*2)


    20:
      PutDown_Plate(servoSPD,DirPtr)
    21:
      Carrry_Ball(servoSPD,DirPtr)
    22:
      Kick_Ball(servoSPD,DirPtr)


    23:
      Test_mode(SPD)

  return

PUB speed_control(SpdPtr)

  case BYTE[SpdPtr]
    0:
      speed := SPD
    1:
      speed := 10
    2:
      speed := 20
    3:
      speed := 30
    4:
      speed := 40
    5:
      speed := 50
    6:
      speed := 60
    7:
      speed := 70
    8:
      speed := 80
    9:
      speed := 90
    10:
      speed := 99

PUB Test_mode(sped)

    Forward(sped)
    pause(par_timer)
    Reverse(sped)
    pause(par_timer)
    TurnRight(sped)
    pause(par_timer)
    TurnLeft(sped)
    pause(par_timer)

    MoveLeft(sped)
    pause(par_timer/2)

    Digonal_UR(sped)
    pause(par_timer)
    Digonal_DL(sped)
    pause(par_timer)

    MoveRight(sped)
    pause(par_timer)
    Digonal_UL(sped)
    pause(par_timer)
    Digonal_DR(sped)
    pause(par_timer)

    MoveLeft(sped)
    pause(par_timer/2)

    ArkRight_Forward(SPD)
    pause(par_timer)
    ArkRight_Reverse(SPD)
    pause(par_timer)
    ArkLeft_Forward(SPD)
    pause(par_timer)

PRI Pause(ms) | t
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _Ms_001)
  return