CON
  _clkmode = xtal1 + pll16x                                      'Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000
  _ConClkFreq = ((_clkmode - xtal1) >> 6) * _xinfreq
  _Ms_001 = _ConClkFreq / 1_000

VAR
  long  MCID, SCID, CCID                                         'cogID for tracking
  long  Stop
  BYTE  DIR, RDY, SPD                                                 'Stop flag

OBJ
  'Sensor        : "XBSensorControl.spin"                           'Ultrasonic and ToF Sensors
  Motor         : "MotorControl_MyBot.spin"                        'RoboClaw Controller
  Comm          : "CommControl_MyBot.spin"
  'Term          : "FullDuplexSerial.spin"                        'Pins 31, 30 for Rx, Tx - For Debugging, use Term.Dec(var) to check value of a variable

PUB Main
 'Declaration & Initialisation
  'Term.Start(31, 30, 0, 115200)
  'Pause(2000)
  'SCID := Sensor.ActSC(@Stop,@DIR)                                     'Initialise Sensor Driver
  Pause(2000)
  MCID := Motor.ActMC(@Stop,@DIR,@SPD)
  CCID := Comm.Init(@DIR, @RDY, @SPD, 2000)                                        'Initialise Motor Driver
  Pause(100)

  repeat while Stop == False                                     'Wait until obstacle detected
  Motor.StopCore                                                 'Disengage Motor cog
  Motor.AllMotorStop                                            'Ensure all motor stopped
  repeat

PRI Pause(ms) | t
  t := cnt - 1088
  repeat (ms #> 0)
    waitcnt(t += _Ms_001)
  return