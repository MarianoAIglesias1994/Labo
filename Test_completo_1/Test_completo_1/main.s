
/*
 * main.s
 *
 * Created: 19/11/2016 02:17:44 a.m.
 *  Author: MarianoAgustín
 */ 

 /*
 Notas:
1. Al escribir la función main en assembler, es necesario declararla como global.
2. La rutina retardo estará en otro archivo y por lo tanto debe ser declarada como extern.
3. Cuando el proyecto es un proyecto en C, no es necesario inicializar el stack, ya que el compilador realiza la inicialización.
4. Al hacer referencia a un registro de I/O, se lo debe hacer utilizando la macro _SFR_IO_ADDR().
 */

 /**************************************************************
DIRECTIVAS
***************************************************************/
 #include <avr/io.h>
 #define F_CPU 18432000UL 
;.include "m88PAdef.inc" // Lo incluye el AtmelStudio al setear el uC


 

.global main
.extern config_i2cmaster_acel_rtc

//??
.global SLEEP_MODE
.global ISR_INT0_INACTIVITY
.global ISR_INT1_BLUETOOTH
/**************************************************************
VECTORES DE INTERRUPCION
***************************************************************/

.org 0x00
rjmp main

rjmp ISR_INT0_INACTIVITY	
rjmp ISR_INT1_BLUETOOTH	



/**************************************************************
RUTINA DE SERVICIO DE INTERRUPCION POR INACTIVIDAD DEL ACELEROMETRO
***************************************************************/

ISR_INT0_INACTIVITY:
CLI
LDI R19,1	
SEI
RETI

/**************************************************************
RUTINA DE SERVICIO DE INTERRUPCION POR ACTIVACION DEL BLUETOOTH
***************************************************************/

ISR_INT1_BLUETOOTH:
CLI
LDI R19,2	
SEI
RETI


/**************************************************************
MAIN
***************************************************************/

main:


; LEDs para las pruebas (Puerto C: Rojos; Puerto D: Verdes)
LDI R20, 0b00001100			; Hay LEDs conectados a los bits seteados en dichos puertos
OUT _SFR_IO_ADDR(DDRC), R20			
LDI R20, 0b00001100			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT _SFR_IO_ADDR(PORTC), R20	

LDI R20, 0b10010000			; Hay LEDs conectados a los bits seteados en dichos puertos
OUT _SFR_IO_ADDR(DDRD), R20	
LDI R20, 0b10010000			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT _SFR_IO_ADDR(PORTD), R20	




/**************************************************************
CONFIGURACION BAJO CONSUMO
***************************************************************/


CONFIG_BAJO_CONSUMO:
	; Config consumo de energia, PSM o PDM
	ldi R16,0b00000100	; Nibble inferior D3D2D1 = 010 es de power down mode y el lsb D0 = 1 es para activar el sleep mode
	out _SFR_IO_ADDR(SMCR),R16

		
/**************************************************************
INCIALIZACION I2C, CONFIGURACION ACELEROMETRO Y RTC
***************************************************************/

RCALL config_i2cmaster_acel_rtc


/**************************************************************
CONFIGURACION INTERRUPCIONES EXTERNAS
***************************************************************/
CONFIG_INT:

	;EICRA: Configura por flanco o por nivel
	;out R18, EICRA     ; Carga estado previo
	ldi R16,0b00000101	; ldi R16,0b00000001 para INT0; ldi R16,0b00000101 para INT0 e INT1 
	sts _SFR_IO_ADDR(EICRA), R16		;

	;EIMSK: Habilita las interrupciones seleccionadas
	;out R18, EIMSK     ; Carga estado previo
	ldi R16,0b00000011 	; ldi R16,0b00000001 para INT0; ldi R16,0b00000011 para INT0 e INT1 
	out _SFR_IO_ADDR(EIMSK),R16		;

	;EIFR: Tiene que estar seteado junto con el bit de interrupcion global al momento de suceder la interrupcion 
	;in R18, EIFR       ; Carga estado previo
	ldi R16,0b00000101	; ldi R16,0b00000001 para INT0; ldi R16,0b00000011 para INT0 e INT1 
	out _SFR_IO_ADDR(EIFR),R16		;

