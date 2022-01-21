;;;;;;; P5 for QwikFlash board ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Use this template for Experiment 5
; This file was created by AC on 3/31/2020
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
	
		;Counters
		offsetOne				
		offsetTwo
		offsetThree
		spawnCounter

		;Pointer Related
		period
		homePointer
		relativePointer
		firstPointer
		secondPointer
		thirdPointer
		fourthPointer
		
		;Related to values
		firstTerm
		secondTerm
		thirdTerm
		fourthTerm
		answerOne
		answerTwo
		answer
		
		;Related to exam
		offsetNew
		

        endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
		endm

copyRegister 	macro A, B		;We want to set A = B by moving B -> WREG then WREG -> A
				movf B, W		;Move B -> WREG
				movwf A			;Move WREG -> A
				endm	

addTwoRegisters	macro A, B, C	;We want to set A = B + C
				movf C, W		;Move C -> WREG
				addwf B, W		;B+C -> WREG
				movwf A			;Move WREG -> A
endm


;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        org  0x0000             ;Reset vector
        nop
        goto  Mainline

        org  0x0008             ;High priority interrupt vector
        goto  $  ;Trap

        org  0x0018             ;Low priority interrupt vector
        goto  $                  ;Trap

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mainline
		;User defined values for the desired offsets or the values of 
		;j,k, l in x[n-j], x[n-k], x[n-l], x[n-NewExam]
		MOVLF 1, offsetNew
		MOVLF 2, offsetOne		
		MOVLF 5, offsetTwo
		MOVLF 8, offsetThree
		
		;Length of the array
		MOVLF 8, period			;length of the array

		rcall  Initial          ;Initialize everything
mainLoop

		rcall updateTerms
		rcall updateAnswer

		bra mainLoop
	

;;;;;;; TIME SERIES DATA
;
; 	The following bytes are stored in program memory.
;   Created by AC 
;	
;  Choose your Periodic Sequence
;--------------------------------------------------------------
; time series X1
;SimpleTable ; ---> period 2
;db 180,240
;--------------------------------------------------------------
; time series X2
;SimpleTable ; ---> period 4
;db 180,240,200,244
;--------------------------------------------------------------
; time series X3
;SimpleTable ; ---> period 6
;db 180,240,200,244,216,236
;--------------------------------------------------------------
; time series X4
SimpleTable ; ---> period 8
db 180,240,200,244,216,236,160,176
; --------------------------------------------------------------



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
       
		;My initializations
	
		;Think of this as initializing the table values and loading them into memory
		MOVLF upper SimpleTable,TBLPTRU 
		MOVLF high  SimpleTable,TBLPTRH 
		MOVLF low   SimpleTable,TBLPTRL
	
		;This declares constant homePointer which is the address of the first 
		;entry in the SimpleTabl, in this specific example we have 
		;homePointer = 190 but this solution is more robust by not defining it
		;explicitly 

		copyRegister homePointer, TBLPTR	;;homePointer = TBLPTR

		;Here we define the variable tortoiseSpawnCounter based on our offset or the 
		;k in x[n-k] which is defined in the mainline program

		;update subroutine		
		MOVLF 0, relativePointer
		MOVLF 0, spawnCounter
		MOVLF 0, firstPointer
		MOVLF 0, secondPointer
		MOVLF 0, thirdPointer
		MOVLF 0, fourthPointer

		
		;updateAnswer subroutine
		MOVLF 0, answerOne
		MOVLF 0, answerTwo
		MOVLF 0, answer

		MOVLF 0, firstTerm
		MOVLF 0, secondTerm
		MOVLF 0, thirdTerm
		MOVLF 0, fourthTerm
	
		;Exam

		MOVLF 0, offsetNew
 return

;;;;;;;;;;;;;;;;updateTerms subroutine;;;;;;;;;;;;;;;;;;;;;;;;;;
updateTerms

