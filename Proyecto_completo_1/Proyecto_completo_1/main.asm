;
; Proyecto_completo_1.asm
;
; Created: 24/11/2016 02:42:27 a.m.
; Author : MarianoAgustín
;


/**************************************************************
DIRECTIVAS
***************************************************************/
;#ifndef F_CPU
#define F_CPU 16000000UL 
;#include "m88PAdef.inc" ; Lo incluye el AtmelStudio al setear el uC
.include "m328Pdef.inc"



/**************************************************************
VECTORES DE INTERRUPCION
***************************************************************/
.cseg
.org 0x00
rjmp main

.org 0x02				; Por alguna razon traen problemas
rjmp ISR_INT0_INACTIVITY	
.org 0x04				; Por alguna razon traen problemas
rjmp ISR_INT1_BLUETOOTH	


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
LDI R20, 0b00000000			; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTD, R20	

/**************************************************************
CONFIGURACION INTERRUPCIONES EXTERNAS
***************************************************************/

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



/**************************************************************
CONFIGURACION BAJO CONSUMO
***************************************************************/


CONFIG_BAJO_CONSUMO:
	; Config consumo de energia, PSM o PDM
	ldi R16,0b00000100	; Nibble inferior D3D2D1 = 010 es de power down mode y el lsb D0 = 1 es para activar el sleep mode
	out SMCR,R16

	
/**************************************************************
INCIALIZACION I2C
***************************************************************/

RCALL I2C_INIT


/**************************************************************
CONFIGURACION ACELEROMETRO
***************************************************************/

CONFIG_ACELEROMETRO:

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
	;LDI R25, 0x00		; Direccion del registro a leer DEVID 
	;LDI R26, 0b11100101	; Dato contra el que se debe comparar la lectura
	


	;The inactivity bit is set when acceleration of less than the value
	;stored in the THRESH_INACT register (Address 0x25) is experienced
	;for more time than is specified in the TIME_INACT
	;register (Address 0x26). The maximum value for TIME_INACT
	;is 255 sec. 

; Se comienza la secuencia de seteo del acelerometro en los valores necesarios

	LDI R25, 0x25		;Direccion del registro a escribir ;THRESH_INACT 0x25 0b0010010
	LDI R26, 0b00000001	;Dato a transmitir ;THRESH_INACT  8 bit unsigned. No dejar en 0x00 umbral de inactividad (62.5 mg/LSB) 
				;en 17 = 0b00010001 despues hacer ajuste fino
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY


	LDI R25, 0x26		;Direccion del registro a escribir ;TIME_INACT 0x26 0b00100110 umbral de tiempo de inactividad
	LDI R26, 0b00000010	;Dato a transmitir ;TIME_INACT  (maximo 255 segundos) (1 sec/LSB)
				;en 1s despues hacer ajuste fino
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY


	LDI R25, 0x27		;Direccion del registro a escribir ;ACT_INACT_CTL 0x27 0b00100111 controla los ejes que intervienen
	LDI R26, 0b00001111	;Dato a transmitir ;ACT_INACT_CTL 
				;en 0b00000111 (D3 en 1=ac coupled)(D2D1D0 = 111 enable en los tres ejes)
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

	
;limpia el flag de inactivity en el acel

LDI R24, 0xA6		; Direccion del esclavo SLA(1010011) + Write(0)
LDI R28, 0xA7		; Direccion del esclavo SLA(1010011) + Read(1)
LDI R25, 0x30		; Direccion del registro a leer DEVID 
LDI R26, 0b00000010	; Dato contra el que se debe comparar la lectura
RCALL SINGLE_BYTE_READ

CP	R26,R23
BRNE NO_INACTi
OKi:
LDI R20, 0b00000001
OUT PORTC, R20	

NO_INACTi:		


/**************************************************************
CONFIGURACION RTC
***************************************************************/
CONFIG_RTC:

;CONFIGURACION REGISTRO DE CONTROL
LDI R24, 0b11010000
LDI R28, 0b11010001
LDI R25, 0x0E 
LDI R26, 0x00
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION SEGUNDOS
LDI R25, 0b00000000
LDI R26, 0b00000000				
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION MINUTOS
LDI R25, 0b00000001
LDI R26, 0b00000000
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION HORA
LDI R25, 0b00000010
LDI R26, 0b00011001
RCALL MULTIPLE_BYTE_WRITE


