;-----------------------------------------------------------------------------
;   initialization
;-----------------------------------------------------------------------------

        ; for IntTo32bit: *429496729.6,   for IntTo16bit: 6553.6
            SET    1.000,1,0       ;Get rate at 1 ms & scaling O command
			;rate msPerStep, DACscale(1 = +-5V), DACoffset
            ;offset for Drum because of the DAC0 output bias of about 700uV
            VAR    V22,DrumOff=VDAC32(0.0000) ;HP .0003 - 0 1/10/14

            ;offset for Chair because of the DAC0 output bias
            VAR    V23,Chairoff=VDAC32(0.0000) ;HP .0004 1/13/14  Now set in Spike2


            VAR    V24,DrumAmp=VDAC16(0.05) ;V24: Amplitude of Drum Velocity command
            VAR    V25,DrumPh=VAngle(0) ;V25: Phase of Drum Velocity command
            VAR    V26,DrumFreq=VHz(1) ;V26: Frequency of Drum Velocity command

            VAR    V27,ChrAmp=VDAC16(0.1) ;V27: Amplitude of Chair Velocity command
            VAR    V28,ChrPh=VAngle(0) ;V28: Phase of Chair Velocity command
            VAR    V29,ChrFreq=VHz(1) ;V29: Fequency of Chair Velocity command

            VAR    V31,ChAmpOff=vdac16(0)
            VAR    V32,DrAmpOff=vdac16(0)

            VAR    V33,PulseWai=1  ;variables for stimulation pulses (opto)
            VAR    V34,PulseNum=1
            VAR    V35,PulseDur=1
            VAR    V36,PulseInt=1
            VAR    V37,PulseSta=1

            VAR    V38,StepRes2=100 ;variables for steps (drum & chair)
            VAR    V39,StepStar=100 ; Not currently used 12/16
            VAR    V40,StepLeng=500
            VAR    V41,SteLeng1=500
            VAR    V42,StepRes1=500
            VAR    V43,SAmpC=VDAC32(.01)        ; Step amp chair
            VAR    V44,SAmpD=VDAC32(.001)       ; Step amp drum
            VAR    V45,SAmpCn=VDAC32(-.01)      ; Step amp chair inverse
            VAR    V46,SAmpDn=VDAC32(-.001)     ; Step amp drum inverse

            VAR    V47,stepLen1=0  ;variables for step DELAYED light pulses
            VAR    V48,stepLen2=500
            VAR    V49,stepLen3=0

            VAR    V50,PulseDuV=33      ; pulse Duration V
            VAR    V51,PulseWaV=966  ; pulse wait V
            VAR    V52,PulsePer=1000 ; pulse period duration
            VAR    V53,PulseHPe=500  ; Half Period duration

;-----------------------------------------------------------------------------
; LOOP: our idle loop.
;-----------------------------------------------------------------------------
;LOOP:       JUMP   LOOP

LOOP:       SZ     7,1        ;set cosine amplitude
            OFFSET 7,0        ;cosine offset command to ghost timing sine wave
            ANGLE  7,0        ;cosine phase
            RATE   7,1        ;set rate and start ghost cosine
            ;CLRC   7
LOOP1:     DAC 0,DrumOff           ; >Looping.
            DAC 1,Chairoff
            JUMP   LOOP1      ;WAITC  7,LOOP1

;-----------------------------------------------------------------------------
; INIT: Move CHAIR (DAC1) & DRUM (DAC0) to zero
;-----------------------------------------------------------------------------
INIT:   'I  RATE   0,0             ;stop cosine on drum
            RATE   1,0             ;stop cosine on chair
            DAC    0,DrumOff       ;stop the drum
            DAC    1,Chairoff      ;stop the chair
            DIGOUT [00000000]      ;stop any pulses
            JUMP   KCHAIR          ;return chair to zero

