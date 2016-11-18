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
    }
    
    for(;;);	
}
