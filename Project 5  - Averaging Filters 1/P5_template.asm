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
		; --- BEGIN variables for TABLAT POINTER
		; DO NOT MODIFY (created by AC) 
;		value
;		counter
		; --- END variables for TABLAT POINTER

		; Create your variables starting from here
		
		;Constants that are not permuatable
		tortoiseSpawnCounter	
		offset				;user DEFINED 
		homePointer
		
		;subroutine variables
		hareValue
		harePointer
		tortoiseValue
		tortoisePointer
		answer

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
		MOVLF 5, offset		;HUMAN DEFINED, value of the offset or the k in x[n-k]
					;change as needed by the problem

		rcall  Initial          ;Initialize everything
mainLoop
			rcall updateHare
			rcall updateTortoise
			rcall updateAnswer
		bra mainLoop
	



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
		copyRegister tortoiseSpawnCounter, offset	;variable tortoiseSpawnCounter
		;The tortoiseSpawnCounter counts down time until we can spawn and use
		;the second counter for the offset term x[n-k] 

		MOVLF 0, harePointer
		MOVLF 0, hareValue
		MOVLF 0, tortoiseValue
		MOVLF 0, tortoisePointer
		MOVLF 0, answer
 return



;;;;;;;;;;updateHare subroutine;;;;;;;;;;;;;;;;;;
updateHare
	addTwoRegisters TBLPTR, homePointer, harePointer;TBLPTR = homePointer + harePointer
	TBLRD*											;read value in address TBLPTR and store value in TABLAT
	copyRegister hareValue, TABLAT					;set hareValue = TABLAT
	incf harePointer, F								;increment harePointer and store value in harePointer

	MOVLF 10, WREG									;This magic number 10 is the length of SimpleTable
	cpfseq harePointer								;checks if harePointer points outside of array
	return											;not equal, harePointer is valid, return
	MOVLF 0, harePointer							;resets harePointer to 0 so it points inside array
	return



;;;;;;;;;updatetortoise subroutine;;;;;;;;;;;;;;;;;;;;;;;;

updateTortoise
	tstfsz tortoiseSpawnCounter			;checks if time to spawn and update tortoise has arrived
	bra updateTortoiseSpawnCount		;not zero, not yet time to spawn tortoise

	;Here tortoiseSpawnCounter is indeed zero, time to spawn tortoise and update value
	addTwoRegisters TBLPTR, homePointer, tortoisePointer ;TBLPTR = homePointer + tortoisePointer
	TBLRD*
	copyRegister tortoiseValue, TABLAT
	incf tortoisePointer, F

	MOVLF 10, WREG	
	cpfseq tortoisePointer
	return
	MOVLF 0, tortoisePointer
	return
	


	updateTortoiseSpawnCount
		decf tortoiseSpawnCounter, F
		return



;;;;;;;;;;;;update Answer;;;;;;;;;;;;;;;;;;;;;;;;;

updateAnswer
	addTwoRegisters answer, tortoiseValue, hareValue
	rrcf answer, F			;divide answer by 2 and update answer register
	return


;;;;;;; TIME SERIES DATA
;
; 	The following bytes are stored in program memory.
;   Created by AC 
;	DO NOT MODIFY
;
SimpleTable 
db 0,50,100,150,200,250,200,150,100,50
; --------------------------------------------------------------

        end


