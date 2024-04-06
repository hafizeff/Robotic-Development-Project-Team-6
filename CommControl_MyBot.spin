CON
        _clkmode = xtal1 + pll16x                                      'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000
        _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
        Local = _ConClkFreq / 1_000

        'Define pins and BAUD rate
        comRx = 24        'Rx/dout is 20
        comTx = 25        'Tx/din is 21
        Baud = 9600

        'Define Commands
        {comStart = $7A
        comForward = $01
        comReverse = $02
        comTurnRight = $03
        comTurnLeft = $04
        comMoveRight = $05
        comMoveLeft = $06
        comDigonal_UR = $07
        comDigonal_UL = $08
        comDigonal_DR = $09
        comDigonal_DL = $0A
        comArkRight_Forward = $0B
        comArkRight_Reverse = $0C
        comArkLeft_Forward = $0D
        comArkLeft_Reverse = $0E
        comPivot_Right_Front = $0F
        comPivot_Left_Front = $10
        comPivot_Right_Rear = $11
        comPivot_Left_Rear = $12
        comRam_Forward = $13
        comCarry_Ball = $14
        comPutDown_Pate = $15
        comKick_Ball = $16
        comParty = $17
        comStopAll = $AA}

        comStart = $7A
        comStopAll = $35
        comForward = $38
        comReverse = $32
        comTurnRight = $2B
        comTurnLeft = $0D
        comMoveRight = $36
        comMoveLeft = $34
        comDigonal_UR = $39
        comDigonal_UL = $37
        comDigonal_DR = $33
        comDigonal_DL = $31

        comArkRight_Forward = $0B
        comArkRight_Reverse = $0C
        comArkLeft_Forward = $0D
        comArkLeft_Reverse = $0E
        comPivot_Right_Front = $0F
        comPivot_Left_Front = $10
        comPivot_Right_Rear = $11
        comPivot_Left_Rear = $12

        comRam_Forward = $13

        comPutDown_Plate = $2F
        comCarry_Ball = $2A
        comKick_Ball = $2D

        comTest = $17

        ' speed changer
        comSpeedbase = $6C
        comSpeed10   = $71
        comSpeed20   = $77
        comSpeed30   = $65
        comSpeed40   = $72
        comSpeed50   = $74
        comSpeed60   = $79
        comSpeed70   = $75
        comSpeed80   = $69
        comSpeed90   = $6F
        comSpeedMax   = $70


VAR
  long CommCogID, CommCogStack[64]
  long _Ms_001

OBJ
  Comm  : "FullDuplexSerial.spin"                                            'UART Communication for control
  'Motor : "MotorControl.spin"
  Term  : "FullDuplexSerial.spin"                                            'UART Communication for control
  Def   : "RxBoardDef.spin"

PUB Main
  _Ms_001 := Local
  StopCore
  Term.Start(31, 30, 0, 115200)
  Term.Dec(67)
  CommCogID := cognew(Terminal, @CommCogStack)


PUB Init(DirPtr , RDYPtr, SpdPtr, MsVal)                                              'Initialise Core for Communications
  _Ms_001 := MSVal
  StopCore                                                                          'Prevent stacking drivers
  CommCogID := cognew(Start(DirPtr, RDYPtr,SpdPtr), @CommCogStack)                        'Initialise new cog with Start method
  'CommCogID := cognew(Terminal, @CommCogStack)                        'Initialise new cog with Start method
  return CommCogID

PUB Start(DirPtr, RDYPtr,SpdPtr) | hexValue                                             'Looping code for Op-Code update

  Comm.Start(comRx, comTx, 0, Baud)                   'Start new cog for UART Communication with ZigBee
                                                      'Receive data from PC
  BYTE[RDYPtr] := 0
  'Poll for commands
  repeat                                                                                      'Protocol starts with start BYTE
    hexValue:=Comm.rx
    if BYTE[RDYPtr] == 0
      if hexValue == comStart
        BYTE[RDYPtr] := 1
    if BYTE[RDYPtr] == 1                                                                  'Retrieve direction BYTE
        case hexValue                                                             'Update direction using Op-Code
          comStopALL:
            BYTE[DirPtr] := 0
          comForward:
            BYTE[DirPtr] := 1
          comReverse:
            BYTE[DirPtr] := 2
          comTurnRight:
            BYTE[DirPtr] := 3
          comTurnLeft:
            BYTE[DirPtr] := 4
          comMoveRight:
            BYTE[DirPtr] := 5
          comMoveLeft:
            BYTE[DirPtr] := 6
          comDigonal_UR:
            BYTE[DirPtr] := 7
          comDigonal_UL:
            BYTE[DirPtr] := 8
          comDigonal_DR:
            BYTE[DirPtr] := 9
          comDigonal_DL:
            Byte[DirPtr] := 10
          comArkRight_Forward:
            BYTE[DirPtr] := 11
          comArkRight_Reverse:
            BYTE[DirPtr] := 12
          comArkLeft_Forward:
            BYTE[DirPtr] := 13
          comArkLeft_Reverse:
            BYTE[DirPtr] := 14
          comPivot_Right_Front:
            BYTE[DirPtr] := 15
          comPivot_Left_Front:
            BYTE[DirPtr] := 16
          comPivot_Right_Rear:
            BYTE[DirPtr] := 17
          comPivot_Left_Rear:
            BYTE[DirPtr] := 18

          comRam_Forward:
           BYTE[DirPtr] := 19


          comPutDown_Plate:
            BYTE[DirPtr] := 20
          comCarry_Ball:
            BYTE[DirPtr] := 21
          comKick_Ball:
            BYTE[DirPtr] := 22

          comTest:
            BYTE[DirPtr] := 23

          comSpeedbase:
            BYTE[SpdPtr]   := 0
          comSpeed10:
            BYTE[SpdPtr] := 1
          comSpeed20:
            BYTE[SpdPtr] := 2
          comSpeed30:
            BYTE[SpdPtr] := 3
          comSpeed40:
            BYTE[SpdPtr] := 4
          comSpeed50:
            BYTE[SpdPtr] := 5
          comSpeed60:
            BYTE[SpdPtr] := 6
          comSpeed70:
            BYTE[SpdPtr] := 7
          comSpeed80:
            BYTE[SpdPtr] := 8
          comSpeed90:
           BYTE[SpdPtr]  := 9
          comSpeedMax:
           BYTE[SpdPtr]  := 10


PUB Terminal | data

  Comm.Start(Def#STM_Rx, Def#STM_Tx, 0, 115200)
  Pause(500)
  repeat
    Term.Tx(47)

    data := Comm.Rx
    Term.Hex(data, 4)
    Comm.Tx($99)
    Pause(2000)

PUB StopCore                                                                    'Stop active cog
  if CommCogID                                                                  'Check for active cog
    cogStop(CommCogID~)                                                         'Stop the cog and zero out ID
  return CommCogID

PRI Pause(ms) | t
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _Ms_001)
  return
