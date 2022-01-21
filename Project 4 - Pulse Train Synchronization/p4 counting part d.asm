;;;;;;; P4;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Use 10 MHz crystal frequency.
; Use Timer0 for ten millisecond looptime.
; Blink "Alive" LED every two and a half seconds.
; Toggle C2 output every ten milliseconds for measuring looptime precisely.
;
;;;;;;; Program hierarchy ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Mainline
;   Initial
;   BlinkAlive
;   LoopTime
;
;;;;;;; Assembler directives ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        list  P=PIC18F4520, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON
        #include <P18F4520.inc>
        __CONFIG  _CONFIG1H, _OSC_HS_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOREN_ON_2L & _BORV_2_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_PORTC_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L & _XINST_OFF_4L  ;RB5 enabled for I/O
        errorlevel -314, -315          ;Ignore lfsr messages

;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        cblock  0x000           ;Beginning of Access RAM
        TMR0LCOPY               ;Copy of sixteen-bit Timer0 used by LoopTime
        TMR0HCOPY
        INTCONCOPY              ;Copy of INTCON for LoopTime subroutine
        ALIVECNT                ;Counter for blinking "Alive" LED
        
		;This is needed for the modulus operation
		dividend
		divisor

		;Keep track of toggles
		numberOfBit0Toggles
		
		;Need this to check for which one to toggle
		answerMod2
		answerMod4
		answerMod8

		;State of RC0-RC3 registers
		state

		endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal			;move literal value to WREG
        movwf  dest				;move WREG to f= dest, which is specified by user
        endm



copyRegister 	macro A, B		;We want to set A = B by moving B -> WREG then WREG -> A
				movf B, W		;Move B -> WREG
				movwf A			;Move WREG -> A
				endm

subTwoRegs		macro A, B, C	;We want to set A = B - C
				movf C, W		;Move C -> WREG
				subwf B, W		;B-C -> WREG
				movwf A			;Move WREG -> A
				endm

;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000             ;Reset vector, READ Section 5.7
        nop
        goto  Mainline			;goes to Mainline; thus skipping the interrupts below

        org  0x0008             ;High priority interrupt vector
        goto  $                 ;Trap

        org  0x0018             ;Low priority interrupt vector
        goto  $                 ;Trap

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
        rcall  Initial          ;Initialize everything

countingLoop

        rcall  	LoopTime					;Wait 0.1ms
		copyRegister PORTC, state			;toggle all required bits through proxy register called state to minimize lag 
		incf numberOfBit0Toggles, F			;increment numberOfBit0Toggles
	
		copyRegister dividend, numberOfBit0Toggles 	;declaring dividend before calling modulus subroutine
		rcall modulus					;computes dividend mod divisor returns answer
		btg state, 0					;Toggle bit0

		;if numberOfBit0Toggles mod 8 = 0 btg all
		tstfsz answerMod8				;Checks if answerMod8 is clear
		bra bit2Toggle					;if false check for bit2
		btg state, 3					;if true toggle up to bit RC3
		btg state, 2
		btg state, 1		
		bra countingLoop
		
		;if numberOfBit0Toggles mod 4 = 0 btg 2 and 1
		bit2Toggle
		tstfsz answerMod4
		bra bit1Toggle
		btg state, 2					;if true toggle up to bit RC2
		btg state, 1
		bra countingLoop

		;if numberOfBit0Toggles	mod 2= 0 btg1 
		bit1Toggle
		tstfsz answerMod2
		bra countingLoop
		btg state, 1					;if true toggle up to bit RC1
		bra countingLoop



;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine performs all initializations of variables and registers.

