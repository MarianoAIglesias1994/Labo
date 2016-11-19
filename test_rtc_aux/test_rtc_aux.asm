/*
 * test_rtc_aux.asm
 *
 *  Created: 18/11/2016 09:06:38 p.m.
 *   Author: win7
 */ 
 ;
; Test_I2C.asm
;
; Created: 18/11/2016 02:01:48 a.m.
; Author : MarianoAgustín
;

/**************************************************************
DIRECTIVAS
***************************************************************/
#define F_CPU 18432000UL 
#include "m88PAdef.inc" ; Lo incluye el AtmelStudio al setear el uC


.cseg
/**************************************************************
VECTORES DE INTERRUPCION
***************************************************************/
.org 0x00
rjmp INICIO
/*
;.org 0x02				; Por alguna razon traen problemas
rjmp ISR_INT0_INACTIVITY	
;.org 0x04				; Por alguna razon traen problemas
rjmp ISR_INT1_BLUETOOTH	
*/

INICIO:

	LDI R21, HIGH(RAMEND)	; Configura el STACK
	OUT SPH, R21
	LDI R21, LOW(RAMEND)
	OUT SPL, R21

; LEDs para las pruebas (Puerto C: Rojos; Puerto D: Verdes)
LDI R20, 0b00001100			; Hay LEDs conectados a los bits seteados en dichos puertos
OUT DDRC, R20			
LDI R20, 0b00001100			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTC, R20	

LDI R20, 0b10010000			; Hay LEDs conectados a los bits seteados en dichos puertos
OUT DDRD, R20	
LDI R20, 0b10010000			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTD, R20	



/**************************************************************
CONFIGURACION INTERRUPCIONES EXTERNAS
***************************************************************/

/*
CONFIG_INT:

	;EICRA: Configura por flanco o por nivel
	;out R18, EICRA     ; Carga estado previo
	ldi R16,0b00000101	; ldi R16,0b00000001 para INT0; ldi R16,0b00000101 para INT0 e INT1 
	sts EICRA, R16		;

	;EIMSK: Habilita las interrupciones seleccionadas
	;out R18, EIMSK     ; Carga estado previo
	ldi R16,0b00000011 	; ldi R16,0b00000001 para INT0; ldi R16,0b00000011 para INT0 e INT1 
	out EIMSK,R16		;

	;EIFR: Tiene que estar seteado junto con el bit de interrupcion global al momento de suceder la interrupcion 
	;in R18, EIFR       ; Carga estado previo
	ldi R16,0b00000011	; ldi R16,0b00000001 para INT0; ldi R16,0b00000011 para INT0 e INT1 
	out EIFR,R16		;

	SEI
*/


/**************************************************************
CONFIGURACION BAJO CONSUMO
***************************************************************/

/*
CONFIG_BAJO_CONSUMO:
	; Config consumo de energia, PSM o PDM
	ldi R16,0b00000100	; Nibble inferior D3D2D1 = 010 es de power down mode y el lsb D0 = 1 es para activar el sleep mode
	out SMCR,R16
*/
	
/**************************************************************
INCIALIZACION I2C
***************************************************************/

RCALL I2C_INIT
RCALL RTC_CONFIG
LDI R18,0b00010110
RCALL RTC_READ_YEAR
CP	R18,R23
BRNE ERROR_I2C
RCALL OK

ERROR_I2C:		
LDI R20, 0b00010000			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTD, R20	

OK:
LDI R20, 0b00000000	; En caso de error del status se prenden los LEDs Verdes
OUT PORTC, R20		
RET
/**************************************************************
CONFIGURACION ACELEROMETRO
***************************************************************/
/*CONFIG_ACELEROMETRO:

;Conexiones hardware:
;Arduino Pin	ADXL345 Pin		Placa CdR Atmega88pa-pu
;GND				GND				8,22
;3V3				VCC				7,20
;3V3				CS				
;GND				SDO				
;A4					SDA				27
;A5					SCL				28
;					INT1			4

;Informacion de la datasheet del ADXL345



; Se realiza la lectura del registro DEVID que tiene una direccion: 0x00 y reset value: 11100101
	LDI R24, 0xA6		; Direccion del esclavo SLA(1010011) + Write(0)
	LDI R28, 0xA7		; Direccion del esclavo SLA(1010011) + Read(1)
	LDI R25, 0x00		; Direccion del registro a leer DEVID 
	LDI R26, 0b11100101	; Dato contra el que se debe comparar la lectura
	RCALL SINGLE_BYTE_READ 
;	RCALL DELAY			; Estaba presente en algunos codigos del Libro pero no tuvo efecto aqui

	CP R23, R26
	BREQ WRITE_OK		; Se encienden LEDs en caso de lectura exitosa
	RJMP CONTINUE		; Si no, se continua
WRITE_OK:					
	LDI R20, 0b00000000
	OUT PORTC, R20	
CONTINUE:*/				
;


