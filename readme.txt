This archive was downloaded from www.partusch.de.vu

CONTENT of the archive
======================

 bfd.com          The Brainfucked compiler
 bfd.asm          The source code of Brainfucked

 src/		  Some examples in Brainfuck
 src/factor.b	  Factors an arbitrarily large positive integer
 src/hello.b	  Prints "Hello World!"
 src/numwarp.b	  A number...obfuscator? Prettifier? See source.
 src/prime.b	  Can find all primes between 0 and 255
 src/quine.b	  Prints its own source code

 gpl.txt          GNU General Public License

 readme.txt       The file you are reading
 liesmich.txt     This file in German


THE LANGUAGE
============

Every brainfuck program has an array and a pointer, that points to the array.
The array as well as the pointer can be manipulated with eight different
commands:

 Command  Effect                                   Same in C
 -------  ------                                   ---------
 +        Increase element under the pointer       ++*p;
 -        Decrease element under the pointer       --*p;
 >        Increase pointer                         p++;
 <        Decrease pointer                         p--;
 [        Start loop                               while(*p) {
 ]        End loop, when element is zero           }
 .        Print ASCII code of element              putchar(*p);
 ,        Read character and store it              *p=getchar();

All other characters are ignored (and can therefore be used for annotation).
All elements of the array are initialized with 0.

There is further information about the language available under
http://en.wikipedia.org/wiki/Brainfuck


BRAINFUCKED - THE COMPILER
==========================

Usage
-----
The compiler must be started in the prompt of Windows or directly under DOS. It is called with
"bfd filename.ending". Call it for example with "bfd src/hello.b" (without the double quotes).
It is important, that the name of the source code file follows the DOS style "8.3". That is, that the
file name must be shorter than nine (but longer than two) characters and the file extension shorter
than four characters. If that's not the case, Brainfucked will react with a "ERR: File"-error message.

Code optimization
-----------------
Brainfucked has quite good code optimization abilities. It optimizes your brainfuck programs to use as
little memory as possible, which also improves the speed of execution.

Syntax checking
---------------
Brainfucked checks the syntax of your programs. If it discovers an (possible) error, it prints an
error message or a warning. See "Messages".

Compatibility
-------------
Brainfucked knows two different modes to create brainfuck programs.

In standard mode the ENTER-key will result in the value 10 (LF), when it's is read by the "," command.
And the value 10 (LF) will create a complete DOS/Windows-line break (CR LF), when printing it with the
"." command. Therefore the standard mode is able to correctly run brainfuck programs, which are written
for Unix environments. Most more complex brainfuck programs are written for these environments. Thus
it's, for compatibility reasons, reommended to develop own programs according to these specifications.

When calling Brainfucked with the parameter "-n" (e.g. "bfd -n src/hello.b"), the native mode will be
used by Brainfucked to compile the source.
In this mode the input read from "," is the same as the plain DOS/Windows key codes. A ENTER-key
therefore results in the value 13 (CR). You also have to "manually" print 13 and 10 (CR LF) to create
a correct line break. This mode is only intended for brainfuck programs, which are specifically written
for DOS/Windows. These programs are, however, unable to run on many other brainfuck implementations.
It is not recommended to develop own programs for this mode.

In both modes an array of 44000 cells is available to every brainfuck program and each cell has
a size of one byte. Every cell is initialized with 0.

Behavior of Brainfuck commands:
-------------------------------------------------------------------------------------
Command  |  Behavior in standard mode              |  Behavior in native mode
-------------------------------------------------------------------------------------
+        |  Increase value                         |  like in standard mode
-        |  Decrease value                         |  like in standard mode
[        |  Start of a loop                        |  like in standard mode
]        |  End of a loop                          |  like in standard mode
.        |  Output an ASCII-value*                 |  Output an ASCII-value*
,        |  Read an and print the ASCII-value*     |  Read an ASCII-value*
>        |  Increase pointer                       |  like in standard mode
<        |  Decrease pointer                       |  like in standard mode
-------------------------------------------------------------------------------------
* see "Compatibility"!


Messages
--------
This is a list of all messages used by Brainfucked and their possible reasons:

---------------------------------------------------------------------------------------------------
Message         |  Meaning                      |  possible Reason
---------------------------------------------------------------------------------------------------
ERR: File       |  Error when processing files  |  File not found or not in 8.3 format
ERR: Loop       |  Serious syntax error         |  At least one wrong loop like "]["
WRN: Range      |  Possible error               |  More < than > found, if not intended, it's most
                |                               |  likely an error!
File assembled  |  File successfully compiled   |  No serious errors occurred ;-)
---------------------------------------------------------------------------------------------------


License
-------
Brainfucked is released under the terms of the GNU General Public License. See gpl.txt in this archive.


   Have fun with Brainfucked!
       - Stefan Partusch (partusch@arcor.de)