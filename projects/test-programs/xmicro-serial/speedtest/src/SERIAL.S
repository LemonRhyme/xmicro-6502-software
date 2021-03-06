;-----------------------------------------------------------------------------
; SERIAL.S
; SERIAL TEST DRIVER
; 2018-08-05
;-----------------------------------------------------------------------------

.INCLUDE "INSTRUCTIONS.MAC"
.INCLUDE "XM7SEG.MAC"

.EXPORTZP SERIAL_TXBUFFER, SERIAL_RXBUFFER
.EXPORT SERIAL_INIT, SERIAL_TX

;CONSTANTS

	SERIAL_BASE	= $7200
	SERIAL_RHR	= SERIAL_BASE+0		;RECEIVE HOLDING REGISTER
	SERIAL_THR	= SERIAL_BASE+0		;TRANSMIT HOLDING REGISTER
	SERIAL_IER	= SERIAL_BASE+1		;INTERRUPT ENABLE REGISTER
	SERIAL_FCR	= SERIAL_BASE+2		;FIFO CONTROL REGISTER
	SERIAL_ISR	= SERIAL_BASE+2		;INTERRUPT STATUS REGISTER
	SERIAL_LCR	= SERIAL_BASE+3		;LINE CONTROL REGISTER
	SERIAL_MCR	= SERIAL_BASE+4		;MODEM CONTROL REGISTER
	SERIAL_LSR	= SERIAL_BASE+5		;LINE STATUS REGISTER
	SERIAL_MSR	= SERIAL_BASE+6		;MODEM STATUS REGISTER
	SERIAL_SPR	= SERIAL_BASE+7		;SCRATCHPAD REGISTER
	SERIAL_DLL	= SERIAL_BASE+0		;DIVISOR LATCH LSB
	SERIAL_DLM	= SERIAL_BASE+1		;DIVISOR LATCH MSB


.SEGMENT "ZEROPAGE"
	SERIAL_TXBUFFER:	.RES 2
	SERIAL_RXBUFFER:	.RES 2

.SEGMENT "CODE"
;-----------------------------------------------------------------------------
; SERIAL_INIT
; INITIALIZE THE SERIAL PORT - LOAD INTERRUPT VECTOR TO IRQ3
;-----------------------------------------------------------------------------
.PROC SERIAL_INIT
	MVA #$4C, $0208				;LOAD INTERRUPT VECTOR WITH "JMP SERIAL_ISR"
	MWA #SERIAL_INTERRUPT, $0209
	LDA #$00				;CLEAR BUFFERS
	STA SERIAL_TXBUFFER
	STA SERIAL_TXBUFFER+1
	STA SERIAL_RXBUFFER
	STA SERIAL_RXBUFFER+1

	LDA #%00000000				;SET IER - RECEIVE HOLDING ONLY
	STA SERIAL_IER

;	LDA #%00000111				;SET FCR - ENABLE AND CLEAR FIFOS, DISABLE DMA, RX INTERRUPT AT 1 BYTE
;	STA SERIAL_FCR

	LDA #%10001011				;SET LCR - DIVISOR LATCH ENABLED
	STA SERIAL_LCR
	LDA #$01				;SET BAUD RATE - 115200
	STA SERIAL_DLL
	LDA #$00
	STA SERIAL_DLM

	LDA #%00001011				;SET LCR - 8-BIT ODD PARITY
	STA SERIAL_LCR

;	LDA #%00010000				;SET MCR - LOOPBACK MODE
;	STA SERIAL_MCR

	RTS
.ENDPROC

;-----------------------------------------------------------------------------
; SERIAL_ISR
; INTERRUPT SERVICE ROUTINE FOR THE SERIAL PORT (RECEIVE ONLY)
;-----------------------------------------------------------------------------
.PROC SERIAL_INTERRUPT
	LDA SERIAL_ISR
	MVA SERIAL_RHR, SERIAL_RXBUFFER
	XM7SEG_WORD SERIAL_RXBUFFER
	RTI
.ENDPROC


.PROC SERIAL_TX
	LDA SERIAL_LSR
	AND #%00100000
	BEQ SERIAL_TX

	LDA SERIAL_TXBUFFER
	STA SERIAL_THR
	RTS
.ENDPROC