/*

; Se comienza la secuencia de seteo del acelerometro en los valores necesarios

	LDI R25, 0x25		;Direccion del registro a escribir ;THRESH_INACT 0x25 0b0010010
	LDI R26, 0b00010001	;Dato a transmitir ;THRESH_INACT  8 bit unsigned. No dejar en 0x00 umbral de inactividad (62.5 mg/LSB) 
				;en 17 = 0b00010001 despues hacer ajuste fino
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY


	LDI R25, 0x26		;Direccion del registro a escribir ;TIME_INACT 0x26 0b00100110 umbral de tiempo de inactividad
	LDI R26, 0b00000001	;Dato a transmitir ;TIME_INACT  (maximo 255 segundos) (1 sec/LSB)
				;en 1s despues hacer ajuste fino
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY


	LDI R25, 0x27		;Direccion del registro a escribir ;ACT_INACT_CTL 0x27 0b00100111 controla los ejes que intervienen
	LDI R26, 0b00001111	;Dato a transmitir ;ACT_INACT_CTL 
				;en 0b00001111 (D3 en 1=ac coupled)(D2D1D0 = 111 enable en los tres ejes)
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY

	
	LDI R25, 0x2C		;Direccion del registro a escribir ;BW_RATE 0x2C 0b00101100 Data rate and power mode control
	LDI R26, 0b00000110	;Dato a transmitir ;BW_RATE
				;(D4=0 sin Low Power)(Rate D3D2D1D0 = 0110 : BW=3.13Hz) 
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY


	LDI R25, 0x2F		;Direccion del registro a escribir ;INT_MAP 0x2F 0b00101111 Interrupt mapping control
	LDI R26, 0b11110111	;Dato a transmitir ;INT_MAP
				;solo la inactividad conectada al pin INT1, el resto conectadas al pin INT2
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY


	LDI R25, 0x2E		;Direccion del registro a escribir ;INT_MAP 0x2E 0b00101110 Interrupt enable control
	LDI R26, 0b00001000	;Dato a transmitir ;INT_ENABLE
				;se habilita solo la interrupcion por inactividad
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY


; Solo queda la duda de si en Reg 0x2D POWER_CTL hay que poner el (Measure)D3 en 1 para que anden las interrupciones o no
; Por defecto esta en 0 al encenderse en modo standby

	LDI R25, 0x2D	;Direccion del registro a escribir ;0x2D POWER_CTL 0b00101101 
	LDI R26, 0b00001000	;Dato a transmitir ; MEASURE ON
				;se pone en 1 el bit de Measure, por defecto se prende en modo standby, no queda claro si es necesario
				;ponerlo en modo medicion para que anden las interrupciones
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY


*/

/**************************************************************
CONFIGURACION RTC
***************************************************************/
RTC_CONFIG:

;CONFIGURACION REGISTRO DE CONTROL
LDI R24, 0b11010000
LDI R25,0X0E 
LDI R26,0X00
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION SEGUNDOS
LDI R24, 0b11010000
LDI R25,0x00000000
LDI R26, 0b00000000	;0 seconds
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION MINUTOS
LDI R24, 0b11010000
LDI R25,0x00000001
LDI R26, 0b00000000 ;0minutos
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION HORA
LDI R24, 0b11010000
LDI R25,0x00000010
LDI R26,0b00011001 ;19 horas
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION DIA DE LA SEMANA
LDI R24, 0b11010000
LDI R25,0b00000011
LDI R26,0b00000101 ;dia 5 de la semana, viernes
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION DIA DEL MES
LDI R24, 0b11010000
LDI R25,0b00000100
LDI R26,0b00011000 ;dia 18 del mes
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION MES
LDI R24, 0b11010000
LDI R25,0b00000101
LDI R26,0b00010001 ;mes noviembre
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION AÑO
LDI R24,0b11010000
LDI R25,0b00000110
LDI R26,0b00010110	;año 16
RCALL MULTIPLE_BYTE_WRITE