;-----------------------------------------------------------------------------
; QUIT: Stops all movement on drum and chair
;-----------------------------------------------------------------------------
QUIT:   'O  RATE   0,0             ;stop cosine on drum
            RATE   1,0             ;stop cosine on chair
            DAC    0,DrumOff       ;stop the drum
            DAC    1,Chairoff      ;stop the chair
            DIGOUT [00000000]      ;stop any pulses
            JUMP   LOOP            ;idle loop

;-----------------------------------------------------------------------------
; KCHAIR: Chair return function
; Returns the chair to a 0 position when called.  Also stops the chair sine-output.
;-----------------------------------------------------------------------------
KCHAIR:     RATE   1,0             ;stop cosine on chair

KCHAIR1:    CHAN   V8,4            ;Get value of channel 3 (chair pos)***3to4 HP 1/10/14
            MOVI   V9,0            ;Intialize v9 to 0 (0=false) >Returning chair.

            BGT    V8,0,KCHAIR2    ;get absolute value by negating if under 0
            NEG    V8,V8           ;it was < 0 so we negate it.
            MOVI   V9,1            ;and then remember that it was negative

KCHAIR2:    BLE    V8,vdac16(0.01),KCHAIREX ;check if we're within our epsilon
            BNE    V9,0,KCHAIR3    ;check if it was negative.
            DAC    1,-0.02          ;vel for positive pos
            JUMP   KCHAIR1

KCHAIR3:    DAC    1,0.02         ;vel for negative pos
            JUMP   KCHAIR1

KCHAIREX:   DAC    1,Chairoff      ;Stop the chair
            JUMP   KDRUM           ;Now initialize the drum

;-----------------------------------------------------------------------------
;KDRUM: Drum return function
;Initialize drum (DAC0) to 0 position
;-----------------------------------------------------------------------------
KDRUM:      RATE   0,0             ;stop sine on drum

KDRUM1:     CHAN   V8,3            ;Get position of drum from Ch 3 * 14 to 3 HP 1/10/14
            MOVI   V9,0            ;Initiliaze v9 to 0 (false)
            BGT    V8,0,KDRUM2     ;get absolute value of position by negating if under 0
            NEG    V8,V8           ;it was < 0 so we negate it.
            MOVI   V9,1            ;and then remember that it was negative

KDRUM2:     BLE    V8,vdac16(0.01),KDRUMEX
                                    ;check if we're within our epsilon
                                    ;if so, exit
            BNE    V9,0,KDRUM3     ;check if position was negative
            DAC    0,0.02         ;vel for positive pos
            JUMP   KDRUM1

KDRUM3:     DAC    0,-0.02          ;vel for negative position
            JUMP   KDRUM1


KDRUMEX:    DAC    0,DrumOff       ;Exit KDRUM
            JUMP   LOOP            ;Drum stopped


;-----------------------------------------------------------------------------
;Set step command to move chair and drum without stimulation
;-----------------------------------------------------------------------------
STEP:   'T  DAC    0,SAmpD         ;HP 1/28/14 ***
            DAC    1,SAmpC
            DELAY  StepLeng
            DAC    0,DrumOff
            DAC    1,Chairoff
            DELAY  StepRes1
            DAC    0,SAmpDn
            DAC    1,SAmpCn
            DELAY  StepLeng
            DAC    0,DrumOff
            DAC    1,Chairoff
            DELAY  StepRes2
            JUMP   STEP

;Set step command to move chair and drum with light pulses - complete cycle
;-----------------------------------------------------------------------------
STEPL:  't  DAC    0,SAmpD              ;Turn on drum
            DAC    1,SAmpC              ;Turn on chair
            DIGOUT [.......1]           ;Light on
            DELAY  StepLeng
            DAC    0,DrumOff
            DAC    1,Chairoff
            DIGOUT [.......0]           ;Light off
            DELAY  StepRes1
            DAC    0,SAmpDn
            DAC    1,SAmpCn
            DIGOUT [.......1]           ;Light on
            DELAY  StepLeng
            DAC    0,DrumOff
            DAC    1,Chairoff
            DIGOUT [.......0]           ;Light off
            DELAY  StepRes2
            JUMP   STEPL

