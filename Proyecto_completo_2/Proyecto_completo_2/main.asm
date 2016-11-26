;
; Proyecto_completo_2.asm
;
; Created: 25/11/2016 08:18:55 p.m.
; Author : MarianoAgustín
;
/**************************************************************
DIRECTIVAS
***************************************************************/
#define F_CPU 16000000UL 
.include "m328Pdef.inc"

.def AUX1 = R21
.def TEMP = R17
.def UART_DATA = R18
.def SWITCH = R19
.def SLA_W = R20
.def SLA_R = R16
.def REG_DIR = R22
.def DATA_OUT = R23
.def DATA_IN = R24
.def AUX_I2C = R25

.def SEGUNDOS = R2
.def MINUTOS = R3
.def HORA = R4
.def DIA_SEMANA = R5
.def DIA_MES = R6
.def MES = R7
.def ANIO = R8

.equ CASE_NULL = 0
.equ CASE_INACT = 1
.equ CASE_BT = 2

.equ ORG_MAIN = 0x00
.equ ORG_ISR_INT0_INACTIVITY = 0x02
.equ ORG_ISR_INT1_BLUETOOTH = 0x04

.equ NULL = 0b00000000
.equ BT_ENABLE = 0b00000001 
.equ INACT_BT_LEDS = 0b00110000	
.equ TODO_CAMBIO_LOGICO_INT0_INT1 = 0b00000101 
.equ INT0_INT1_ENABLE = 0b00000011
.equ POWER_DOWN_MODE_SLEEP_OFF = 0b00000100 ; Nibble inferior D3D2D1 = 010 es de power down mode y el lsb D0 = 1 es para activar el sleep mode
.equ POWER_DOWN_MODE_SLEEP_ON = 0b00000101
.equ BT_LED_TIME = 10; Duracion LED titilando
.equ INACT_LED_BUZZER_TIME = 200; Duracion LED y buzzer titilando
.equ BT_LED = 0b00010000
.equ INACT_LED = 0b00100000

.equ ACELEROMETRO_SLA_W = 0xA6; Direccion del esclavo SLA(1010011) + Write(0)
.equ ACELEROMETRO_SLA_R = 0xA7; Direccion del esclavo SLA(1010011) + Read(1)
.equ THRESH_INACT = 0x25; Umbral de inactividad
.equ THRESH_INACT_VAL = 0b00000001; 8 bit unsigned. No dejar en 0x00 umbral de inactividad (62.5 mg/LSB)
.equ TIME_INACT = 0x26; Umbral de tiempo de inactividad
.equ TIME_INACT_VAL = 0b00000010; (maximo 255 segundos) (1 sec/LSB)
.equ ACT_INACT_CTL = 0x27; Controla los ejes que intervienen
.equ ACT_INACT_CTL_VAL = 0b00001111; (D3 en 1=ac coupled)(D2D1D0 = 111 enable en los tres ejes)
.equ BW_RATE = 0x2C; Data rate and power mode control
.equ BW_RATE_VAL = 0b00000110 ;(D4=0 sin Low Power)(Rate D3D2D1D0 = 0110 : BW=3.13Hz) 
.equ INT_MAP = 0x2F; Interrupt mapping control
.equ INT_MAP_VAL = 0b11110111; Solo la inactividad conectada al pin INT1, el resto conectadas al pin INT2
.equ INT_ENABLE = 0x2E; Interrupt enable control
.equ INT_ENABLE_VAL = 0b00001000; Se habilita solo la interrupcion por inactividad
.equ POWER_CTL = 0x2D; 
.equ POWER_CTL_VAL = 0b00001000	; MEASURE ON, por defecto se prende en modo standby
.equ INT_SOURCE = 0x30; -Muestra la causa de interrupcion, read only

