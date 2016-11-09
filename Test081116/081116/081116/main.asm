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


.cseg
.org 0x00
rjmp INICIO
;ver ubicación de INT0 en Vector de Interrupciones Atmel
.org 0x02
rjmp ISR_INT0_INACTIVITY	
;Idem INT1
.org 0x04
rjmp ISR_INT1_BLUETOOTH	
.org 0x3E

INICIO:

	LDI R21, HIGH(RAMEND)	;Configura el STACK
	OUT SPH, R21
	LDI R21, LOW(RAMEND)
	OUT SPL, R21

;CLR R20
;OUT DDRD,R20	;como entrada
;CLR R20
;OUT PORTD,R20	;en 1


/**************************************************************
CONFIGURACION INTERRUPCIONES EXTERNAS
***************************************************************/


CONFIG_INT:
	cli
	sei

	;EIMSK
	;out R18, EIMSK      ;me fijo que hay en eimsk
	ldi R16,1			; 0000 0011
	out EIMSK,R16		;habilito las dos interrupciones externas del mcu. INT0 e INT1

	;EICRA si se configura por flanco o por nivel, hablarlo, depende de la interrupcion INT0 o INT1 utilizada en la seccion de arriba
	;out R18, EICRA      ;me fijo que hay en eicra
	ldi R16, 1			; 1111 1111
	sts EICRA, R16		;habilito todo despues lo cambio

	;EIFR tiene que estar seteado junto con el bit de interrupcion globar para que al momento de suceder la interrupcion 
	;in R18, EIFR      ;me fijo que hay en eifr
	ldi R16,1			; 1111 1111
	out EIFR,R16		;habilito todo despues lo cambio

/**************************************************************
CONFIGURACION BAJO CONSUMO
***************************************************************/
	;;por ahora lo comento, despues probamos
CONFIG_BAJO_CONSUMO:
	;;configuro el consumo de energia, PSM o PDM
	;;in R18,SMCR	;
	ldi R16,0x09	;0000 0101  010 es de power down mode y el lsb es para activar el sleep mode
	out SMCR,R16


/**************************************************************
CONFIGURACION I2C
***************************************************************/
CONFIG_I2C:

I2C_INIT:
	LDI R21, 0		
	STS TWSR, R21		;Preescaler 1 en TWI Status Reg
	LDI R21, 0x47
	STS TWBR, R21		;Setea la frecuencia a 50k (8MHz XTAL)
	LDI R21, (1<<TWEN)	;0x04 a R21 (TWEN: Enable bit)
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
	STS TWDR, R27		;Lleva el byte a TWDR
	LDI R21, (1<<TWINT)|(1<<TWEN) ;Se setean TWINT y TWEN en el TWCR
	STS TWCR, R21		;Configura TWCR para enviar TWDR

WAIT2:
	LDS R21, TWCR		;Lee el registro de control a R21
	SBRS R21, TWINT		;Saltea siguiente línea si TWINT es 1
	RJMP WAIT2		;Salta a WAIT2 si TWINT es 0
	RET


;TWSTO:TWI Stop condition bit

I2C_STOP:
	LDI R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
	STS TWCR, R21		;Transmitir condición de STOP
	RET

/**************************************************************
INCIALIZO I2C
***************************************************************/

RCALL I2C_INIT




