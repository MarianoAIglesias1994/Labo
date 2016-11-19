;
; Test_BT.asm
;
; Created: 18/11/2016 09:51:43 p.m.
; Author : MarianoAgustín
;

RCALL USART_INIT

LDI R19, 0xAA ;envio 0b10101010 de prueba
TRANS: RCALL USART_TRANSMISION
RJMP TRANS




USART_INIT:

;configuro el baud rate en 9600
LDI R16, 0X33
LDI R17, 0X00
STS UBRR0H, R17
STS UBRR0L, R16

;habilito el tx  solamente ya que el modulo se encarga de enviar la fecha del evento, no de recibir cualquier tipo de informacion

LDI R16, (1<<TXEN0)|(0<<RXEN0)
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