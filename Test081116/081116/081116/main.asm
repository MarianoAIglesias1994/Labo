;
; 081116.asm
;
; Created: 08/11/2016 07:49:55 p.m.
; Author : MarianoAgustín
;

 /**************************************************************
-MODIFICAR NOMBRES A FUTURO
-CONFIGURAR RTC
-CONFIGURAR BT
-DISEÑAR MANEJO DE TIMESTAMP
-RECONFIGURAR UMBRALES

***************************************************************/

;#define F_CPU 8000000UL  //frecuencia de trabajo del ATMEGA88PA
#define F_CPU 18432000UL  //frecuencia de trabajo del ATMEGA88PA
#include "m88PAdef.inc"


.cseg
.org 0x00
rjmp INICIO

INICIO:

	LDI R21, HIGH(RAMEND)	;Configura el STACK
	OUT SPH, R21
	LDI R21, LOW(RAMEND)
	OUT SPL, R21

; Configuro los leds para las pruebas
LDI R20, 0b00001100	;ROJOS no los uso, todo en pull up
OUT DDRC, R20	;
LDI R20, 0b00001100
OUT PORTC, R20	;


LDI R20, 0b10010000
OUT DDRD, R20	;
LDI R20, 0b10010000
OUT PORTD, R20	;



	
/**************************************************************
INCIALIZO I2C
***************************************************************/

RCALL I2C_INIT


/**************************************************************
CONFIGURACION ACELEROMETRO
***************************************************************/
CONFIG_ACELEROMETRO:
;Información sacada de la data sheet del ADXL345
;Arduino Pin	ADXL345 Pin		Placa CdR 88papu
;GND				GND				8,22
;3V3				VCC				7,20
;3V3				CS				
;GND				SDO				
;A4					SDA				27
;A5					SCL				28
;					INT1			4


;%%%%%%%%%% Se va a realizar la lectura del registro configurado para ver si efectivamente se escribió
	LDI R24, 0xA6; 0b10100110	;Dirección del esclavo SLA(1010011) + Write(0)
	LDI R28, 0xA7; Dirección del esclavo SLA(1010011) + Read(1)
	LDI R25,  0x00	;Dirección del registro a leer
	LDI R26, 0b11100101	;Dato a leer
	RCALL SINGLE_BYTE_READ 

	CP R23, R26
	BREQ OK
	RJMP NOK
OK:
	LDI R20, 0b00000000
	OUT PORTC, R20	; PRENDE ROJOS
	RJMP OK
NOK:
	LDI R20, 0b00000000
	OUT PORTD, R20	; PRENDE VERDES
	RJMP NOK
	;%%%%%%%%%



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/**************************************************************
CONFIGURACION I2C
***************************************************************/
CONFIG_I2C:

I2C_INIT:
	LDI R21, 0b00000011		
	STS TWSR, R21		;Preescaler 1 en TWI Status Reg
	LDI R21, 44		;0x47 xC5
	STS TWBR, R21		;Setea la frecuencia a 50k (8MHz XTAL)
	LDI R21, (1<<TWEN)|(1<<TWINT)	;0x04 a R21 (TWEN: Enable bit)
	STS TWCR, R21		;Habilita el TWI 
	RET

	

;TWINT:TWI Interrupt Flag en 1 el trabajo ha sido finalizado, se pone solo en 1 por hardware
;TWSTA:TWI Start condition bit

I2C_START:
	LDI R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN);
	STS TWCR, R21		;Transimitir condición de START
	
WAIT1:
	LDS R21, TWCR		;Lee el registro
	SBRS R21, TWINT		;Saltea siguiente linea si TWINT es 1(==operación finalizada)
	RJMP WAIT1		;TWINT está en 0
	RET



;Se debe cargar el dato a enviar en el registro TWDR (R27)
;TWDR: TWI Data Register

I2C_WRITE:
	
	LDI R21, (1<<TWINT)|(1<<TWEN) ;Se setean TWINT y TWEN en el TWCR
	STS TWCR, R21		;Configura TWCR para enviar TWDR
	STS TWDR, R27		;Lleva el byte a TWDR

WAIT2:
	LDS R21, TWCR		;Lee el registro de control a R21
	SBRS R21, TWINT		;Saltea siguiente línea si TWINT es 1
	RJMP WAIT2		;Salta a WAIT2 si TWINT es 0
	RET


I2C_READ:
	LDI R21, (1<<TWINT)|(1<<TWEN);|(1<<TWEA)
	STS TWCR, R21

WAIT3:
	LDS R21, TWCR
	SBRS R21, TWINT
	RJMP WAIT2
	LDS R27, TWDR	; Guarda en R27 el dato leido
	RET



;TWSTO:TWI Stop condition bit

I2C_STOP:
	LDI R21, (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
	STS TWCR, R21		;Transmitir condición de STOP
	RET




MULTIPLE_BYTE_WRITE:		
	RCALL I2C_START		;Transmite la condición de START

	MOV R27, R24		;Carga la dirección del esclavo + configuración W
	RCALL I2C_WRITE		;Escribe R27 al bus I2C


	MOV R27, R25		;Dirección del registro a escribir
	RCALL I2C_WRITE		;Escribe R27 al bus I2C
	
	MOV R27, R26		;Dato a transmitir 
	RCALL I2C_WRITE		;Escribe R27 al bus I2C

	RCALL I2C_STOP 		;Transmite la condición de STOP
	RET



SINGLE_BYTE_READ:
	RCALL I2C_START
	
	MOV R27, R24		;Carga la dirección del esclavo + configuración W
	RCALL I2C_WRITE		;Escribe R27 al bus I2C

	MOV R27, R25		;Dirección del registro a escribir
	RCALL I2C_WRITE		;Escribe R27 al bus I2C


	RCALL I2C_START
	
	MOV R27, R28		;Carga la dirección del esclavo + configuración R
	RCALL I2C_WRITE

	RCALL I2C_READ
	

	RCALL I2C_STOP 		
	RET