;CONFIGURACION DIA DE LA SEMANA
LDI R25, 0b00000011
LDI R26, 0b00000101 ;dia 5 de la semana, viernes
RCALL MULTIPLE_BYTE_WRITE


;CONFIGURACION DIA DEL MES
LDI R25, 0b00000100
LDI R26, 0b00011000
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION MES
LDI R25, 0b00000101
LDI R26, 0b00010001
RCALL MULTIPLE_BYTE_WRITE

;CONFIGURACION AÑO
LDI R25,0b00000110
LDI R26,0b00010110
RCALL MULTIPLE_BYTE_WRITE



	

/**************************************************************
CONFIGURACION BLUETOOTH
***************************************************************/

RCALL RETARDO_BT
RCALL USART_INIT
RCALL RETARDO_BT






/**************************************************************
BLOQUE PRINCIPAL
***************************************************************/

 
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





/**************************************************************
RUTINA ENVIO DE ENVIO DE DATOS POR BLUETOOTH 
***************************************************************/



BLUETOOTH:	; D4
LDI R21, 10	; Valor de tiempo 

PARPADEO2:
		LDI R20, 0b00010000	; Prende LED
		OUT PORTD, R20	
		RCALL RETARDO2
		LDI R20, 0b00000000	; Apaga LED
		OUT PORTD, R20	
		RCALL RETARDO2

		DEC R21
		CPI R21, 0
		BRNE PARPADEO2



		MOV R19, R2;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV R19, R3;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV R19, R4;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV R19, R5;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV R19, R6;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV R19, R7;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV R19, R8;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		
RCALL CLEAN_INACT

RCALL AUX

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


RETARDO3:
		LDI R16, 5
LOOP13:	LDI R17, 255
LOOP23:	LDI R18, 255
LOOP33:  DEC R18
		BRNE LOOP33		
		DEC R17
		BRNE LOOP23
		DEC R16
		BRNE LOOP13
		RET

/**************************************************************
RUTINA DE ALARMA
***************************************************************/



ALARMA:	; D5 Verde
LDI R21, 200	; Valor de tiempo 



RCALL PARPADEO
RCALL RETARDO3
RCALL PARPADEO
RCALL RETARDO3
RCALL PARPADEO
RCALL RETARDO3

		LDI R24, 0b11010000		;direccion del esclavo+escritura
		LDI R28, 0b11010001	;direccion del esclavo+lectura
	
	
		LDI R25, 0b00000000	;
		RCALL SINGLE_BYTE_READ
		MOV R2,R23	

		LDI R25, 0b00000001	;va a ser utilizada por RTC_READ
		RCALL SINGLE_BYTE_READ
		MOV R3,R23		

		LDI R25, 0b00000010	;va a ser utilizada por RTC_READ
		RCALL SINGLE_BYTE_READ
		MOV R4,R23	
		
		;CONFIGURACION DIA DE LA SEMANA
		LDI R25, 0b00000011
		RCALL SINGLE_BYTE_READ
		MOV R5,R23
				
		LDI R25, 0b00000100	;va a ser utilizada por RTC_READ
		RCALL SINGLE_BYTE_READ
		MOV R6,R23	
		
		
		LDI R25, 0b00000101	;va a ser utilizada por RTC_READ
		RCALL SINGLE_BYTE_READ
		MOV R7,R23	
		

		LDI R25, 0b00000110	;va a ser utilizada por RTC_READ
		RCALL SINGLE_BYTE_READ
		MOV R8,R23


RCALL CLEAN_INACT



;;;;;;;;;;;;;;


RCALL AUX

;;;;;;;;;;;;;;;;


		LDI R19,0			; Se limpia el registro indicador
		RJMP RETORNO_ALARMA


RETARDO:
		LDI R16, 1
