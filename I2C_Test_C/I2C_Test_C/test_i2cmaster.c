/****************************************************************************
Title:    Access serial Acelerometro ADXL345 using I2C interace
Author:   Peter Fleury <pfleury@gmx.ch>
Edit:     Mariano Iglesias 18/11/16
File:     $Id: test_i2cmaster.c,v 1.3 2015/09/16 09:29:24 peter Exp $
Software: AVR-GCC 4.x
Hardware: any AVR device can be used when using i2cmaster.S or any
          AVR device with hardware TWI interface when using twimaster.c

Description:
    This example shows how the I2C/TWI library i2cmaster.S or twimaster.c 
	can be used to access a serial eeprom.

*****************************************************************************/
#include <avr/io.h>
#include "i2cmaster.h"


#define DevADXL345  0xA6      // Direccion del esclavo SLA(1010011) + (0); en el .h lo acomoda


int main(void)
{
    unsigned char ret;

    DDRC  = 0x0C;                              // LEDs Rojos 
    PORTC = 0x0C;                              // (active low LED's )

    DDRD  = 0x90;                              // LEDs Verdes 
    PORTD = 0x90;                              // (active low LED's )

/*
; LEDs para las pruebas (Puerto C: Rojos; Puerto D: Verdes)
LDI R20, 0b00001100         ; Hay LEDs conectados a los bits seteados en dichos puertos
OUT DDRC, R20           
LDI R20, 0b00001100         ; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTC, R20  

LDI R20, 0b10010000         ; Hay LEDs conectados a los bits seteados en dichos puertos
OUT DDRD, R20   
LDI R20, 0b10010000         ; Con un 1 quedan apagados por la logica de la placa Club de Robotica
OUT PORTD, R20  
*/


    i2c_init();                                // init I2C interface

/*
; Se realiza la lectura del registro DEVID que tiene una direccion: 0x00 y reset value: 11100101
    LDI R24, 0xA6       ; Direccion del esclavo SLA(1010011) + Write(0)
    LDI R28, 0xA7       ; Direccion del esclavo SLA(1010011) + Read(1)
    LDI R25, 0x00       ; Direccion del registro a leer DEVID 
    LDI R26, 0b11100101 ; Dato contra el que se debe comparar la lectura
    RCALL SINGLE_BYTE_READ 
;   RCALL DELAY         ; Estaba presente en algunos codigos del Libro pero no tuvo efecto aqui

    CP R23, R26
    BREQ WRITE_OK       ; Se encienden LEDs en caso de lectura exitosa
    RJMP CONTINUE       ; Si no, se continua
WRITE_OK:                   
    LDI R20, 0b00000000
    OUT PORTC, R20  
CONTINUE:               
*/

    ret = i2c_start(DevADXL345+I2C_WRITE);       // set device address and write mode
    if ( ret ) {
        /* failed to issue start condition, possibly no device found */
        i2c_stop();
        PORTD = 0x00;                            // Prende LEDs Verdes en caso de ERROR
    }else {
        /* issuing start condition ok, device accessible */
        i2c_write(0x00);                       // Direccion del registro a leer DEVID
        i2c_rep_start(DevADXL345+I2C_READ);       // set device address and read mode
        ret = i2c_readNak();                    // read one byte
        i2c_stop();
        
        if(ret == 0xE5)
            PORTC = 0x00;                      // Prende LEDs Rojos en caso de Lectura correcta
    
	//
	 i2c_start_wait(DevADXL345+I2C_WRITE);     // set device address and write mode
	 i2c_write(0x25);                        // write address = 5
	 i2c_write(0b00010001);
	 i2c_stop();
	 
	 
	 i2c_start_wait(DevADXL345+I2C_WRITE);     // set device address and write mode
	 i2c_write(0x25);                        // write address = 5
	i2c_rep_start(DevADXL345+I2C_READ);       // set device address and read mode
	ret = i2c_readNak();                    // read one byte
	i2c_stop();
	
	if(ret == 0xE5)
	PORTC = 0x00;                      // Prende LEDs Rojos en caso de Lectura correcta
	//
	
	
	
	
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
	
	
	
	}
    
    for(;;);	
}