;Set step command to move chair and drum with light pulses - "delayed"
;-----------------------------------------------------------------------------
STEPD:  'd  DAC    0,SAmpD              ;Turn on drum
            DAC    1,SAmpC              ;Turn on chair
            DELAY  StepLen1
            DIGOUT [.......1]           ;Light on
            DELAY  StepLen2
            DIGOUT [.......0]           ;Light off
            DELAY  StepLen3
            DAC    0,DrumOff
            DAC    1,Chairoff
            DELAY  StepRes1
            DAC    0,SAmpDn
            DAC    1,SAmpCn
            DELAY  StepLen1
            DIGOUT [.......1]           ;Light on
            DELAY  StepLen2
            DIGOUT [.......0]           ;Light off
            DELAY  StepLen3
            DAC    0,DrumOff
            DAC    1,Chairoff
            DELAY  StepRes2
            JUMP   STEPD

 ;Set step command to move chair and drum with light pulses - "light aligned to beginning"
;-----------------------------------------------------------------------------
STEPB:  'b  DAC    0,SAmpD              ;Turn on drum
            DAC    1,SAmpC              ;Turn on chair
            DIGOUT [.......1]           ;Light on
            DELAY  StepLen2
            DIGOUT [.......0]           ;Light off
            DELAY  StepLen3
            DAC    0,DrumOff
            DAC    1,Chairoff
            DELAY  StepRes1
            DAC    0,SAmpDn
            DAC    1,SAmpCn
            DIGOUT [.......1]           ;Light on
            DELAY  StepLen2
            DIGOUT [.......0]           ;Light off
            DELAY  StepLen3
            DAC    0,DrumOff
            DAC    1,Chairoff
            DELAY  StepRes2
            JUMP   STEPB


 ;Set step command to move chair and drum with light pulses - "light aligned to end"
;-----------------------------------------------------------------------------
STEPE:  'e  DAC    0,SAmpD              ;Turn on drum
            DAC    1,SAmpC              ;Turn on chair
            DELAY  StepLen1
            DIGOUT [.......1]           ;Light on
            DELAY  StepLen2
            DIGOUT [.......0]           ;Light off
            DAC    0,DrumOff
            DAC    1,Chairoff
            DELAY  StepRes1
            DAC    0,SAmpDn
            DAC    1,SAmpCn
            DELAY  StepLen1
            DIGOUT [.......1]           ;Light on
            DELAY  StepLen2
            DIGOUT [.......0]           ;Light off
            DAC    0,DrumOff
            DAC    1,Chairoff
            DELAY  StepRes2
            JUMP   STEPE
;Set step command to move chair and drum with opto stimulation -- Maxwell 8/18
;-----------------------------------------------------------------------------
STEPZ:  'u  DAC    0,SAmpD              ;Turn on drum
            DAC    1,SAmpC              ;Turn on chair
            DIGOUT [.....1.1]           ;Light + R Pulse on
            DELAY  StepLeng
            DAC    0,DrumOff
            DAC    1,Chairoff
            DIGOUT [.....0.0]           ;Light + R Pulse off
            DELAY  StepRes1
            DAC    0,SAmpDn
            DAC    1,SAmpCn
            DIGOUT [....1..1]           ;Light + L Pulse on
            DELAY  StepLeng
            DAC    0,DrumOff
            DAC    1,Chairoff
            DIGOUT [....0..0]           ;Light + L Pulse off
            DELAY  StepRes2
            JUMP   STEPZ


;STEPS:  'u  DAC    0,SAmpD
;            DAC    1,SAmpC
;            DIGOUT [.......1]
;            DELAY  PulseDur
;            DIGOUT [.......0]
;            DELAY  SteLeng1
;            DAC    0,DrumOff
;            DAC    1,Chairoff
;            DELAY  StepRes1
;            DAC    0,SAmpDn
;            DAC    1,SAmpCn
;            DIGOUT [.......1]
;            DELAY  PulseDur
;            DIGOUT [.......0]
;            DELAY  SteLeng1
;            DAC    0,DrumOff
;            DAC    1,Chairoff
;            DELAY  StepRes1
;            JUMP   STEPS

