#!/bin/bash
# Interface Dialog pour RTL-SDR - Zipacna 2017 - www.zipacna.fr

FREQUENCIES="cli_scanner_frequencies.csv"
RTL_FM_BIN=./rtl_fm
RTL_TCP_BIN=rtl_tcp

dialog --backtitle "CLI-Scanner - V1.0" --title "Welcome" --msgbox "CLI Scanner is a frontend for RTL-SDR\n\nIn case of problem, please contact us at register@zipacna.fr" 10 100

set_defaults()
{
	FREQ_PARAMETER="446M"
	MODE_PARAMETER="fm"
	SQUELCH="30"
	SQUELCH_DELAY="20"
	CHOICE_SAMPLERATE="24k"
	TUNER_GAIN="40"
	#OUTPUT="play -t raw -es -b 16 -c 1 -V1 "
	#OUTPUT="dsd -s -i - -o /dev/snd/controlC0"
	#OUTPUT="aplay -r 24k -f S16_LE -t raw -c 1"
	#OUTPUT="aplay -f S16_LE -t raw -c 1"
}

set_frequencies()
{
	FREQ=$(cat $FREQUENCIES | grep -v "#" | cut -d "," -f1)

	MENU_FREQ=$(dialog --clear --backtitle "CLI-Scanner - V1.0" --title "Select Frequencies" --menu "Select :" 30 60 40 ${FREQ[@]} 2>&1 >/dev/tty)
			if [ $? = 1 ];then
			main_menu
			fi
	CHOICE_FREQ=$(cat $FREQUENCIES | grep -e "^$MENU_FREQ " | cut -d "," -f1)
	FREQ_PARAMETER=$(cat $FREQUENCIES | grep -e "^$MENU_FREQ " | cut -d "," -f2)
	CHOICE_SAMPLERATE=$(cat $FREQUENCIES | grep -e "^$MENU_FREQ " | cut -d "," -f3)
	MODE_PARAMETER=$(cat $FREQUENCIES | grep -e "^$MENU_FREQ " | cut -d "," -f4)
configure_output
}

set_mode()
{
	MENU_MODE=$(dialog --clear --backtitle "CLI-Scanner - V1.0" --title "Select Modes" --menu "Select :" 30 60 40 1 FM 2 AM 3 LSB 4 USB 5 RAW 2>&1 >/dev/tty)
			if [ $? = 1 ];then
			main_menu
			fi
	if [ "$MENU_MODE" = "1" ]; then MODE_PARAMETER="fm"; fi
	if [ "$MENU_MODE" = "2" ]; then MODE_PARAMETER="am"; fi
	if [ "$MENU_MODE" = "3" ]; then MODE_PARAMETER="lsb"; fi
	if [ "$MENU_MODE" = "4" ]; then MODE_PARAMETER="usb"; fi
	if [ "$MENU_MODE" = "5" ]; then MODE_PARAMETER="raw"; fi
}

set_squelch()
{
	SQUELCH=$(dialog --clear --backtitle "CLI-Scanner - V1.0" --title "Set Squelch" --rangebox "" 1 100 0 500 $SQUELCH 2>&1 >/dev/tty)
                        if [ $? = 1 ];then
                        main_menu
                        fi
}

set_squelch_delay()
{
	SQUELCH_DELAY=$(dialog --clear --backtitle "CLI-Scanner - V1.0" --title "Set Squelch Delay" --rangebox "" 1 50 0 100 20 2>&1 >/dev/tty)
                        if [ $? = 1 ];then
                        main_menu
                        fi
}

set_tuner_gain()
{
	MENU_GAIN=$(dialog --clear --backtitle "CLI-Scanner - V1.0" --title "Select Modes" --menu "Select :" 20 30 30 1 AUTO 2 USER 2>&1 >/dev/tty)
			if [ $? = 1 ];then
			main_menu
			fi
	if [ "$MENU_GAIN" = "1" ]; then TUNER_GAIN="auto"; main_menu; fi
	if [ "$MENU_GAIN" = "2" ]; then 
	TUNER_GAIN=$(dialog --clear --backtitle "CLI-Scanner - V1.0" --title "Set Tuner Gain" --rangebox "" 1 50 0 50 40 2>&1 >/dev/tty)
                        if [ $? = 1 ];then
			TUNER_GAIN="auto"
                        main_menu
                        fi
	fi
}

set_sample_rate()
{
	
	MENU_SAMPLERATE=$(dialog --clear --backtitle "CLI-Scanner - V1.0" --title "Select Modes" --menu "Select :" 30 60 40 1 12.5k 2 24k 3 25k 4 100k 2>&1 >/dev/tty)
			if [ $? = 1 ];then
			main_menu
			fi
	if [ "$MENU_SAMPLERATE" = "1" ]; then CHOICE_SAMPLERATE="12.5k"; fi
	if [ "$MENU_SAMPLERATE" = "2" ]; then CHOICE_SAMPLERATE="24k"; fi
	if [ "$MENU_SAMPLERATE" = "3" ]; then CHOICE_SAMPLERATE="25k"; fi
	if [ "$MENU_SAMPLERATE" = "4" ]; then CHOICE_SAMPLERATE="100k"; fi
configure_output
}