/**************************************************************
CONFIGURACION ACELEROMETRO
***************************************************************/
CONFIG_ACELEROMETRO:
;Información sacada de la data sheet del ADXL345

	LDI R24, 0b10100110	;Dirección del esclavo SLA(1010011) + Write(0)
	LDI R25, 0b00011001	;Dirección del registro a escribir ;THRESH_INACT 0x25 0b00011001
	LDI R26, 0b10000000	;Dato a transmitir ;THRESH_INACT  8 bit unsigned no dejar en 0x00 umbral de inactividad (62.5 mg/LSB) 
				;en 128 despues hacer ajuste fino
	RCALL SINGLE_BYTE_WRITE

	LDI R25, 0b00011010	;Dirección del registro a escribir ;TIME_INACT 0x26 0b00011010 umbral de tiempo de inactividad
	LDI R26, 0b00001010	;Dato a transmitir ;TIME_INACT  (máximo 255 segundos) (1 sec/LSB)
				;en 10s despues hacer ajuste fino
	RCALL SINGLE_BYTE_WRITE

	LDI R25, 0b00011011	;Dirección del registro a escribir ;ACT_INACT_CTL 0x27 0b00011011 controla los ejes que intervienen
	LDI R26, 0b00001111	;Dato a transmitir ;ACT_INACT_CTL 
				;en 0b00001111 (D3 en 1=ac coupled)(D2D1D0 = 111 enable en los tres ejes)
	RCALL SINGLE_BYTE_WRITE

	LDI R25, 0b00101100	;Dirección del registro a escribir ;BW_RATE 0x2C 0b00101100 Data rate and power mode control
	LDI R26, 0b00001010	;Dato a transmitir ;BW_RATE
				;en lo que viene por defecto (D4=0 sin Low Power)(Rate D3D2D1D0 = 1010 : BW=50Hz) podria disminuirse
	RCALL SINGLE_BYTE_WRITE

	LDI R25, 0b00101111	;Dirección del registro a escribir ;INT_MAP 0x2F 0b00101100 Interrupt mapping control
	LDI R26, 0b11110111	;Dato a transmitir ;INT_MAP
				;sólo la inactividad conectada al pin INT1, el resto conectadas al pin INT2
				;Por defecto en active high, se puede cambiar con INT_INVERT bit en DATA_FORMAT 0x31
	RCALL SINGLE_BYTE_WRITE

	LDI R25, 0b00101110	;Dirección del registro a escribir ;INT_MAP 0x2E 0b00101110 Interrupt enable control
	LDI R26, 0b00001000	;Dato a transmitir ;INT_ENABLE
				;se habilita sólo la interrupción por inactividad
	RCALL SINGLE_BYTE_WRITE

;Sólo queda la duda de si en Reg 0x2D POWER_CTL hay que poner el (Measure)D3 en 1 para que anden las interrupciones o no. Por defecto está en 0

SINGLE_BYTE_WRITE:
	RCALL I2C_START		;Transmite la condición de START
	MOV R27, R24		;Carga la dirección del esclavo + configuración R/W
	RCALL I2C_WRITE		;Escribe R27 al bus I2C
	MOV R27, R25		;Dirección del registro a escribir
	RCALL I2C_WRITE		;Escribe R27 al bus I2C
	MOV R27, R26		;Dato a transmitir 
	RCALL I2C_WRITE		;Escribe R27 al bus I2C
	RCALL I2C_STOP 		;Transmite la condición de STOP
	RET



/**************************************************************
CONFIGURACION RTC
***************************************************************/
CONFIG_RTC:

/**************************************************************
CONFIGURACION BLUETOOTH
***************************************************************/
CONFIG_BLUETOOTH:


/**************************************************************
BLOQUE PRINCIPAL
***************************************************************/
;se queda esperando que haya una interrupcion 
SLEEP_MODE:
		;	sleep
			;CPI R18,1
			RJMP ALARMA
RETORNO_ALARMA:
			CPI R18,2
			BREQ BLUETOOTH
RETORNO_BLUETOOTH:
			RJMP SLEEP_MODE


/**************************************************************
RUTINA DE SERVICIO DE INTERRUPCION POR INACTIVIDAD DEL ACELEROMETRO
***************************************************************/
ISR_INT0_INACTIVITY:
PUSH R16; se guarda para que no se pise lo que habia en r16 antes de la interrupcion
IN R16, SREG
PUSH R16
POP R16
OUT SREG, R16
POP R16
LDI R18,1	
RETI


/**************************************************************
RUTINA DE SERVICIO DE INTERRUPCION POR ACTIVACION DEL BLUETOOTH
***************************************************************/
ISR_INT1_BLUETOOTH:
PUSH R16; se guarda para que no se pise lo que habia en r16 antes de la interrupcion
IN R16, SREG
PUSH R16
POP R16
OUT SREG, R16
POP R16
LDI R18,2	
RETI



/**************************************************************
RUTINA DE ALARMA
***************************************************************/
ALARMA:
/*PRENDE Y APAGA LED (EQUIVALENTE A SONAR ALARMA) Y GAURDAR DATOS EN RTC*/
SER R20
OUT DDRC,R20	;el port C esta como salida
LDI R21, 255	;valor a ajustar tiempo 



PARPADEO:
		SER R20
		OUT PORTC,R20	;los pines de port C estan en 1
		RCALL RETARDO
		CLR	R20
		OUT PORTC,R20	;los pines de port C estan en 0
		RCALL RETARDO

		DEC R21
		CPI R21, 0
		BRNE PARPADEO
		RJMP RETORNO_ALARMA

RETARDO:
		LDI R16, 1
LOOP1:	LDI R17, 100
LOOP2:	BRNE LOOP2
		DEC R16
		BRNE LOOP1
		RET





/**************************************************************
RUTINA ENVIO DE ENVIO DE DATOS POR BLUETOOTH 
***************************************************************/
BLUETOOTH:

RJMP RETORNO_BLUETOOTH