;	copyRegister relativePointer, firstPointer	;relativePointer is local variable
;	rcall updateNoCounter				;update subroutine updates spawnCounter, TABLAT, relativePointer
;	copyRegister firstPointer, relativePointer	;firstPointer is global variable
;	copyRegister firstTerm, TABLAT			;updates first term with TABLAT that was received
;	MOVLF 0, TABLAT							;sanitize TABLAT




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	copyRegister spawnCounter, offsetNew		;spawnCounter is local variable 
	copyRegister relativePointer, firstPointer 	;relativePointer is local variable
	rcall update					;update subroutine updates spawnCounter, TABLAT, relativePointer
	copyRegister offsetNew, spawnCounter		;offsetOne is global variable
	copyRegister firstPointer, relativePointer	;firstPointer is global variable
	copyRegister firstTerm, TABLAT			;updates first term with TABLAT that was received
	MOVLF 0, TABLAT							;sanitize TABLAT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




	copyRegister spawnCounter, offsetOne		;spawnCounter is local variable 
	copyRegister relativePointer, secondPointer 	;relativePointer is local variable
	rcall update					;update subroutine updates spawnCounter, TABLAT, relativePointer
	copyRegister offsetOne, spawnCounter		;offsetOne is global variable
	copyRegister secondPointer, relativePointer	;firstPointer is global variable
	copyRegister secondTerm, TABLAT			;updates first term with TABLAT that was received
	MOVLF 0, TABLAT							;sanitize TABLAT

	copyRegister spawnCounter, offsetTwo		;spawnCounter is local variable 
	copyRegister relativePointer, thirdPointer	;relativePointer is local variable
	rcall update					;update subroutine updates spawnCounter, TABLAT, relativePointer
	copyRegister offsetTwo, spawnCounter		;offsetOne is global variable
	copyRegister thirdPointer, relativePointer	;firstPointer is global variable
	copyRegister thirdTerm, TABLAT			;updates first term with TABLAT that was received
	MOVLF 0, TABLAT							;sanitize TABLAT

	copyRegister spawnCounter, offsetThree		;spawnCounter is local variable 
	copyRegister relativePointer, fourthPointer	;relativePointer is local variable
	rcall update					;update subroutine updates spawnCounter, TABLAT, relativePointer
	copyRegister offsetThree, spawnCounter		;offsetOne is global variable
	copyRegister fourthPointer, relativePointer	;firstPointer is global variable
	copyRegister fourthTerm, TABLAT			;updates first term with TABLAT that was received
	MOVLF 0, TABLAT							;sanitize TABLAT


return



;;;;;;;;;update subroutine;;;;;;;;;;;;;;;;;;;;;;;;

update		;the arguments passed are relativePointer and spawnCounter
	tstfsz spawnCounter			;checks if time to spawn and update the register has arrived
	bra updateSpawnCount			;not zero, not yet time to spawn or update register

	updateNoCounter
	;Here tortoiseSpawnCounter is indeed zero, time to spawn tortoise and update value
	addTwoRegisters TBLPTR, homePointer, relativePointer ;TBLPTR = homePointer + relativePointer
	TBLRD*
	incf relativePointer, F
;	copyRegister tortoiseValue, TABLAT		moving this to mainline

	copyRegister WREG, period		;The period is the length of SimpleTable
	cpfseq relativePointer			;checks if relativePointer == period
	return					;relativePointer != period

	;relativePointer = period
	MOVLF 0, relativePointer		
	return
	
		;updateSpawnCounter catch
		updateSpawnCount
		decf spawnCounter, F
return		;return spawnCounter, relativePointer, TABLAT



;;;;;;;;;;;;update Answer;;;;;;;;;;;;;;;;;;;;;;;;;

updateAnswer


	;Taking care of 1/8 so that it transforms into 1/4

	;firstTerm/2
	rrcf firstTerm,F

	;secondTerm/2

	rrcf secondTerm,F
	;thirdTerm/2

	rrcf thirdTerm,F
	;fourthTerm/2

	rrcf fourthTerm,F





	;divisor 1/4
	addTwoRegisters answerOne, firstTerm, secondTerm	;answerOne = firstTerm + secondTerm
	rrcf answerOne,F					;answerOne = answerOne /2

	addTwoRegisters answerTwo, thirdTerm, fourthTerm	;answerTwo = thirdTerm + fourthTerm
	rrcf answerTwo, F					;answerTwo = answerTwo /2

	addTwoRegisters answer, answerOne, answerTwo		;answerOne = answerOne + answerTwo
	rrcf answer,F						;answerOne = answerOne /2
	return





        end