LOOP1:	LDI R17, 50
LOOP2:	LDI R18, 50
LOOP3:  DEC R18
		BRNE LOOP3			
		DEC R17
		BRNE LOOP2
		DEC R16
		BRNE LOOP1
		RET

		PARPADEO:
		LDI R20, 0b00100000	; Prende LED
		OUT PORTD, R20	
		RCALL RETARDO
		LDI R20, 0b00000000	; Apaga LED
		OUT PORTD, R20	
		RCALL RETARDO

		DEC R21
		CPI R21, 0
		BRNE PARPADEO
		RET

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





CLEAN_INACT:
;limpia el flag de inactivity en el acel

LDI R24, 0xA6		; Direccion del esclavo SLA(1010011) + Write(0)
LDI R28, 0xA7		; Direccion del esclavo SLA(1010011) + Read(1)
LDI R25, 0x30		; Direccion del registro a leer DEVID 
LDI R26, 0b00000010	; Dato contra el que se debe comparar la lectura
RCALL SINGLE_BYTE_READ

CP	R26,R23
BRNE NO_INACT
OK:
LDI R20, 0b00000001
OUT PORTC, R20	
NO_INACT:

RET

AUX:

; Se realiza la lectura del registro DEVID que tiene una direccion: 0x00 y reset value: 11100101
	LDI R24, 0xA6		; Direccion del esclavo SLA(1010011) + Write(0)
	LDI R28, 0xA7		; Direccion del esclavo SLA(1010011) + Read(1)
	;LDI R25, 0x00		; Direccion del registro a leer DEVID 
	;LDI R26, 0b11100101	; Dato contra el que se debe comparar la lectura
	


	;The inactivity bit is set when acceleration of less than the value
	;stored in the THRESH_INACT register (Address 0x25) is experienced
	;for more time than is specified in the TIME_INACT
	;register (Address 0x26). The maximum value for TIME_INACT
	;is 255 sec. 

; Se comienza la secuencia de seteo del acelerometro en los valores necesarios

	LDI R25, 0x25		;Direccion del registro a escribir ;THRESH_INACT 0x25 0b0010010
	LDI R26, 0b00000110	;Dato a transmitir ;THRESH_INACT  8 bit unsigned. No dejar en 0x00 umbral de inactividad (62.5 mg/LSB)11111110 
				;en 17 = 0b00010001 despues hacer ajuste fino
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY


	LDI R25, 0x26		;Direccion del registro a escribir ;TIME_INACT 0x26 0b00100110 umbral de tiempo de inactividad
	LDI R26, 0b00000010	;Dato a transmitir ;TIME_INACT  (maximo 255 segundos) (1 sec/LSB)
				;en 1s despues hacer ajuste fino
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY


	LDI R25, 0x27		;Direccion del registro a escribir ;ACT_INACT_CTL 0x27 0b00100111 controla los ejes que intervienen
	LDI R26, 0b00001111	;Dato a transmitir ;ACT_INACT_CTL 
				;en 0b00000111 (D3 en 1=ac coupled)(D2D1D0 = 111 enable en los tres ejes)
	RCALL MULTIPLE_BYTE_WRITE
;	RCALL DELAY

	
	LDI R25, 0x2C		;Direccion del registro a escribir ;BW_RATE 0x2C 0b00101100 Data rate and power mode control
	LDI R26, 0b00001110	;Dato a transmitir ;BW_RATE
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
RET

; Biblioteca I2C

/**************************************************************
CONFIGURACION I2C
***************************************************************/


CONFIG_I2C:

I2C_INIT:
	LDI R21, 0		
	STS TWSR, R21		; Preescaler 1 en TWI Status Reg
	LDI R21, 0xB0		;  0xB0
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
	RJMP WAIT3
	LDS R27, TWDR		; Guarda en R27 el dato leido
	RET



;TWSTO:TWI Stop condition bit

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




/**************************************************************
CONFIGURACION BLUETOOTH
***************************************************************/


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

RETARDO_BT:
			LDI R16, 20
LOOP1BT:	LDI R17, 255
LOOP2BT:	LDI R18, 255
LOOP3BT:  DEC R18
		BRNE LOOP3BT			
		DEC R17
		BRNE LOOP2BT
		DEC R16
		BRNE LOOP1BT
		RET