SEI


; LEDs para las pruebas (Puerto C: Rojos; Puerto D: Verdes)
LDI R20, 0b00001100			; Hay LEDs conectados a los bits seteados en dichos puertos
OUT _SFR_IO_ADDR(DDRC), R20			
LDI R20, 0b00001100			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT _SFR_IO_ADDR(PORTC), R20	

LDI R20, 0b10010000			; Hay LEDs conectados a los bits seteados en dichos puertos
OUT _SFR_IO_ADDR(DDRD), R20	
LDI R20, 0b10010000			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT _SFR_IO_ADDR(PORTD), R20	

/**************************************************************
CONFIGURACION BLUETOOTH
***************************************************************/
;CONFIG_BLUETOOTH:




/**************************************************************
BLOQUE PRINCIPAL
***************************************************************/


; Si entro al bloque principal, se prenden los LEDs del puerto D
			LDI R20, 0b00000000	
			OUT _SFR_IO_ADDR(PORTD), R20

; Entra en modo sleep, al suceder una interrupcion se despierta en la instruccion siguiente
SLEEP_MODE:
			
			ldi R16,0b00000101	; lsb = 1 para activar el sleep mode
			out _SFR_IO_ADDR(SMCR),R16
			SLEEP
			ldi R16,0b00000100	; lsb = 0 para desactivar el sleep mode
			out _SFR_IO_ADDR(SMCR),R16

			
; En las rutinas de interrupcion se usa R19 para almacenar un registro indicador del tipo de interrupcion ocurrida
; Es una analogia del switch/case del lenguaje C
		
			CPI R19,1
			BREQ ALARMA
RETORNO_ALARMA:
			CPI R19,2
			BREQ BLUETOOTH
RETORNO_BLUETOOTH:
			RJMP SLEEP_MODE



/**************************************************************
RUTINA ENVIO DE ENVIO DE DATOS POR BLUETOOTH 
***************************************************************/

BLUETOOTH:	; LED Verde
LDI R21, 10	; Valor de tiempo 

PARPADEO2:
		LDI R20, 0b00000000	; Prende LED
		OUT _SFR_IO_ADDR(PORTD), R20	
		RCALL RETARDO2
		LDI R20, 0b10010000		; Apaga LED
		OUT _SFR_IO_ADDR(PORTD), R20	
		RCALL RETARDO2

		DEC R21
		CPI R21, 0
		BRNE PARPADEO2

		LDI R19,0			; Se limpia el registro indicador
		RJMP RETORNO_BLUETOOTH

RETARDO2:
		LDI R16, 10
LOOP12:	LDI R17, 255
LOOP22:	LDI R18, 255
LOOP32:  DEC R18
		BRNE LOOP32			
		DEC R17
		BRNE LOOP22
		DEC R16
		BRNE LOOP12
		RET
		

/**************************************************************
RUTINA DE ALARMA
***************************************************************/

ALARMA:	; LED Rojo
LDI R21, 10	; Valor de tiempo 

PARPADEO:
		LDI R20, 0b00000000	; Prende LED
		OUT _SFR_IO_ADDR(PORTC), R20	
		RCALL RETARDO
		LDI R20, 0b00001100	; Apaga LED
		OUT _SFR_IO_ADDR(PORTC), R20	
		RCALL RETARDO

		DEC R21
		CPI R21, 0
		BRNE PARPADEO

		LDI R19,0			; Se limpia el registro indicador
		RJMP ALARMA;RETORNO_ALARMA

RETARDO:
		LDI R16, 10
LOOP1:	LDI R17, 255
LOOP2:	LDI R18, 255
LOOP3:  DEC R18
		BRNE LOOP3			
		DEC R17
		BRNE LOOP2
		DEC R16
		BRNE LOOP1
		RET


