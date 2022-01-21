;;;;;;; P3 Template by AC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; INTERRUPTS LAB ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        list  P=PIC18F4520, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON
        #include <P18F4520.inc>
        __CONFIG  _CONFIG1H, _OSC_HS_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOREN_ON_2L & _BORV_2_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_PORTC_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L & _XINST_OFF_4L  ;RB5 enabled for I/O
        errorlevel -314, -315          ;Ignore lfsr messages

;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        cblock  0x000                  ;Beginning of Access RAM
        TMR0LCOPY                      ;Copy of sixteen-bit Timer0 used by LoopTime
        TMR0HCOPY
        INTCONCOPY                     ;Copy of INTCON for LoopTime subroutine

		WREG_TEMP
		STATUS_TEMP

		TIMECOUNT

		counter
		numerator
		denominator


        endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
        endm

;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000                    ;Reset vector
        nop
        goto  Mainline

        org  0x0008                    ;High priority interrupt vector
		goto HPISR                     ;execute High Priority Interrupt Service Routine


        org  0x0018                    ;Low priority interrupt vector
        goto LPISR                     ;execute Low Priority Interrupt Service Routine

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial                 ;Initialize everything
        
;L1
 ;        btg  PORTC,RC2               ;Toggle pin, to generate pulse train
  ;       rcall  LoopTime              ;Looptime is set to 0.1ms delay
  ;       bra	L1
L1

	MOVLF 15, numerator
	MOVLF 4, denominator
	rcall modulus
L2
rcall L2



;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Initial
	
        MOVLF  B'10001110',ADCON1      ;Enable PORTA & PORTE digital I/O pins
        MOVLF  B'11100001',TRISA       ;Set I/O for PORTA
        MOVLF  B'11011111',TRISB       ;Set I/O for PORTB
		MOVLF  B'11010000',TRISC       ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD       ;Set I/O for PORTD
        MOVLF  B'00000100',TRISE       ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON       ;Set up Timer0 for a looptime of 10 ms
        MOVLF  B'00010000',PORTA       ;Turn off all four LEDs driven from PORTA
		MOVLF  B'11111111',TMR0H 		;Added by AC - DO NOT MODIFY
        MOVLF  B'00000000',TMR0L 		;Added by AC - DO NOT MODIFY
		bcf PORTC,RC1 					;Added by AC - DO NOT MODIFY

	
	;The following are required to be enabled as per page 91 of manual 	
	bsf RCON, IPEN			; Enables interrupt priority feature, stands for Interrupt Priority ENable 
	bsf INTCON, GIEH		; Enables all high-priority input, stands for Global Interrupt Enable High
	bsf INTCON, GIEL		; Enables all low-priority input, stands for Global Interrupt Enable Low

	;INT0 is defined as HIGH piority interrupt by default. Let us set up the Low
	;priority interrupt service routine to be INT1

	bsf PORTB,INT0			;Allows bit0 or INTerrupt0 to be read (this is going to be HPISR)
	bsf PORTB,INT1			;Allows bit1 or INTerrupt1 to be read (this is going to be LPISR)

	;We do not need to set register TRISB bits INT0 and INT1 
	;as that has been already done by AC

	bsf INTCON,INT0IE		;Enables the use of INT0 stands for INTerrupt 0 Interrupt Enable
	bsf INTCON3, INT1IE		;Enables the use of INT1 stands for INTerrupt 1 Interrupt Enable
	bcf INTCON3, INT1IP		;Since INT1 is not defined as default HPISR or LPISR we define it to be LPISR

	;Now we are going to define the rising edge to be the interrupt trigger
	;setting 	(1) is rising edge
	;clearing	(0) is falling edge

	bsf INTCON2, INTEDG0	;INT0 interrupts on rising edge
	bsf INTCON2, INTEDG1	;INT1 interrupts on falling edge

	;Now we have to make sure the microcontroller knows INT0 and INT1 interrupts have not yet occured
	;So we explicitly say that have not clearing the Interrupt Flag
	
	bcf INTCON, INT0IF		;Clear INT0 interrupt flag (INT0 has not yet occured)
	bcf INTCON3, INT1IF		;Clear INT1 interrupt flag (INT1 has not yet occured)

	;Now we are ready to define our ISR as all the initialization has been done

	;Defining variables needed for LPISR logic 
	MOVLF  2, TIMECOUNT
		
return