;STEPS:  'u  DAC    0,DrumOff
;            DAC    1,Chairoff
;            DELAY  StepStar
;            DAC    0,SAmpD
;            DAC    1,SAmpC
;            MOV    V10,PulseNum
;STEPS2:     DIGOUT [.......1]
;            DELAY  PulseDur
;            DIGOUT [.......0]
;            DELAY  PulseInt
;            DBNZ   V10,STEPS2
;            DELAY  SteLeng1
;            DAC    0,DrumOff
;            DAC    1,Chairoff
;            DELAY  StepRes1
;            DAC    0,SAmpDn
;            DAC    1,SAmpCn
;            MOV    V10,PulseNum
;STEPS3:     DIGOUT [.......0]
;            DELAY  PulseDur
;            DIGOUT [.......0]
;            DELAY  PulseInt
;            DBNZ   V10,STEPS3
;            DELAY  SteLeng1
;            DAC    0,DrumOff
;            DAC    1,Chairoff
;            DELAY  StepRes1
;            JUMP   STEPS

;-----------------------------------------------------------------------------
;SINEON: Set sine command to DRUM Velocity DAC0 & to CHAIR Velocity DAC1
;-----------------------------------------------------------------------------
SINEON: 'S  SZ     0,DrumAmp       ;set cosine amplitude
            OFFSET 0,DrumOff       ;cosine offset
            ANGLE  0,DrumPh        ;cosine phase

            SZ     1,ChrAmp        ;set cosine amplitude
            OFFSET 1,Chairoff      ;cosine offset
            ANGLE  1,ChrPh         ;cosine phase

            RATE   0,DrumFreq      ;set rate and start cosine
            RATE   1,ChrFreq       ;set rate and start cosine

OFFST1:     WAITC  1,OFFST1
            OFFSET 0,DrumOff
            OFFSET 1,Chairoff

            JUMP   OFFST1            ;set loop to continue sine function > Sine running.

SINEOFF: 's RATE   0,0             ;stop cosine on drum
            RATE   1,0             ;stop cosine on chair
            DAC    0,DrumOff       ;stop the drum
            DAC    1,Chairoff      ;stop the chair

            JUMP   KCHAIR          ;return chair to zero
;-----------------------------------------------------------------------------

SETOFF: 'A  OFFSET 0,DrumOff
            OFFSET 1,Chairoff

            JUMP   LOOP

;-----------------------------------------------------------------------------
;LIGHTON: 'L SZ     0,DrumAmp       ;set cosine amplitude
;            OFFSET 0,DrumOff       ;cosine centre
;            ANGLE  0,DrumPh        ;cosine phase
;            RATE   0,DrumFreq      ;set rate and start cosine off
;
;            SZ     1,ChrAmp        ;set cosine amplitude
;            OFFSET 1,Chairoff      ;cosine offset command to chair b/c DAC1 has bias of -0.8 mV
;            ANGLE  1,ChrPh         ;cosine phase
;            RATE   1,ChrFreq       ;set rate and start cosine of
;
;            JUMP   pulse
;
;LIGHTOFF: 'l JUMP  pulse

;-----------------------------------------------------------------------------
; LIGHTON: modified 1/20/14 for Rig D019
LIGHTON: 'L DIGOUT [.......1]
            JUMP   OFFST1    ;LOOP

LIGHTOFF: 'l DIGOUT [.......0]
            JUMP   OFFST1    ;LOOP

;-----------------------------------------------------------------------------
; LASERON: turn on both lasers
LASERON: 'Z DIGOUT [....11..]
            JUMP   OFFST1    ;LOOP