Initial
        MOVLF  B'10001110',ADCON1  ;Enable PORTA & PORTE digital I/O pins
        MOVLF  B'11100001',TRISA  ;Set I/O for PORTA 0 = output, 1 = input
        MOVLF  B'11011100',TRISB  ;Set I/O for PORTB
        MOVLF  B'11010000',TRISC  ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD  ;Set I/O for PORTD
        MOVLF  B'00000000',TRISE  ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON  ;Set up Timer0 for a looptime of 10 ms;  bit7=1 enables timer; bit3=1 bypass prescaler
        MOVLF  B'00010000',PORTA  ;Turn off all four LEDs driven from PORTA ; See pin diagrams of Page 5 in DataSheet
		MOVLF  B'11111111',TMR0H ;ADDED by AC
        MOVLF  B'00000000',TMR0L ;ADDED by AC
		MOVLF  B'00000100',ALIVECNT ;ADDED by AC

		;Initialize these counters to be 0
		MOVLF 0, numberOfBit0Toggles

	    MOVLF  B'00010000',PORTC


		MOVLF 0, answerMod2
		MOVLF 0, answerMod4
		MOVLF 0, answerMod8

		MOVLF 0, state
        return

;;;;;;; LoopTime subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This subroutine waits for Timer0 to complete its ten millisecond count
; sequence. It does so by waiting for sixteen-bit Timer0 to roll over. To obtain
; a period of precisely 10000/0.4 = 25000 clock periods, it needs to remove
; 65536-25000 or 40536 counts from the sixteen-bit count sequence.  The
; algorithm below first copies Timer0 to RAM, adds "Bignum" to the copy ,and
; then writes the result back to Timer0. It actually needs to add somewhat more
; counts to Timer0 than 40536.  The extra number of 12+2 counts added into
; "Bignum" makes the precise correction.

Bignum  equ     65536-250+12+2

LoopTime
        btfss  INTCON,TMR0IF    ;Wait until 0.1 milliseconds are up OR check if bit TMR0IF of INTCON == 1, skip next line if true
        bra  LoopTime
        movff  INTCON,INTCONCOPY  ;Disable all interrupts to CPU
        bcf  INTCON,GIEH
        movff  TMR0L,TMR0LCOPY  ;Read 16-bit counter at this moment
        movff  TMR0H,TMR0HCOPY
        movlw  low  Bignum
        addwf  TMR0LCOPY,F
        movlw  high  Bignum
        addwfc  TMR0HCOPY,F
        movff  TMR0HCOPY,TMR0H
        movff  TMR0LCOPY,TMR0L  ;Write 16-bit counter at this moment
        movf  INTCONCOPY,W      ;Restore GIEH interrupt enable bit
        andlw  B'10000000'
        iorwf  INTCON,F
        bcf  INTCON,TMR0IF      ;Clear Timer0 flag
        return




;;;;;;;;;;;;;;;Modulus Subroutine;;;;;;;;;;;;;;;;;;;;;;;

modulus

;;First check mod8 for RC3;;;;

	MOVLF 8, divisor			;First check for answerMod8
	rcall modulo
	copyRegister answerMod8, dividend	;at the end you set answerMod8=dividend

;;Now check mod4 for RC2;;;

	MOVLF 4, divisor			;declare divisor 
	rcall modulo				;Find dividend mod 4
	copyRegister answerMod4, dividend	;At the end answerMod4 = dividend

	
;;Now check for mod2 for RC1;;
	MOVLF 2, divisor
	rcall modulo			
	copyRegister answerMod2, dividend

return	


;;;;;;;;;;;;;;;modulo subroutine;;;;;;;;;;;;;;;;
modulo

beginModulo

	copyRegister WREG, divisor 	;We are assuming divisor has been defined before calling
	cpfseq dividend			;Checks if dividend is equal to WREG where dividend == divisor?
	bra modGreaterThanCheck;if false check if dividend > divisor ?
	bra subtractingLoop	;If true then dividend is equal to 8 then subtract 
	
	modGreaterThanCheck
	copyRegister WREG, divisor		;Again assuming divisor has been defined
	cpfsgt dividend			;Checks if dividend is greater than divisor if true then 
	bra endModulo				;If dividend < divisor then skip to endModulo

	subtractingLoop
		subTwoRegs dividend, dividend, divisor	; Here we do dividend= dividend - divisor
	bra beginModulo	
	endModulo

return


end	