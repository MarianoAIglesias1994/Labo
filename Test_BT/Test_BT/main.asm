;
; Test_BT.asm
;
; Created: 18/11/2016 09:51:43 p.m.
; Author : MarianoAgustín
;
;Anda en TeraTERM pc http://www.instructables.com/id/Cheap-2-Way-Bluetooth-Connection-Between-Arduino-a/?ALLSTEPS pero no en android
.include "m328Pdef.inc"

.cseg
.org 0x00
rjmp main
main:

		LDI R21, HIGH(RAMEND)	; Configura el STACK
		OUT SPH, R21
		LDI R21, LOW(RAMEND)
		OUT SPL, R21

LDI R20, 0b00110000		; Hay LEDs conectados a los bits seteados en dichos puertos
OUT DDRD, R20
LDI R20, 0b00110000		; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTD, R20	

RCALL RETARDO_BT
RCALL USART_INIT
RCALL RETARDO_BT

		LDI R19, 0b00000000	 ;
		RCALL USART_TRANSMISION
		RCALL RETARDO_BT

		LDI R19, 0b00000000	 ;
		RCALL USART_TRANSMISION
		RCALL RETARDO_BT

		LDI R19,0b00011001 ;
		RCALL USART_TRANSMISION
		RCALL RETARDO_BT

		LDI R19,0b00011000 ;
		RCALL USART_TRANSMISION
		RCALL RETARDO_BT
		
		LDI R19,0b00010001 ;
		RCALL USART_TRANSMISION
		RCALL RETARDO_BT
		
		LDI R19, 0b00010110;
		RCALL USART_TRANSMISION
		RCALL RETARDO_BT


TRANS2:		RJMP TRANS2
		
RETARDO_BT:
		LDI R16, 20
LOOP1:	LDI R17, 255
LOOP2:	LDI R18, 255
LOOP3:  DEC R18
		BRNE LOOP3			
		DEC R17
		BRNE LOOP2
		DEC R16
		BRNE LOOP1
		RET



USART_INIT:
;configuro el baud rate en 9600
LDI R16, 0x67
LDI R17, 0x00
STS UBRR0H, R17
STS UBRR0L, R16

;habilito el tx  solamente ya que el modulo se encarga de enviar la fecha del evento, no de recibir cualquier tipo de informacion

LDI R16, (1<<TXEN0)
STS UCSR0B, R16

LDI R16, (1<<USBS0)|(3<<UCSZ00); 8 bits por dato, 2bits de stop
STS UCSR0C, R16
RET


USART_TRANSMISION:
LDS	R17,UCSR0A		;se fija que el buffer este listo para la transmision
SBRS	R17,UDRE0
RJMP	USART_TRANSMISION
STS	UDR0,R19		;manda la informacion que hay en el registro 19 al buffer para ser enviada
RET
