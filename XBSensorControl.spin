{
  Project: Mobile Platform - Build 2 (Sensor Control)
  Platform: Parallax Project USB Board
  Revision: 1.0
  Author: SIT
  Date: 1st Nov 2023
  Log:
    Date: Desc
}


CON
  'Clock Settings
  _clkmode = xtal1 + pll16x                                                     'Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000
  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  _Ms_001 = _ConClkFreq / 1_000

  'Ultrasonic Sensor Address and Pins
  ultra1SCL = 6, ultra1SDA = 7                                                  'Front Ultrasonic Sensor Pins
  ultra2SCL = 8, ultra2SDA = 9                                                  'Back Ultrasonic Sensor Pins
  ultraADD = $57

  'ToF Sensor Address and Pins
  tof1SCL = 0, tof1SDA = 1, tof1RST = 14                                       'Front ToF Pins
  tof2SCL = 2, tof2SDA = 3, tof2RST = 15                                       'Back ToF Pins
  tofADD = $29                                                                  'Common ToF I2C Address

  'Sensor Groupings
  Front = 1                                                                     'Macros for ultrasonic sensor and ToF ID.
  Back = 2

  'Stop Detection
  stopConfirmTres = 2                                                           'Treshold for stop confirmation count

VAR
  long  SensorCogStack[64]
  long  SensorCogID
  long  FU, FT, BU, BT
  long  stopConfirmCnt

OBJ

  Ultra         : "UltrasonicSensor.spin"                                       'HC-SR04
  ToFDriver     : "ToFSensor.spin"                                              'VL6180X
  bus           : "i2cDriver.spin"                                              'I2C
  Term          : "FullDuplexSerial.spin"                                       'Pins 31, 30 for Rx, Tx - For Debugging, use Term.Dec(var) to check value of a variable

PUB Main

  'Declaration & Initilisation
  'Term.Start(31, 30, 0, 115200)
  'Pause(2000)

  repeat

PUB ActSC(StopFlagPtr, DirPtr) 'Initialise and activate core for sensor controls

  StopCore                                                                      'Prevent stacking drivers
  SensorCogID := cognew(StartSC(StopFlagPtr, DirPtr), @SensorCogStack)                  'Start new cog with Start method
  return SensorCogID                                                            'Return cogID for tracking

PUB StopCore 'Stop active cog
  if SensorCogID                                                                'Check if any active driver cog
    cogstop(SensorCogID)                                                        'Stop the cog

  return

PUB StartSC(StopFlagPtr, DirPtr)| dir 'Looping Code for sensor updates

  Term.Start(31, 30, 0, 115200)
  Pause(2000)

  InitToF                                                                       'Initialise the Time of Flight Sensors

  stopConfirmCnt := 0                                                           'Initialise stop confirmation count to 0
  repeat 'Sensor Updates
    FU := ReadUltraSonic(Front)
    FT := ReadToF(Front)
    BU := ReadUltraSonic(Back)
    BT := ReadToF(Back)
    Term.DEC(FT)
    Term.Tx(47)

    case BYTE[DirPtr]
      1:
        if ((FU > 1  AND FU < 300) OR FT > 254)                            'Obstacle / Fall detection criteria
          stopConfirmCnt += 1                                                       'Start stop detect confirmation count
          if stopConfirmCnt > stopConfirmTres                                       'Update Stop flag in Main OBJ
              BYTE[DirPtr]:=5

        else
              BYTE[StopFlagPtr] := FALSE
      2:
        if ((BU > 1 AND BU < 300) OR BT > 254)                            'Obstacle / Fall detection criteria
          stopConfirmCnt += 1                                                       'Start stop detect confirmation count
          if stopConfirmCnt > stopConfirmTres                                       'Update Stop flag in Main OBJ
              BYTE[DirPtr]:=5

        else
          BYTE[StopFlagPtr] := FALSE

      3:
        if ((FU > 1 AND FU < 300) OR FT > 254)                            'Obstacle / Fall detection criteria
          stopConfirmCnt += 1                                                       'Start stop detect confirmation count
          if stopConfirmCnt > stopConfirmTres                                       'Update Stop flag in Main OBJ
               BYTE[DirPtr]:=5
        else
              BYTE[StopFlagPtr] := FALSE
        if ((BU > 1 AND BU < 300) OR BT > 254)                            'Obstacle / Fall detection criteria
          stopConfirmCnt += 1                                                       'Start stop detect confirmation count
          if stopConfirmCnt > stopConfirmTres                                       'Update Stop flag in Main OBJ
              BYTE[DirPtr]:=5
        else
             BYTE[StopFlagPtr] := FALSE
      4:
        if ((FU > 1 AND FU < 300) OR FT > 254)                            'Obstacle / Fall detection criteria
          stopConfirmCnt += 1                                                       'Start stop detect confirmation count
          if stopConfirmCnt > stopConfirmTres                                       'Update Stop flag in Main OBJ
              BYTE[DirPtr]:=5
        else
             BYTE[StopFlagPtr] := FALSE
        if ((BU > 1 AND BU < 300) OR BT > 254)                            'Obstacle / Fall detection criteria
          stopConfirmCnt += 1                                                       'Start stop detect confirmation count
          if stopConfirmCnt > stopConfirmTres                                       'Update Stop flag in Main OBJ
             BYTE[DirPtr]:=5
        else
             BYTE[StopFlagPtr] := FALSE

PUB ReadUltraSonic(Sensor_num) 'Reads UltraSonic values

  if Sensor_num == Front                                                        'Select Sensor & switch the I2C bus
    bus.Init(ultra1SCL, ultra1SDA)
  if Sensor_num == Back
    bus.Init(ultra2SCL, ultra2SDA)
  Pause(40)                                                                     'Ultrasonic latency

  return Ultra.readSensor                                                       'Return Sensor reading

PUB ReadToF(Sensor_num) 'Reads ToF values

  if Sensor_num == Front                                                        'Select Sensor & switch the I2C bus and reset pin
    ToFDriver.Init(tof1SCL, tof1SDA, tof1RST)
  if Sensor_num == Back
    ToFDriver.Init(tof2SCL, tof2SDA, toF2RST)
  return TofDriver.GetSingleRange(tofADD)                                       'Return Sensor reading

PUB InitToF 'Initialise ToF Sensors

    ToFDriver.Init(tof1SCL, tof1SDA, tof1RST)                                 'Change the I2C bus and reset pins
    ToFDriver.ChipReset(1)                                                      'Reset the memory array
    Pause(1000)
    ToFDriver.FreshReset(tofADD)                                                'Start-up sequence
    ToFDriver.MandatoryLoad(tofADD)
    ToFDriver.RecommendedLoad(tofADD)
    ToFDriver.FreshReset(tofADD)
    Pause(1000)
    ToFDriver.Init(tof2SCL, tof2SDA, tof2RST)                                 'Change the I2C bus and reset pins
    ToFDriver.ChipReset(1)                                                      'Reset the memory array
    Pause(1000)
    ToFDriver.FreshReset(tofADD)                                                'Start-up sequence
    ToFDriver.MandatoryLoad(tofADD)
    ToFDriver.RecommendedLoad(tofADD)
    ToFDriver.FreshReset(tofADD)
    Pause(1000)
  return

PRI Pause(ms) | t
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _Ms_001)
  return