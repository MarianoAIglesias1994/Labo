/*
 * config_i2c_acel_rtc.c
 *
 * Created: 19/11/2016 01:47:03 a.m.
 * Author : MarianoAgustín
 */ 
/****************************************************************************
Controlador Acelerometro ADXL345 y RTC DS3231 con interfaz I2C

Basado en la biblioteca I2C de Peter Fleury
*****************************************************************************/
#include <avr/io.h>
#include "i2cmaster.h"


#define DevADXL345  0xA6      // Direccion del esclavo SLA(1010011) + (0); en el .h lo acomoda
/*
;Conexiones hardware:
;Arduino Pin	ADXL345 Pin		Placa CdR Atmega88pa-pu
;GND				GND				8,22
;3V3				VCC				7,20
;3V3				CS
;GND				SDO
;A4					SDA				27
;A5					SCL				28
;					INT1			4
*/

#define DevDS3231  0xD0     // Direccion del esclavo SLA(1101000) + (0); en el .h lo acomoda



int main(void)
{
	unsigned char ret;

	DDRC  = 0x0C;                              // LEDs Rojos
	PORTC = 0x0C;                              // (active low LED's )

	DDRD  = 0x90;                              // LEDs Verdes
	PORTD = 0x90;                              // (active low LED's )

	i2c_init();                                // init I2C interface
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
		
		//; Se comienza la secuencia de seteo del acelerometro en los valores necesarios
		//
		i2c_start_wait(DevADXL345+I2C_WRITE);
		i2c_write(0x25);                        // ;Dato a transmitir ;THRESH_INACT  8 bit unsigned. No dejar en 0x00 umbral de inactividad (62.5 mg/LSB)
		i2c_write(0x11);
		i2c_stop();
		
		i2c_start_wait(DevADXL345+I2C_WRITE);
		i2c_write(0x25);
		i2c_rep_start(DevADXL345+I2C_READ);
		ret = i2c_readNak();
		i2c_stop();
		
		if(ret == 0x11)
			PORTC &= 0x04;                       // Prende 1 LED Rojo en caso de Lectura correcta
		//
		
		//
		i2c_start_wait(DevADXL345+I2C_WRITE);
		i2c_write(0x26);                        // ;Dato a transmitir ;TIME_INACT  (maximo 255 segundos) (1 sec/LSB)
		i2c_write(0x01);
		i2c_stop();
		//

		//
		i2c_start_wait(DevADXL345+I2C_WRITE);
		i2c_write(0x27);                        // ;Dato a transmitir ;ACT_INACT_CTL ;en 0b00001111 (D3 en 1=ac coupled)(D2D1D0 = 111 enable en los tres ejes)
		i2c_write(0x0F);
		i2c_stop();
		//
		
		//
		i2c_start_wait(DevADXL345+I2C_WRITE);
		i2c_write(0x2C);                        //BW_RATE;(D4=0 sin Low Power)(Rate D3D2D1D0 = 0110 : BW=3.13Hz)
		i2c_write(0x06);
		i2c_stop();
		//

		//
		i2c_start_wait(DevADXL345+I2C_WRITE);
		i2c_write(0x2F);                        //;INT_MAP	;solo la inactividad conectada al pin INT1, el resto conectadas al pin INT2
		i2c_write(0xF7);
		i2c_stop();
		//

		//
		i2c_start_wait(DevADXL345+I2C_WRITE);
		i2c_write(0x2E);                        //;INT_ENABLE		;se habilita solo la interrupcion por inactividad
		i2c_write(0x08);
		i2c_stop();
		//

		//
		i2c_start_wait(DevADXL345+I2C_WRITE);
		i2c_write(0x2D);                        //;POWER_CTL MEASURE ON
		i2c_write(0x08);						//	;se pone en 1 el bit de Measure, por defecto se prende en modo standby, no queda claro si es necesario
		i2c_stop();								//	;ponerlo en modo medicion para que anden las interrupciones
		//

		//; Fin de la secuencia de seteo del acelerometro en los valores necesarios

		//; Se comienza la secuencia de seteo del rtc en los valores necesarios

		//
		i2c_start_wait(DevDS3231+I2C_WRITE);
		i2c_write(0x0E);                        // ;CONFIGURACION REGISTRO DE CONTROL
		i2c_write(0x00);
		i2c_stop();
		//

		//
		i2c_start_wait(DevDS3231+I2C_WRITE);
		i2c_write(0x00);                        // ;CONFIGURACION SEGUNDOS
		i2c_write(0x00);
		i2c_stop();
		//

		//
		i2c_start_wait(DevDS3231+I2C_WRITE);
		i2c_write(0x01);                        // ;CONFIGURACION MINUTOS
		i2c_write(0x00);						// ;0minutos
		i2c_stop();
		//

		//
		i2c_start_wait(DevDS3231+I2C_WRITE);
		i2c_write(0x02);                        // ;CONFIGURACION HORA
		i2c_write(0x19);						// ;19 horas
		i2c_stop();
		//
		
		//
		i2c_start_wait(DevDS3231+I2C_WRITE);
		i2c_write(0x03);                        // ;CONFIGURACION DIA DE LA SEMANA
		i2c_write(0x05);						// ;dia 5 de la semana, viernes
		i2c_stop();
		//

		//
		i2c_start_wait(DevDS3231+I2C_WRITE);
		i2c_write(0x04);                        // ;CONFIGURACION DIA DEL MES
		i2c_write(0x18);						// ;dia 18 del mes
		i2c_stop();
		//

		//
		i2c_start_wait(DevDS3231+I2C_WRITE);
		i2c_write(0x05);                        // ;CONFIGURACION MES
		i2c_write(0x11);						// ;mes noviembre
		i2c_stop();
		//

		//
		i2c_start_wait(DevDS3231+I2C_WRITE);
		i2c_write(0x05);                        // ;CONFIGURACION AÑO
		i2c_write(0x16);						// ;año 16
		i2c_stop();
		//

		//; Fin de la secuencia de seteo del rtc en los valores necesarios

		//
		i2c_start_wait(DevDS3231+I2C_WRITE);
		i2c_write(0x05);
		i2c_rep_start(DevDS3231+I2C_READ);
		ret = i2c_readNak();
		i2c_stop();
		
		if(ret == 0x16)
			PORTC &= 0x00;                 // Prende el otro LED Rojo en caso de Lectura correcta
		//
		
	}
	
	for(;;);
}