edit_frequencies()
{
	dialog --clear --backtitle "CLI-Scanner - V1.0" --title "Edit Frequencies" --editbox $FREQUENCIES 30 80 2>cli_scanner_frequencies.user
		if [ $? = 1 ];then
			main_menu
		else
			cp $FREQUENCIES cli_scanner_frequencies.bak
			cp cli_scanner_frequencies.user $FREQUENCIES
		fi
}

configure_output()
{
	MENU_OUTPUT=$(dialog --clear --backtitle "CLI-Scanner - V1.0" --title "Select Modes" --menu "Select :" 30 60 40 1 RASPBERRY 2 MAC 3 DSD 2>&1 >/dev/tty)
			if [ $? = 1 ];then
			main_menu
			fi
	if [ "$MENU_OUTPUT" = "1" ]; then OUTPUT="aplay -f S16_LE -t raw -c 1 -r $CHOICE_SAMPLERATE -"; fi
	if [ "$MENU_OUTPUT" = "2" ]; then OUTPUT="play -t raw -es -b 16 -c 1 -V1 -r $CHOICE_SAMPLERATE -"; fi
	if [ "$MENU_OUTPUT" = "3" ]; then OUTPUT="dsd -s -i - -o /dev/snd/controlC0"; fi
}

start_scanning()
{
	killall -s9 rtl_fm
	if [ -z "$OUTPUT" ]; then dialog --clear --colors --backtitle "CLI-Scanner - V1.0" --title "ERROR !" --msgbox "No Output Selected" 5 30; main_menu; fi

	if [ "$TUNER_GAIN" = "auto" ]; then
		COMMAND="$RTL_FM_BIN -M $MODE_PARAMETER -f$FREQ_PARAMETER -s $CHOICE_SAMPLERATE -l $SQUELCH | $OUTPUT"
	else
		COMMAND="$RTL_FM_BIN -M $MODE_PARAMETER -f$FREQ_PARAMETER -g $TUNER_GAIN -s $CHOICE_SAMPLERATE -l $SQUELCH | $OUTPUT"
	fi

	echo $COMMAND > debug.log
	dialog --clear --colors --backtitle "CLI-Scanner - V1.0" --title "Running: CTRL+C to Exit" --prgbox "\Z1$COMMAND\Zn" "$COMMAND" 30 80
}

start_tcp()
{
	dialog --clear --colors --backtitle "CLI-Scanner - V1.0" --title "Running: CTRL+C to Exit" --prgbox "RTL_TCP" "$RTL_TCP_BIN -a 192.168.1.2 -p 1234" 30 80
}

main_menu ()
{
	MAIN_MENU=$(dialog --clear --backtitle "CLI-Scanner - V1.0" --title "Main Menu" --colors --menu "\ZbFREQUENCY:\Zn$FREQ_PARAMETER/$CHOICE_SAMPLERATE \ZbMODE:\Zn$MODE_PARAMETER \ZbSQUELCH:\Zn$SQUELCH\Zb TUNER GAIN:\Zn$TUNER_GAIN" 10 90 0 \
1 "\Z1START scanning !\Zn" \
2 "START TCP" \
3 "Set Frequencies" \
4 "Set Mode" \
5 "Set Squelch" \
6 "Set Squelch Delay" \
7 "Set Sample Rate" \
8 "Set Tuner Gain" \
9 "Configure Output" \
10 "Edit Frequencies" 2>&1 >/dev/tty)

	if [ "$?" = "1" ]; then
	echo "FREQ_PARAMETER=\"$FREQ_PARAMETER\"" > session.save
	echo "MODE_PARAMETER=\"$MODE_PARAMETER\"" >> session.save
	echo "SQUELCH=\"$SQUELCH\"" >> session.save
	echo "SQUELCH_DELAY=\"$SQUELCH_DELAY\"" >> session.save
	echo "CHOICE_SAMPLERATE=\"$CHOICE_SAMPLERATE\"" >> session.save
	echo "TUNER_GAIN=\"$TUNER_GAIN\"" >> session.save
	echo "OUTPUT=\"$OUTPUT\"" >> session.save
	clear
	exit
	fi
	if [ "$MAIN_MENU" = "1" ]; then start_scanning; main_menu; fi
	if [ "$MAIN_MENU" = "2" ]; then start_tcp; main_menu; fi
	if [ "$MAIN_MENU" = "3" ]; then set_frequencies; main_menu; fi
	if [ "$MAIN_MENU" = "4" ]; then set_mode; main_menu; fi
	if [ "$MAIN_MENU" = "5" ]; then set_squelch; main_menu; fi
	if [ "$MAIN_MENU" = "6" ]; then set_squelch_delay; main_menu; fi
	if [ "$MAIN_MENU" = "7" ]; then set_sample_rate; main_menu; fi
	if [ "$MAIN_MENU" = "8" ]; then set_tuner_gain; main_menu; fi
	if [ "$MAIN_MENU" = "9" ]; then configure_output; main_menu; fi
	if [ "$MAIN_MENU" = "10" ]; then edit_frequencies; main_menu; fi
}

if [ -f session.save ]; then

	. session.save
else
	set_defaults
fi

main_menu
