;
; Test_211116.asm
;
; Created: 21/11/2016 05:10:37 p.m.
; Author : MarianoAgustín
;
#define F_CPU 16000000UL 
;#include "m88PAdef.inc" 

.cseg
.org 0x00
rjmp INICIO


INICIO:

; LEDs para las pruebas (Puerto C: Rojos; Puerto D: Verdes)
LDI R20, 0b00000001		; Hay LEDs conectados a los bits seteados en dichos puertos
OUT DDRC, R20			
LDI R20, 0b00000000			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTC, R20	

/*
LDI R20, 0b10010000			; Hay LEDs conectados a los bits seteados en dichos puertos
OUT DDRD, R20	
LDI R20, 0b00000000			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTD, R20
*/	

/* TEST PORTD NANO
	LDI R20, 0b11111111		; Hay LEDs conectados a los bits seteados en dichos puertos
	OUT DDRD, R20	
	LDI R20, 0b11111111	
	OUT PORTD, R20

	FIN: RJMP FIN
*/

RCALL I2C_INIT



; Se realiza la lectura del registro DEVID que tiene una direccion: 0x00 y reset value: 11100101
	LDI R24, 0xA6		; Direccion del esclavo SLA(1010011) + Write(0)
	LDI R28, 0xA7		; Direccion del esclavo SLA(1010011) + Read(1)
	LDI R25, 0x25		; Direccion del registro a trabajar
	LDI R26, 0xAA	; Dato;
	
	RCALL MULTIPLE_BYTE_WRITE

	RCALL SINGLE_BYTE_READ 
	
	/*
	ROL R23
	ROL R23
	ROL R23
	ROL R23
	*/
	LDI R20, 0b11111111	; Hay LEDs conectados a los bits seteados en dichos puertos
	OUT DDRD, R20	
	OUT PORTD, R23
	; se leyo 0xA7 en 0x00 con sólo RCALL SINGLE_BYTE_READ 
	
	

	CP R23, R26
	;CPI R23, 0b10100111
	BREQ OK		; Se encienden LEDs en caso de lectura exitosa
	RJMP CONTINUE		; Si no, se continua
OK:					
	LDI R20, 0b00000001
	OUT PORTC, R20
	END: RJMP END
CONTINUE:	
	;RCALL TITILA_VERDE


HERE: RJMP HERE



TITILA_VERDE:

LDI R20, 0b10010000			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTD, R20
		LDI R16, 10
LOOP1:	LDI R17, 255
LOOP2:	LDI R18, 255
LOOP3:  DEC R18
		BRNE LOOP3			
		DEC R17
		BRNE LOOP2
		DEC R16
		BRNE LOOP1
		LDI R20, 0b00000000	
		OUT PORTD, R20
		RET

	
; Biblioteca I2C

/**************************************************************
CONFIGURACION I2C
***************************************************************/


I2C_INIT:
	LDI R21, 0		
	STS TWSR, R21		; Preescaler 1 en TWI Status Reg
	LDI R21, 0xB0		;  0xB0
	STS TWBR, R21		; Setea la frecuencia a 50.087 kHz (18.432 MHz XTAL)
	LDI R21, (1<<TWEN)	; 0x04 a R21 (TWEN: Enable bit)
	STS TWCR, R21		; Habilita el TWI 
	RET


I2C_START:
	LDI R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN);
	STS TWCR, R21		; Transimitir condicion de START
	
WAIT1:
	LDS R21, TWCR		; Lee el registro
	SBRS R21, TWINT		; Saltea siguiente linea si TWINT es 1(==operacion finalizada)
	RJMP WAIT1			; TWINT esta en 0
	RET


I2C_WRITE:
	STS TWDR, R27		; Lleva el byte a TWDR;****
	LDI R21, (1<<TWINT)|(1<<TWEN) ; Se setean TWINT y TWEN en el TWCR
	STS TWCR, R21		; Configura TWCR para enviar TWDR
	
	
WAIT2:
	LDS R21, TWCR		; Lee el registro de control a R21
	SBRS R21, TWINT		; Saltea siguiente li­nea si TWINT es 1
	RJMP WAIT2			; TWINT esta en 0
	RET


I2C_READ:
	LDI R21, (1<<TWINT)|(1<<TWEN)
	STS TWCR, R21

WAIT3:
	LDS R21, TWCR
	SBRS R21, TWINT
	RJMP WAIT3
	LDS R27, TWDR		; Guarda en R27 el dato leido
	RET



I2C_STOP:
	LDI R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
	STS TWCR, R21		; Transmitir condicion de STOP
	RET




; Subrutina de escritura de registros del acelerometro 
MULTIPLE_BYTE_WRITE:		
	RCALL I2C_START		; Transmite la condicion de START
	
	MOV R27, R24		; Carga la direccion del esclavo + configuracion W
	RCALL I2C_WRITE		; Escribe R27 al bus I2C
	
	MOV R27, R25		; Direccion del registro a escribir
	RCALL I2C_WRITE		; Escribe R27 al bus I2C
	
	MOV R27, R26		; Dato a transmitir 
	RCALL I2C_WRITE		; Escribe R27 al bus I2C

	RCALL I2C_STOP 		;Transmite la condicion de STOP
	RET


; Subrutina de lectura de registros del acelerometro 
SINGLE_BYTE_READ:
	RCALL I2C_START		; Transmite la condicion de START

	MOV R27, R24		; Carga la direccion del esclavo + configuracion W
	RCALL I2C_WRITE		; Escribe R27 al bus I2C

	MOV R27, R25		; Direccion del registro a leer
	RCALL I2C_WRITE		; Escribe R27 al bus I2C


	RCALL I2C_START		; Retransmite Start


	MOV R27, R28		; Carga la direccion del esclavo + configuracion R
	RCALL I2C_WRITE

	LDI R27,0

	RCALL I2C_READ
	MOV R23, R27

	RCALL I2C_STOP
	RET