.equ RTC_SLA_W = 0b11010000; Direccion del esclavo + Write(0)
.equ RTC_SLA_R = 0b11010001; Direccion del esclavo + Read(1)
.equ RTC_CTRL_REG = 0x0E; CONFIGURACION REGISTRO DE CONTROL
.equ RTC_CTRL_REG_VAL = 0x00
.equ RTC_SEGUNDOS_REG = 0b00000000; CONFIGURACION SEGUNDOS
.equ RTC_SEGUNDOS_REG_VAL = 0b00000000
.equ RTC_MINUTOS_REG = 0b00000001; CONFIGURACION MINUTOS
.equ RTC_MINUTOS_REG_VAL = 0b00000000
.equ RTC_HORA_REG = 0b00000010; CONFIGURACION HORA
.equ RTC_HORA_REG_VAL = 0b00011001
.equ RTC_DIA_SEMANA_REG = 0b00000011; CONFIGURACION DIA DE LA SEMANA
.equ RTC_DIA_SEMANA_REG_VAL = 0b00000101 ;dia 5 de la semana, viernes
.equ RTC_DIA_MES_REG = 0b00000100; CONFIGURACION DIA DEL MES
.equ RTC_DIA_MES_REG_VAL = 0b00011000
.equ RTC_MES_REG = 0b00000101; CONFIGURACION MES
.equ RTC_MES_REG_VAL = 0b00010001
.equ RTC_ANIO_REG = 0b00000110; CONFIGURACION AÑO
.equ RTC_ANIO_REG_VAL = 0b00010110

.equ UBRR0L_VALUE = 0x67
.equ UBRR0H_VALUE = 0x00


/**************************************************************
VECTORES DE INTERRUPCION
***************************************************************/

.cseg
.org ORG_MAIN
rjmp main
.org ORG_ISR_INT0_INACTIVITY				
rjmp ISR_INT0_INACTIVITY	
.org ORG_ISR_INT1_BLUETOOTH				
rjmp ISR_INT1_BLUETOOTH	


/**************************************************************
MAIN
***************************************************************/

main:


/**************************************************************
CONFIGURACION STACK
***************************************************************/

	LDI TEMP, HIGH(RAMEND)	; Configura el STACK
	OUT SPH, TEMP
	LDI TEMP, LOW(RAMEND)
	OUT SPL, TEMP


/**************************************************************
CONFIGURACION PUERTOS
***************************************************************/

	LDI TEMP, BT_ENABLE		; Habilita Vcc a BT
	OUT DDRC, TEMP			
	LDI TEMP, BT_ENABLE		
	OUT PORTC, TEMP	

	LDI TEMP, INACT_BT_LEDS	; LEDs conectados a los bits seteados en dichos puertos
	OUT DDRD, TEMP
	LDI TEMP, NULL		; LEDs apagados
	OUT PORTD, TEMP	


/**************************************************************
CONFIGURACION INTERRUPCIONES EXTERNAS
***************************************************************/

CONFIG_INT:

	;EICRA: Configura por flanco o por nivel
	ldi TEMP, TODO_CAMBIO_LOGICO_INT0_INT1; Cualquier cambio logico en INT0 e INT1 
	sts EICRA, TEMP		;

	;EIMSK: Habilita las interrupciones seleccionadas
	ldi TEMP, INT0_INT1_ENABLE; Habilita INT0 e INT1 
	out EIMSK, TEMP		;

	;EIFR: Tiene que estar seteado junto con el bit de interrupcion global al momento de suceder la interrupcion 
	ldi TEMP, INT0_INT1_ENABLE	; Para INT0 e INT1 
	out EIFR, TEMP		;

	SEI


/**************************************************************
CONFIGURACION BAJO CONSUMO
***************************************************************/

CONFIG_BAJO_CONSUMO:
	; Config consumo de energia, PSM o PDM
	ldi TEMP, POWER_DOWN_MODE_SLEEP_OFF
	out SMCR, TEMP

	
/**************************************************************
INCIALIZACION I2C
***************************************************************/

RCALL I2C_INIT


/**************************************************************
CONFIGURACION ACELEROMETRO
***************************************************************/

RCALL CONFIG_ACELEROMETRO
RCALL CLEAN_INACT
	

/**************************************************************
CONFIGURACION RTC
***************************************************************/

RCALL CONFIG_RTC


/**************************************************************
CONFIGURACION BLUETOOTH
***************************************************************/
RCALL RETARDO_BT
RCALL USART_INIT
RCALL RETARDO_BT


