;
; avr_305_rxtx.asm
;
; Created: 23/11/2016 04:44:26 p.m.
; Author : MarianoAgustín
;

;**** A P P L I C A T I O N   N O T E   A V R 3 0 5 ************************ 
;* 
;* Title		: Half Duplex Interrupt Driven Software UART 
;* Version		: 1.1 
;* Last updated		: 97.08.27 
;* Target		: AT90Sxxxx (All AVR Device) 
;* 
;* Support email	: avr@atmel.com 
;* 
;* Code Size		: 32 Words 
;* Low Register Usage	: 0 
;* High Register Usage	: 4 
;* Interrupt Usage	: None 
;* 
;* DESCRIPTION 
;* This Application note contains a very code efficient software UART. 
;* The example program receives one character and echoes it back. 
;*************************************************************************** 
 
;.include "1200def.inc" 
;.include "m328Pdef.inc"
;***** Pin definitions 
 
.equ	RxD	=0			;Receive pin is PD0 
.equ	TxD	=1			;Transmit pin is PD1 
 .equ		sb	=1		;Number of stop bits (1, 2, ...) 
;***** Global register variables 
 
.def	bitcnt	=R16			;bit counter 
.def	temp	=R17			;temporary storage register 
 
.def	Txbyte	=R18			;Data to be transmitted 
.def	RXbyte	=R19			;Received data 
 
.cseg 
.org 0x00 
rcall reset
 



;***** Program Execution Starts Here 
 
;***** Test program 
 
reset:	
		LDI R21, HIGH(RAMEND)	; Configura el STACK
		OUT SPH, R21
		LDI R21, LOW(RAMEND)
		OUT SPL, R21

		
		sbi	PORTD,TxD	;Init port pins 
		sbi	DDRD,TxD 
 
		ldi	Txbyte,0x4D	;Clear terminal 
		rcall	putchar 
 
forever:	
		;LDI	Txbyte,0x4D 
		;rcall	putchar		;Echo received char 
		;rcall UART_delay
		;rcall UART_delay
		rjmp	forever 
 

;*************************************************************************** 
;* 
;* "putchar" 
;* 
;* This subroutine transmits the byte stored in the "Txbyte" register 
;* The number of stop bits used is set with the sb constant 
;* 
;* Number of words	:14 including return 
;* Number of cycles	:Depens on bit rate 
;* Low registers used	:None 
;* High registers used	:2 (bitcnt,Txbyte) 
;* Pointers used	:None 
;* 
;*************************************************************************** 

 
putchar:
		ldi	Txbyte,0x4D	;Clear terminal 
		ldi	bitcnt,9+sb	;1+8+sb (sb is # of stop bits) 
		com	Txbyte		;Inverte everything 
		sec			;Start bit 
 
putchar0:	brcc	putchar1	;If carry set 
		cbi	PORTD,TxD	;    send a '0' 
		rjmp	putchar2	;else	 
 
putchar1:	sbi	PORTD,TxD	;    send a '1' 
		nop 
 
putchar2:	rcall UART_delay	;One bit delay 
		rcall UART_delay 
 
		lsr	Txbyte		;Get next bit 
		dec	bitcnt		;If not all bit sent 
		brne	putchar0	;   send next 
					;else 
		ret			;   return 
 
 
;*************************************************************************** 
;* 
;* "UART_delay" 
;* 
;* This delay subroutine generates the required delay between the bits when 
;* transmitting and receiving bytes. The total execution time is set by the 
;* constant "b": 
;* 
;*	3·b + 7 cycles (including rcall and ret) 
;* 
;* Number of words	:4 including return 
;* Low registers used	:None 
;* High registers used	:1 (temp) 
;* Pointers used	:None 
;* 
;*************************************************************************** 
; Some b values: 	(See also table in Appnote documentation) 
; 
; 1 MHz crystal: 
;   9600 bps - b=14 
;  19200 bps - b=5 
;  28800 bps - b=2 
; 
; 2 MHz crystal: 
;  19200 bps - b=14 
;  28800 bps - b=8 
;  57600 bps - b=2 
 
; 4 MHz crystal: 
;  19200 bps - b=31 
;  28800 bps - b=19 
;  57600 bps - b=8 
; 115200 bps - b=2 

 .equ	b	=255	;19200 bps @ 4 MHz crystal 
 
 
UART_delay:	ldi	temp,b 
UART_delay1:	dec	temp 
		brne	UART_delay1 
 	LDI R18, 18
LOOP3:  DEC R18
		BRNE LOOP3
		ret 
 