RET

RTC_READ_SECONDS:
;lectura de datos
LDI R24,0b11010000	;direccion del esclavo+escritura
LDI R25,0b00000000	;direccion del registro de los segundos
LDI R28,0b11010001	;direccion del esclavo+lectura
RCALL SINGLE_BYTE_READ
;EN R23 ESTA EL DATO
RET

RTC_READ_MINUTES:
;lectura de datos
LDI R24,0b11010000	;direccion del esclavo+escritura
LDI R25,0b00000001	;direccion del registro de los minutos
LDI R28,0b11010001	;direccion del esclavo+lectura
RCALL SINGLE_BYTE_READ
;EN R23 ESTA EL DATO que se envia a eeprom y 
RET

RTC_READ_HOURS:
;lectura de datos
LDI R24,0b11010000	;direccion del esclavo+escritura
LDI R25,0b00000010	;direccion del registro de las horas
LDI R28,0b11010001	;direccion del esclavo+lectura
RCALL SINGLE_BYTE_READ
RET

RTC_READ_DAY_OT_WEEK:
;lectura de datos
LDI R24,0b11010000	;direccion del esclavo+escritura
LDI R25,0b00000011	;direccion del registro del dia de la semana
LDI R28,0b11010001	;direccion del esclavo+lectura
RCALL SINGLE_BYTE_READ
RET

RTC_READ_DAY_OT_MONTH:
;lectura de datos
LDI R24,0b11010000	;direccion del esclavo+escritura
LDI R25,0b00000100	;direccion del registro del dia del mes
LDI R28,0b11010001	;direccion del esclavo+lectura
RCALL SINGLE_BYTE_READ
RET

RTC_READ_MONTH:
;lectura de datos
LDI R24,0b11010000	;direccion del esclavo+escritura
LDI R25,0b00000101	;direccion del registro del mes
LDI R28,0b11010001	;direccion del esclavo+lectura
RCALL SINGLE_BYTE_READ
RET

RTC_READ_YEAR:
;lectura de datos
LDI R24,0b11010000	;direccion del esclavo+escritura
LDI R25,0b00000110	;direccion del registro del dia del año
LDI R28,0b11010001	;direccion del esclavo+lectura
RCALL SINGLE_BYTE_READ
RET


/**************************************************************
CONFIGURACION BLUETOOTH
***************************************************************/
;CONFIG_BLUETOOTH:




/**************************************************************
BLOQUE PRINCIPAL
***************************************************************/

/*

; Si entro al bloque principal, se apaga uno de los LEDs del puerto D
LDI R20, 0b00010000
OUT PORTD, R20
 
; Entra en modo sleep, al suceder una interrupcion se despierta en la instruccion siguiente
SLEEP_MODE:
			ldi R16,0b00000101	; lsb = 1 para activar el sleep mode
			out SMCR,R16
			SLEEP
			ldi R16,0b00000100	; lsb = 0 para desactivar el sleep mode
			out SMCR,R16
			
; En las rutinas de interrupcion se usa R19 para almacenar un registro indicador del tipo de interrupcion ocurrida
; Es una analogia del switch/case del lenguaje C

			CPI R19,1
			BREQ ALARMA
RETORNO_ALARMA:
			CPI R19,2
			BREQ BLUETOOTH
RETORNO_BLUETOOTH:
			RJMP SLEEP_MODE

*/








; Biblioteca I2C

/**************************************************************
CONFIGURACION I2C
***************************************************************/
CONFIG_I2C:

I2C_INIT:
	LDI R21, 0		
	STS TWSR, R21		; Preescaler 1 en TWI Status Reg
	LDI R21, 0xB0		;
	STS TWBR, R21		; Setea la frecuencia a 50.087 kHz (18.432 MHz XTAL)
	LDI R21, (1<<TWEN)	; 0x04 a R21 (TWEN: Enable bit)
	STS TWCR, R21		; Habilita el TWI 
	RET

	

; TWINT:TWI Interrupt Flag 
; TWSTA:TWI Start condition bit

I2C_START:
	LDI R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN);
	STS TWCR, R21		; Transimitir condicion de START
	
