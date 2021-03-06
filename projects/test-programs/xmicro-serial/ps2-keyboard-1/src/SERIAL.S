;-----------------------------------------------------------------------------
; SERIAL.S
; SERIAL TEST DRIVER
; 2018-08-05
;-----------------------------------------------------------------------------

.INCLUDE "INSTRUCTIONS.MAC"
.INCLUDE "XM7SEG.MAC"

.EXPORTZP SERIAL_TXBUFFER, SERIAL_RXBUFFER
.EXPORT XMSERIAL_INIT, SERIAL_THR, SERIAL_RHR

;CARD INFO
	SLOT		= 7			;BACKPLANE SLOT CARD WILL OCCUPY
	CARD		= $7000 + (SLOT * $100)	;CARD BASE ADDRESS
	IRQ		= $0200 + (SLOT * $4)	;CARD IRQ VECTOR ADDRESS

;OPTIONS
	UART1		= 0
	UART2		= 0
	KEYBOARD	= 1

;REGISTERS
	SERIAL_RHR	= CARD+0		;RECEIVE HOLDING REGISTER
	SERIAL_THR	= CARD+0		;TRANSMIT HOLDING REGISTER
	SERIAL_IER	= CARD+1		;INTERRUPT ENABLE REGISTER
	SERIAL_FCR	= CARD+2		;FIFO CONTROL REGISTER
	SERIAL_ISR	= CARD+2		;INTERRUPT STATUS REGISTER
	SERIAL_LCR	= CARD+3		;LINE CONTROL REGISTER
	SERIAL_MCR	= CARD+4		;MODEM CONTROL REGISTER
	SERIAL_LSR	= CARD+5		;LINE STATUS REGISTER
	SERIAL_MSR	= CARD+6		;MODEM STATUS REGISTER
	SERIAL_SPR	= CARD+7		;SCRATCHPAD REGISTER
	SERIAL_DLL	= CARD+0		;DIVISOR LATCH LSB
	SERIAL_DLM	= CARD+1		;DIVISOR LATCH MSB

	XMSERIAL_PS2	= CARD+$10		;PS/2 DATA REGISTER
	XMSERIAL_CSR	= CARD+$11		;CARD STATUS REGISTER
	XMSERIAL_ID	= CARD+$FF		;CARD ID REGISTER


.SEGMENT "ZEROPAGE"
	SERIAL_TXBUFFER:	.RES 2
	SERIAL_RXBUFFER:	.RES 2

.SEGMENT "BSS"
	PS2_DATABUFFER:		.RES 2
	PS2_COMMANDBUFFER:	.RES 6

.SEGMENT "CODE"
;-----------------------------------------------------------------------------
; SERIAL_INIT
; INITIALIZE THE CARD - LOAD IRQ VECTOR
;-----------------------------------------------------------------------------
.PROC XMSERIAL_INIT
	MVA #$4C, IRQ				;LOAD INTERRUPT VECTOR WITH "JMP XMSERIAL_ISR"
	MWA #XMSERIAL_ISR, IRQ+1

	JSR KB_INIT

	RTS
.ENDPROC


;-----------------------------------------------------------------------------
; KB_INIT
; INITIALIZE THE KEYBOARD
;-----------------------------------------------------------------------------
.PROC KB_INIT
	MVA $FF, XMSERIAL_PS2	;SEND RESET COMMAND

@RESET:	LDA XMSERIAL_CSR
	AND %00001000
	BEQ @RESET				;WAIT UNTIL A WRITE IS IN PROGRESS
	LDA XMSERIAL_PS2			;CLEAR THE PS/2 DATA REGISTER DURING RESET COMMAND


	RTS
.ENDPROC


;-----------------------------------------------------------------------------
; XMSERIAL_ISR
; INTERRUPT SERVICE ROUTINE FOR THE CARD
;-----------------------------------------------------------------------------
.PROC XMSERIAL_ISR
	PHA
	LDA XMSERIAL_CSR
	AND %00100000				;CHECK FOR PS/2 INTERRUPT
	BEQ @PS2_INT

	PLA
	RTI

@PS2_INT:
	JSR PS2_ISR

.ENDPROC


.PROC PS2_ISR
	LDA XMSERIAL_PS2
	STA PS2_DATABUFFER



	RTS
.ENDPROC