/**************************************************************
BLOQUE PRINCIPAL
***************************************************************/

SLEEP_MODE:
			ldi TEMP, POWER_DOWN_MODE_SLEEP_ON	; Activa el sleep mode
			out SMCR, TEMP
			SLEEP ; Entra en modo sleep, al suceder una interrupcion se despierta en la instruccion siguiente
			ldi TEMP, POWER_DOWN_MODE_SLEEP_OFF	; Desactiva el sleep mode
			out SMCR, TEMP
			
; En las rutinas de interrupcion se usa SWITCH para almacenar un registro indicador del tipo de interrupcion ocurrida
; Es una analogia del switch/case del lenguaje C

			CPI SWITCH, CASE_INACT
			BREQ ALARMA
RETORNO_ALARMA:
			CPI SWITCH, CASE_BT
			BREQ BLUETOOTH
RETORNO_BLUETOOTH:
			RJMP SLEEP_MODE


/**************************************************************
RUTINA ENVIO DE ENVIO DE DATOS POR BLUETOOTH 
***************************************************************/

BLUETOOTH:
LDI AUX1, BT_LED_TIME

PARPADEO2:
		LDI TEMP, BT_LED; Prende LED
		OUT PORTD, TEMP	
		RCALL RETARDO2
		LDI TEMP, NULL	; Apaga LED
		OUT PORTD, TEMP	
		RCALL RETARDO2

		DEC AUX1
		CPI AUX1, NULL
		BRNE PARPADEO2

; Envia los datos
		MOV UART_DATA, SEGUNDOS;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV UART_DATA, MINUTOS;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV UART_DATA, HORA;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV UART_DATA, DIA_SEMANA;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV UART_DATA, DIA_MES;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV UART_DATA, MES;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		MOV UART_DATA, ANIO;
		RCALL USART_TRANSMISION	;
		RCALL RETARDO_BT

		
		RCALL CLEAN_INACT
		RCALL CONFIG_ACELEROMETRO

		LDI SWITCH, CASE_NULL		; Se limpia el registro indicador
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
LOOP33: DEC R18
		BRNE LOOP33		
		DEC R17
		BRNE LOOP23
		DEC R16
		BRNE LOOP13
		RET

/**************************************************************
RUTINA DE ALARMA
***************************************************************/

ALARMA:	
		LDI AUX1, INACT_LED_BUZZER_TIME

		RCALL PARPADEO
		RCALL RETARDO3
		RCALL PARPADEO
		RCALL RETARDO3
		RCALL PARPADEO
		RCALL RETARDO3

		LDI SLA_W, RTC_SLA_W
		LDI SLA_R, RTC_SLA_R
	
		LDI REG_DIR, RTC_SEGUNDOS_REG
		RCALL SINGLE_BYTE_READ
		MOV SEGUNDOS,DATA_IN	

		LDI REG_DIR, RTC_MINUTOS_REG
		RCALL SINGLE_BYTE_READ
		MOV MINUTOS,DATA_IN		

		LDI REG_DIR, RTC_HORA_REG
		RCALL SINGLE_BYTE_READ
		MOV HORA,DATA_IN	
		
		LDI REG_DIR, RTC_DIA_SEMANA_REG
		RCALL SINGLE_BYTE_READ
		MOV DIA_SEMANA,DATA_IN
				
		LDI REG_DIR, RTC_DIA_MES_REG
		RCALL SINGLE_BYTE_READ
		MOV DIA_MES,DATA_IN	 
		
		LDI REG_DIR,RTC_MES_REG
		RCALL SINGLE_BYTE_READ
		MOV MES,DATA_IN	
		
		LDI REG_DIR, RTC_ANIO_REG
		RCALL SINGLE_BYTE_READ
		MOV ANIO,DATA_IN


		RCALL CLEAN_INACT
		RCALL CONFIG_ACELEROMETRO

		LDI SWITCH, CASE_NULL; Se limpia el registro indicador
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
	LDI TEMP, INACT_LED	; Prende LED
	OUT PORTD, TEMP	
	RCALL RETARDO
	LDI TEMP, NULL	; Apaga LED
	OUT PORTD, TEMP	
	RCALL RETARDO
	
	DEC AUX1
	CPI AUX1, NULL
	BRNE PARPADEO
	RET