WAIT1:
	LDS R21, TWCR		; Lee el registro
	SBRS R21, TWINT		; Saltea siguiente linea si TWINT es 1(==operacion finalizada)
	RJMP WAIT1			; TWINT esta en 0
	RET



; Se debe cargar el dato a enviar en el registro TWDR (R27)
; TWDR: TWI Data Register

I2C_WRITE:
	STS TWDR, R27		; Lleva el byte a TWDR
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
	RJMP WAIT2
	LDS R27, TWDR		; Guarda en R27 el dato leido
	RET



;TWSTO:TWI Stop condition bit

I2C_STOP:
	LDI R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
	STS TWCR, R21		; Transmitir condicion de STOP
	RET


; Check value of TWI status register. Mask prescaler bits. If
; status different from START go to ERROR

CHECK_TWI_ST_REG:
	LDS R21,TWSR		; TWSR: TWI status register
	ANDI R21, 0xF8		; Mascara
	CP R21, R17			; El status se pasa por R17
	BRNE ERROR
	RJMP NO_ERROR
ERROR:
	LDI R20, 0b00000000	; En caso de error del status se prenden los LEDs Verdes
	OUT PORTD, R20		
	RET
NO_ERROR:
	RET


; Subrutina de escritura de registros del acelerometro 
MULTIPLE_BYTE_WRITE:		
	RCALL I2C_START		; Transmite la condicion de START
	LDI R17, 0x10		; 0x08: A START condition has been transmitted
						; 0x10: A repeated START condition has been transmitted
	RCALL CHECK_TWI_ST_REG; Chequea que este OK el status reg del TWI, recibe previamente el status en R17
	
	MOV R27, R24		; Carga la direccion del esclavo + configuracion W
	RCALL I2C_WRITE		; Escribe R27 al bus I2C
	LDI R17, 0x18		; 0x18: SLA+W has been transmitted ;ACK has been received
	RCALL CHECK_TWI_ST_REG;
	
	MOV R27, R25		; Direccion del registro a escribir
	RCALL I2C_WRITE		; Escribe R27 al bus I2C
	LDI R17, 0x28		; 0x28: Data byte has been transmitted; ACK has been received
	RCALL CHECK_TWI_ST_REG;
	
	MOV R27, R26		; Dato a transmitir 
	RCALL I2C_WRITE		; Escribe R27 al bus I2C
	LDI R17, 0x28		; 0x28: Data byte has been transmitted; ACK has been received
	RCALL CHECK_TWI_ST_REG;

	RCALL I2C_STOP 		;Transmite la condicion de STOP
	RET



; Subrutina de lectura de registros del acelerometro 
SINGLE_BYTE_READ:
	RCALL I2C_START		; Transmite la condicion de START
	LDI R17, 0x08		;  0x08: A START condition has been transmitted
	RCALL CHECK_TWI_ST_REG; Chequea que este OK el status reg del TWI, recibe previamente el status en R17
	
	MOV R27, R24		; Carga la direccion del esclavo + configuracion W
	RCALL I2C_WRITE		; Escribe R27 al bus I2C
	LDI R17, 0x18		; 0x18: SLA+W has been transmitted ;ACK has been received
	RCALL CHECK_TWI_ST_REG;

	MOV R27, R25		; Direccion del registro a escribir
	RCALL I2C_WRITE		; Escribe R27 al bus I2C
	LDI R17, 0x28		; 0x28: Data byte has been transmitted; ACK has been received
	RCALL CHECK_TWI_ST_REG;

	RCALL I2C_START		; Retransmite Start
	LDI R17, 0x10		; 0x10: A repeated START condition has been transmitted
	RCALL CHECK_TWI_ST_REG
	
	MOV R27, R28		; Carga la direccion del esclavo + configuracion R
	RCALL I2C_WRITE
	LDI R17, 0x40		; 0x40: SLA+R has been transmitted; ACK has been received
	RCALL CHECK_TWI_ST_REG;

	RCALL I2C_READ
	LDI R17, 0x58		; 0x58: Data byte has been received; NOT ACK has been returned
	RCALL CHECK_TWI_ST_REG;
	MOV R23, R27

	RCALL I2C_STOP 		
	RET


; En algunos ejemplos del Libro se usaba un Delay
;DELAY:
;	LDI R22, 0xFF
;A1: DEC R22
;	NOP
;	BRNE A1
;	RET

