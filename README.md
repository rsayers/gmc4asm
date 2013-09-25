gmc4asm
=======
Author: Rob Sayers <rsayers@robsayers.com>

An assembler for the Gakken GMC4 in Ruby

Requirements: Ruby 2.0.  Possibly works in 1.9, but untested.

Usage:
	gmc4asm.rb [OPTIONS] src.asm
	Options:
	        -h Help: Display this message
        	-l LED Output: Display hex values along with the GMC4 Led indicators
	        -a ASM Output (Default): Display Text addresses, hex values, and original assembly code


The input source must be valid assembly, as documented here: http://tsoj.manga.org/gakken/otona_gmc.html

Asm output mode will output addresses, assembled hex, and the equivalent asm code all one one line.

LED output mode shows one hex value per line, and provides an indicator as to what LEDs will be lit on the device to make it easier to input programs.

This has currently been tested only on limited programs, but seems to work pretty well.  One huge exception is that JUMPs can only point to labels defined beforehand, and cannot jump forward.  This will be corrected in the next release


License
-------

I, the copyright holder of this work, hereby release it into the public domain. This applies worldwide.

In case this is not legally possible, I grant any entity the right to use this work for any purpose, without any conditions, unless such conditions are required by law.