/**************************************************************
RUTINA DE SERVICIO DE INTERRUPCION POR INACTIVIDAD DEL ACELEROMETRO
***************************************************************/


ISR_INT0_INACTIVITY:
CLI
LDI SWITCH, CASE_INACT	
SEI
RETI



/**************************************************************
RUTINA DE SERVICIO DE INTERRUPCION POR ACTIVACION DEL BLUETOOTH
***************************************************************/


ISR_INT1_BLUETOOTH:
CLI
LDI SWITCH, CASE_BT
SEI
RETI




/**************************************************************
CONFIGURACION ACELEROMETRO
***************************************************************/

CONFIG_ACELEROMETRO:

	LDI SLA_W, ACELEROMETRO_SLA_W		
	LDI SLA_R, ACELEROMETRO_SLA_R		

; Se comienza la secuencia de seteo del acelerometro en los valores necesarios

	LDI REG_DIR, THRESH_INACT	
	LDI DATA_OUT, THRESH_INACT_VAL	
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, TIME_INACT		
	LDI DATA_OUT, TIME_INACT_VAL
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, ACT_INACT_CTL		
	LDI DATA_OUT, ACT_INACT_CTL_VAL	
	RCALL MULTIPLE_BYTE_WRITE
	
	LDI REG_DIR, BW_RATE		
	LDI DATA_OUT, BW_RATE_VAL 
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, INT_MAP
	LDI DATA_OUT, INT_MAP_VAL
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, INT_ENABLE
	LDI DATA_OUT, INT_ENABLE_VAL
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, POWER_CTL
	LDI DATA_OUT, POWER_CTL_VAL
	RCALL MULTIPLE_BYTE_WRITE

RET



CLEAN_INACT: ; Limpia el flag de inactivity en el acelerometro

	LDI SLA_W, ACELEROMETRO_SLA_W
	LDI SLA_R, ACELEROMETRO_SLA_R
	LDI REG_DIR, INT_SOURCE
	RCALL SINGLE_BYTE_READ
RET


/**************************************************************
CONFIGURACION RTC
***************************************************************/

CONFIG_RTC:

	LDI SLA_W, RTC_SLA_W
	LDI SLA_R, RTC_SLA_R

	LDI REG_DIR, RTC_CTRL_REG
	LDI DATA_OUT, RTC_CTRL_REG_VAL
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, RTC_SEGUNDOS_REG
	LDI DATA_OUT, RTC_SEGUNDOS_REG_VAL			
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, RTC_MINUTOS_REG
	LDI DATA_OUT, RTC_MINUTOS_REG_VAL
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, RTC_HORA_REG
	LDI DATA_OUT, RTC_HORA_REG_VAL
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, RTC_DIA_SEMANA_REG
	LDI DATA_OUT, RTC_DIA_SEMANA_REG_VAL
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, RTC_DIA_MES_REG
	LDI DATA_OUT, RTC_DIA_MES_REG_VAL
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, RTC_MES_REG
	LDI DATA_OUT, RTC_MES_REG_VAL
	RCALL MULTIPLE_BYTE_WRITE

	LDI REG_DIR, RTC_ANIO_REG
	LDI DATA_OUT, RTC_ANIO_REG_VAL
	RCALL MULTIPLE_BYTE_WRITE

RET


/**************************************************************
CONFIGURACION I2C
***************************************************************/

I2C_INIT:
	LDI TEMP, NULL		
	STS TWSR, TEMP		; Preescaler 1 en TWI Status Reg
	LDI TEMP, 0xB0		; 0xB0
	STS TWBR, TEMP		; Setea la frecuencia a 50.087 kHz (16 MHz XTAL); Ver cuanto da con 16 MHz
	LDI TEMP, (1<<TWEN)	; 0x04 a TEMP (TWEN: Enable bit)
	STS TWCR, TEMP		; Habilita el TWI 
	RET


I2C_START:
	LDI TEMP, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN);
	STS TWCR, TEMP		; Transimitir condicion de START
	
