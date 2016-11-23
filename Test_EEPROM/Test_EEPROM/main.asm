;
; Test_EEPROM.asm
;
; Created: 23/11/2016 03:29:20 a.m.
; Author : MarianoAgustín
;



; Este codigo esta andando en la placa CdR, hace titilar las ISR por separado OK

/**************************************************************
DIRECTIVAS
***************************************************************/
;#ifndef F_CPU
#define F_CPU 16000000UL 
;#include "m88PAdef.inc" ; Lo incluye el AtmelStudio al setear el uC


/**************************************************************
VECTORES DE INTERRUPCION
***************************************************************/
.cseg
.org 0x00
rjmp main

main:

	LDI R21, HIGH(RAMEND)	; Configura el STACK
	OUT SPH, R21
	LDI R21, LOW(RAMEND)
	OUT SPL, R21
	

; LEDs para las pruebas (Puerto C: Rojos; Puerto D: Verdes)
LDI R20, 0b00000001		; Hay LEDs conectados a los bits seteados en dichos puertos
OUT DDRC, R20			
LDI R20, 0b00000000			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTC, R20	

LDI R20, 0b00110000		; Hay LEDs conectados a los bits seteados en dichos puertos
OUT DDRD, R20
LDI R20, 0b00110000			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTD, R20	

RCALL EEPROM_INIT

LDI R21,0x0C		;en R20 Y R21 estan las direcciones de eeprom
LDI R20,0x5D		;que se usa en la funcion EEPROM_WRITE
LDI R22,0b00010110 ;anio

RCALL EEPROM_WRITE

LDI R22,0

RCALL EEPROM_READ

	CPI R22, 0b00010110
	BREQ OK		; Se encienden LEDs en caso de lectura exitosa
	RJMP CONTINUE		; Si no, se continua
OK:					
	LDI R20, 0b00000001
	OUT PORTC, R20
	END: RJMP END
CONTINUE:	RJMP CONTINUE


/**************************************************************
CONFIGURACION EEPROM
***************************************************************/

EEPROM_INIT:	;este bloque de codigo indica a partir de que lugar de memoria se pueden escribir las fechas de los sucesos
STS EEARL,R20
STS EEARH,R21
RET


EEPROM_WRITE:
;RCALL RETARDO_EEPROM
;supongo que en el registro R22 va a estar la fecha del suceso por inactividad en R22 
SBIC EECR,EEPE
RJMP EEPROM_WRITE	;se fija que no haya una escritura previa

STS EEARH, R21
STS EEARL, R20

STS EEDR, R22  		;escribo en el registro de datos de la eeprom la informacion
SBI EECR,EEMPE		;habilito el master para poder escribir en la eeprom	

SBI EECR,EEPE		;habilito la escritura en la eeprom

RET


EEPROM_READ:
;RCALL RETARDO_EEPROM
SBIC EECR,EEPE
RJMP EEPROM_READ	;se fija que no haya una escritura previa

STS EEARH, R21
STS EEARL, R20
			
SBI EECR,EERE		;habilito la lectura en la eeprm 

LDS R22,EEDR		;leo lo que hay en el registro de datos de la eeprom

RET



RETARDO_EEPROM:
		LDI R16, 20
LOOP1EEPROM:	LDI R17, 255
LOOP2EEPROM:	LDI R18, 255
LOOP3EEPROM:	DEC R18
		BRNE LOOP3EEPROM			
		DEC R17
		BRNE LOOP2EEPROM
		DEC R16
		BRNE LOOP1EEPROM
RET