LASEROFF: 'z DIGOUT [....00..]
            JUMP   OFFST1    ;LOOP

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;uses commands for pulse stimulation
SPULSE0: 'P SZ     0,DrumAmp       ;set cosine amplitude
            OFFSET 0,DrumOff       ;cosine centre
            ANGLE  0,DrumPh        ;cosine phase

            SZ     1,ChrAmp        ;set cosine amplitude
            OFFSET 1,Chairoff      ;cosine offset command to chair V
            ANGLE  1,ChrPh         ;cosine phase


            SZ     7,1        ;set cosine amplitude
            OFFSET 7,0        ;cosine offset command to ghost timing sine wave
            ANGLE  7,0        ;cosine phase


            DIGOUT [....00..] ;   Can later change this to 11 to get overlapping pulses

            RATE   0,DrumFreq      ;set rate and start DRUM cosine
            RATE   1,ChrFreq       ;set rate and start CHAIR cosine
            RATE   7,ChrFreq       ; Standard for timing

            CLRC   7


SPULSE1:    MOV    V10,PulseNum

W1:         WAITC  7,W1            ;Wait for next cosine cycle
SPULSE2:    DIGOUT [.....1..]      ; 1
            DELAY  PulseDur        ;DELAY takes up 1 ms itself
            DIGOUT [.....0..]      ; 0
            DELAY  PulseInt
            DBNZ   V10,SPULSE2
            DELAY  PulseWai        ;Number of ms to wait in between phases
            MOV    V10,PulseNum
            OFFSET 0,DrumOff
            OFFSET 1,Chairoff
SPULSE3:    DIGOUT [....1...]
            DELAY  PulseDur
            DIGOUT [....0...]
            DELAY  PulseInt
            DBNZ   V10,SPULSE3
            OFFSET 0,DrumOff
            OFFSET 1,Chairoff
            JUMP   SPULSE1

;uses commands for pulse stimulation - immediate switching between sides
IPULSE0: 'Q SZ     0,DrumAmp       ;set cosine amplitude
            OFFSET 0,DrumOff       ;cosine centre
            ANGLE  0,DrumPh        ;cosine phase

            SZ     1,ChrAmp        ;set cosine amplitude
            OFFSET 1,Chairoff      ;cosine offset command to chair V
            ANGLE  1,ChrPh         ;cosine phase

            SZ     7,1        ;set cosine amplitude - ghost channel for timing only
            OFFSET 7,0        ;cosine offset command to ghost timing sine wave
            ANGLE  7,0        ;cosine phase

            RATE   0,DrumFreq      ;set rate and start DRUM cosine
            RATE   1,ChrFreq       ;set rate and start CHAIR cosine
            RATE   7,ChrFreq       ; Standard for timing

            CLRC   7

IW1:        WAITC  7,IW1           ;Wait for next cosine cycle
            DELAY  PulseSta        ;Pulse Start - number of ms to wait before start
            DIGOUT [....01..]      ;Invert two channels
            DELAY  PulseDur        ;DELAY takes up 1 ms itself
            DIGOUT [....10..]
            OFFSET 0,DrumOff
            OFFSET 1,Chairoff
            JUMP   IW1

;----------------------------------------------------
KSPULSE: 'p DIGOUT [....00..]      ;set digital outputs low
            JUMP   LOOP
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;uses commands for single channel LED single 33 ms pulse stimulation (event output 1 for video)
SPULSE4: 'V SZ     0,DrumAmp       ;set cosine amplitude
            OFFSET 0,DrumOff       ;cosine centre
            ANGLE  0,DrumPh        ;cosine phase
            RATE   0,DrumFreq      ;set rate and start cosine off

            SZ     1,ChrAmp        ;set cosine amplitude
            OFFSET 1,Chairoff      ;cosine offset command to chair b/c DAC1 has bias of -0.8 mV
            ANGLE  1,ChrPh         ;cosine phase
            RATE   1,ChrFreq       ;set rate and start cosine off

SPULSE5:    DIGOUT [......1.]
            DELAY  PulseDuV
            DIGOUT [......0.]
            DELAY  PulseWaV
            OFFSET 0,DrumOff
            OFFSET 1,Chairoff
            JUMP   SPULSE5
;----------------------------------------------------
KPULSE2: 'v DIGOUT [......0.]      ;set digital outputs low
            JUMP   INIT