;;;;;;; LoopTime subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; DO NOT MODIFY	    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Bignum  equ     65536-250+12+2
LoopTime
		btfss INTCON,TMR0IF            ;Wait for rollover
        bra	LoopTime
		movff  INTCON,INTCONCOPY       ;Disable all interrupts to CPU
        bcf  INTCON,GIEH
        movff  TMR0L,TMR0LCOPY         ;Read 16-bit counter at this moment
        movff  TMR0H,TMR0HCOPY
        movlw  low  Bignum
        addwf  TMR0LCOPY,F
        movlw  high  Bignum
        addwfc  TMR0HCOPY,F
        movff  TMR0HCOPY,TMR0H
        movff  TMR0LCOPY,TMR0L         ;Write 16-bit counter at this moment
        movf  INTCONCOPY,W             ;Restore GIEH interrupt enable bit
        andlw  B'10000000'
        iorwf  INTCON,F
        bcf  INTCON,TMR0IF             ;Clear Timer0 flag
        return


;;;;;;; TIMECOUNT Subroutine;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	MOVLF  2,TIMECOUNT		;Set TIMECOUNT to 2

DELAY
	rcall LoopTime			;Call looptime
	decfsz TIMECOUNT, f		;Decrement TIMECOUNT by 1 and check for 0
	bra DELAY				;Loop
	MOVLF  2,TIMECOUNT		;Reset TIMECOUNT

	return

;;;;;;; Step;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Step
	bsf PORTA,RA1	;Step 1
	bsf PORTA,RA2
	bsf PORTA,RA3
	rcall DELAY

	bcf PORTA,RA1	;Step 2
	bsf PORTA,RA2
	bsf PORTA,RA3
	rcall DELAY

	bsf PORTA,RA1	;Step 3
	bcf PORTA,RA2
	bsf PORTA,RA3
	rcall DELAY

	bcf PORTA,RA1	;Step 4
	bcf PORTA,RA2
	bsf PORTA,RA3
	rcall DELAY

	bsf PORTA,RA1	;Step 5
	bsf PORTA,RA2
	bcf PORTA,RA3
	rcall DELAY

	bcf PORTA,RA1	;Step 6
	bsf PORTA,RA2
	bcf PORTA,RA3
	rcall DELAY

	bsf PORTA,RA1	;Step 7
	bcf PORTA,RA2
	bcf PORTA,RA3
	rcall DELAY

	bcf PORTA,RA1	;;Step 8
	bcf PORTA,RA2
	bcf PORTA,RA3
	rcall DELAY

	return


;;;;;;; LPISR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LPISR
	movff STATUS, STATUS_TEMP          ; save STATUS and W
	movf W,WREG_TEMP

	bcf PORTC, RC2		;Clear the pulse train from the mainline
	;Notice we initalize HPISR flag to be 0 so we don't need to clear it again in this LPISR, 
	;the HPISR can always interrupt this LPISR at any time
	
	rcall Step					;Initate Counting Bits
	MOVLF B'0000000', PORTA	 	; Clear all counting bits from LPISR

	movf WREG_TEMP,W					; restore W
	movff STATUS_TEMP,STATUS			; restore STATUS
	
	bcf INTCON3,INT1IF	;Clearing interrupt flag for LPISR letting it be called again

retfie


;;;;;;; HPISR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HPISR
	bsf PORTC,RC1;Signal that we are entering HPISR - Added by AC - DO NOT MODIFY

	;When the HPISR is initiated all outputs must be cleared 
	bcf PORTC,RC2		;Clearing pulse train in RC2
	
	;Here we clear the outputs of the LPISR if we initiated HPISR within LPISR
	bcf PORTA, RA1
	bcf PORTA, RA2
	bcf PORTA, RA3

AwaitingHumanInput
	btfss PORTE,RE2		;Check if RE2 has been set, if so skip the next line. Notice the only thing 
						;that can break this loop is RE2 being set, no other ISR will break this
	bra AwaitingHumanInput


	bcf PORTC,RC1;Signal that we are Leaving HPISR - Added by AC - DO NOT MODIFY
	MOVLF  B'11111111',TMR0H ;Added by AC - DO NOT MODIFY
	MOVLF  B'00000000',TMR0L ;Added by AC - DO NOT MODIFY


	bcf INTCON,INT0IF	;Clearing interrupt flag for HPISR letting it be called again
	bcf INTCON3, INT1IF	;Clearing interrupt flag for LPISR letting it be called again if it was set 
						;while HPISR was still running causing LPISR to be ignored and lost

retfie FAST

;







;;;;;;;;;;;;;;;Modulus Subroutine;;;;;;;;;;;;;;;;;;;;;;;

modulus
	MOVLF 0, counter

	subtractingLoop

		movf numerator, counter			;moving numerator to counter so we can return counter in the end
		movf denominator, WREG	;moving denominator to WREG so we can subtract 
		subwf numerator, numerator		;Subtract Num = num - WREG <===> num = num - denom

	bnn subtractingLoop				;if num - denom in previous line was not negative then repeat this subtraction

	
return		;Go back to where we came from with counter containing the final answer






end