WAIT1:
	LDS TEMP, TWCR		; Lee el registro
	SBRS TEMP, TWINT		; Saltea siguiente linea si TWINT es 1 (==operacion finalizada)
	RJMP WAIT1			; TWINT esta en 0
	RET


I2C_WRITE:
	STS TWDR, AUX_I2C		; Lleva el byte a TWDR
	LDI TEMP, (1<<TWINT)|(1<<TWEN) ; Se setean TWINT y TWEN en el TWCR
	STS TWCR, TEMP		; Configura TWCR para enviar TWDR

WAIT2:
	LDS TEMP, TWCR		; Lee el registro de control a TEMP
	SBRS TEMP, TWINT		; Saltea siguiente linea si TWINT es 1
	RJMP WAIT2			; TWINT esta en 0
	RET


I2C_READ:
	LDI TEMP, (1<<TWINT)|(1<<TWEN)
	STS TWCR, TEMP

WAIT3:
	LDS TEMP, TWCR
	SBRS TEMP, TWINT
	RJMP WAIT3
	LDS AUX_I2C, TWDR		; Guarda en AUX_I2C el dato leido
	RET


I2C_STOP:
	LDI TEMP, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
	STS TWCR, TEMP		; Transmitir condicion de STOP
	RET


; Subrutina de escritura de registros de perifericos
MULTIPLE_BYTE_WRITE:		
	RCALL I2C_START		; Transmite la condicion de START
	MOV AUX_I2C, SLA_W		; Carga la direccion del esclavo + configuracion W
	RCALL I2C_WRITE		; Escribe AUX_I2C al bus I2C
	MOV AUX_I2C, REG_DIR	; Direccion del registro a escribir
	RCALL I2C_WRITE		; Escribe AUX_I2C al bus I2C
	MOV AUX_I2C, DATA_OUT	; Dato a transmitir 
	RCALL I2C_WRITE		; Escribe AUX_I2C al bus I2C
	RCALL I2C_STOP 		; Transmite la condicion de STOP
	RET


; Subrutina de lectura de registros de perifericos 
SINGLE_BYTE_READ:
	RCALL I2C_START		; Transmite la condicion de START
	MOV AUX_I2C, SLA_W		; Carga la direccion del esclavo + configuracion W
	RCALL I2C_WRITE		; Escribe AUX_I2C al bus I2C
	MOV AUX_I2C, REG_DIR	; Direccion del registro a leer
	RCALL I2C_WRITE		; Escribe AUX_I2C al bus I2C
	RCALL I2C_START		; Retransmite Start
	MOV AUX_I2C, SLA_R		; Carga la direccion del esclavo + configuracion R
	RCALL I2C_WRITE
	LDI AUX_I2C, NULL
	RCALL I2C_READ
	MOV DATA_IN, AUX_I2C
	RCALL I2C_STOP
	RET


/**************************************************************
CONFIGURACION BLUETOOTH
***************************************************************/

USART_INIT:
	;Baud rate en 9600
	LDI TEMP, UBRR0L_VALUE
	STS UBRR0L, TEMP
	LDI TEMP, UBRR0H_VALUE
	STS UBRR0H, TEMP

	LDI TEMP, (1<<TXEN0); Habilitacion TX
	STS UCSR0B, TEMP

	LDI TEMP, (1<<USBS0)|(3<<UCSZ00); 8 bits por dato, 2 bits de stop
	STS UCSR0C, TEMP
RET


USART_TRANSMISION:
	LDS	TEMP,UCSR0A		; Chequea que el buffer este listo para la transmision
	SBRS	TEMP,UDRE0
	RJMP	USART_TRANSMISION
	STS	UDR0, UART_DATA		; Envía la informacion que hay en el registro UART_DATA al buffer para ser enviada
RET

RETARDO_BT:
		LDI R16, 20
LOOP1BT:LDI R17, 255
LOOP2BT:LDI R18, 255
LOOP3BT:DEC R18
		BRNE LOOP3BT			
		DEC R17
		BRNE LOOP2BT
		DEC R16
		BRNE LOOP1BT
RET