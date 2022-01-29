# SAAINT
**Scott Adams Adventure Interpreter for the Colour Maximite 2**

An interpreter allowing the classic works of Interactive Fiction (a.k.a. Text Adventures) by Scott
Adams, Brian Howarth and others to be played on the
[Colour Maximite 2](http://geoffg.net/maximite.html).

Written in MMBasic 5.07 by Thomas Hugo Williams with the assistance of Bill McKinley in 2020-2021.

Although it consists almost entirely of new code it is derived *with permission* from:
 - Scott Adams' "Pirate Adventure" for TRS-80 published in BYTE Magazine Volume 05 Number 12 - December 1980
 - Source-code for a BASIC version of "Adventureland" provided to the authors by Scott Adams.

The authors would also like to thank:
 - Alan Moluf and Bruce Hanson for documenting the data file format used by Scott Adams' adventure games: https://github.com/pdxiv/LuaScott/blob/master/doc/The_ADVENTURE_Data_Base_Format_(1980).md
 - @hope1 for porting "Pirate Adventure" to the BBC Micro which served to show that the task was not as daunting as it first appeared: https://github.com/ahope1/Beeb-Pirate-Adventure.

**IMPORTANT!** Game data (.dat) file are copyright their respective authors and should not be
distributed without permission.

![Screenshot 1](/resources/screenshot-1.png)
![Screenshot 3](/resources/screenshot-3.png)
![Screenshot 2](/resources/screenshot-2.png)
![Screenshot 4](/resources/screenshot-4.png)

Please read the [LICENSE](LICENSE) file for further details about modifying and distributing this
program.

SAAINT is distributed for free but if you enjoy it then perhaps you would like to buy Tom a coffee?
[![paypal](https://www.paypalobjects.com/en_GB/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=T5F7BZ5NZFF66&source=url)

## How do I install it ?

 - Download the [latest release](https://github.com/thwill1000/cmm2-saaint-public/releases/latest)
 - Extract to a directory of your choice, e.g. ```/saaint/```

## How do I run it ?
 - Type ```chdir "/saaint"```
 - Type ```*saaint```

## What adventures does it come with ?

With his kind permission SAAINT is distributed with 12 of Scott Adams' Classic Adventures (SACA).<br/>
These adventures / data files are still copyright Scott Adams and not subject to the open
[LICENSE](LICENSE) covering SAAINT's source-code.

Scott Adams is still very much active in the computer-games industry, you can find his latest games
here:
 - https://www.clopas.net
 - http://www.AdventurelandXL.com
 - https://www.EscapeTheGloomer.com

## How do I play a text adventure ?

When the computer asks "What shall I do ?" type a one or two word command.
The first word is usually a verb - a word you use to do something. The second
is a noun such as a direction or object. Suppose you are in a dark room and
the computer says "I can't see, it's too dark! What shall I do ?"
If you are carrying a torch then you could light it by typing "LIGHT TORCH".

Some (but not all!) of the words you might find useful are:
```
  CLIMB  DIG   DROP  GIVE   GO    HELP     INVENTORY  LIGHT  LOOK  OPEN
  QUIT   READ  SAVE  SCORE  TAKE  UNLIGHT  UNLOCK     WAKE   WEAR
```
If you use a command that the computer can't perform or doesn't understand, it
will say "You use word(s) I don't know." or "I don't understand your command.
When this happens, try thinking of another way to say it or try making a verb
out of the action. Instead of "GO SWIMMING", try "SWIM". You'll also discover
that most objects can be picked up using the last word of their names.
For example. to pick up an OLD BOOK, type "TAKE BOOK". Normally you can only
do things to objects that are either visible or you are carrying.

To speed up play, you can type N, S, E, W, U, D instead of the command
GO NORTH, SOUTH, EAST, WEST, UP, DOWN. For example instead of typing "GO WEST",
simply type "W".

To take an inventory of the items you are carrying type "I".

To save your current progress type "SAVE".

## Where can I find more adventures?

Many more SAAINT compatible adventures can be downloaded from the
[ifarchive.org](https://www.ifarchive.org/indexes/if-archiveXscott-adamsXgamesXscottfree.html):

 - [AdamsGames.zip](https://www.ifarchive.org/if-archive/scott-adams/games/scottfree/AdamsGames.zip)
     - 17 copyrighted Scott Adams adventures, plus a freely distributable sampler.
     - These text adventures were commercially distributed in the 1970s and 1980s, but today they are distributed as Shareware.
     - The games have been converted to "ScottFree" format. Game conversion and readme file by Paul David Doherty.
     - The 12 games that are distributed with SAAINT come from this collection.
     - To install extract contents into ```adventures/scott-adams/```

 - [mysterious.tar.gz](https://www.ifarchive.org/if-archive/scott-adams/games/scottfree/mysterious.tar.gz)
     - The 11 Mysterious Adventures by Brian Howarth (1981-83), converted to ScottFree format by Paul David Doherty:
     - To install extract contents into ```adventures/brian-howarth/```

 - [otheradv.zip](https://www.ifarchive.org/if-archive/scott-adams/games/scottfree/otheradv.zip)
     - 8 miscellaneous adventures by Bruce Hansen, Jim Veneskey and others.
     - To install extract contents into ```adventures/misc/```

 - [desert-scott.zip](https://www.ifarchive.org/if-archive/scott-adams/games/scottfree/desert-scott.zip)
     - An adventure in Scott Adams' TRS-80 game format, BSD license, by Sam Trenholme.
     - "In the adventure, you are lost in a desert and need to find the four treasures to win."
     - Archive also includes a Windows executable and a Z-code version of the game. [file is linked to scott-adams/games/zcode/desert-scott.zip]
     - To install extract contents into ```adventures/misc/```

 - [ghostking.zip](https://www.ifarchive.org/if-archive/scott-adams/games/scottfree/ghostking.zip)
     - Initial release of GHOST KING, the first entry in the fictitious "Scott Adams Literary Adventure Diversions" (S.A.L.A.D.) series of text adventures adapted from classic tales.
     - GHOST KING is provided in Scott Adams .dat format, playable in ScottFree and other modern Scott Adams interpreters.
     - It is based on William Shakespeare's Hamlet and the storytelling style of Scott Adams circa 1980.
     - Documentation and ScottKit source code included. Written and published in 2020 by Jason Compton.
     - To install extract contents into ```adventures/misc/```

## Meta-Commands

The interpreter includes a number of meta-commands all prefixed with a ```*``` that are provided by
the interpreter itself rather than being specific to an adventure:

 - ```*actions <index>```
     - prints details of action ```<index>```.
     - if ```<index>``` is omitted then prints all the actions in the adventure.
     - WARNING! may contain spoilers.
 - ```*debug```
     - enables debug diagnostics:
         - room descriptions are prefixed with the room number.
         - object names are prefixed with the object number.
         - messages are prefixed with the message number.
 - ```*debug off```
     - disables debug diagnostics.
 - ```*look```
     - redescribes the current room. Useful for those adventures that don't implement the ```look``` verb without a noun as a standard command.
 - ```*messages <index>```
     - prints content of message ```<index>```.
     - if ```<index>``` is omitted then prints all the messages in the adventure.
     - WARNING! may contain spoilers.
 - ```*more```
     - enables output paging so that a ```[MORE]``` prompt is shown whenever more output than can be shown on a single screen is generated; this is only likely to happen when replaying a script, see ```*replay``` below.
     - this initially defaults to ```on```, but is persisted across SAAINT sessions.
 - ```*more off```
     - disables output paging for this and future sessions.
 - ```*objects <index>```
     - prints name and current location of object ```<index>```.
     - if ```<index>``` is omitted then prints all the objects in the adventure.
     - WARNING! may contain spoilers.
 - ```*record```
     - prompts the user to select and name one of 10 script file slots and then starts to echo every subsequent command into the selected file.
 - ```*record off```
     - halts recording.
 - ```*replay```
     - prompts the user to select a script file slot and then replays the contents of that file as if the user was typing it at the prompt.
 - ```*replay off```
     - halts replaying.
     - only makes sense if inserted manually into a script file to prevent it from replaying to its end.
 - ```*rooms <index>```
     - prints description and exits from room ```<index>```.
     - if ```<index>``` is omitted then prints all the rooms in the adventure.
     - WARNING! may contain spoilers.
 - ```*seed <+ve integer>```
     - immediately re-seeds the pseudo-random number generator used by the interpreter with the given value.
     - this command is DEPRECATED. Instead specify ```seed = <+ve integer>``` in the "saaint.ini" file to provide a seed that will automatically be used when an adventure is started or restored.
     - note that the pseudo-random number generator is automatically re-seeded with the value 7 when recording or replaying a script so as to ensure any "random" behaviour will be consistent.
 - ```*state```
     - prints the current game state:
         - the number of the current room.
         - the value of the "dark flag".
         - the value of the "remaining light" counter.
         - the indexes of the status bits that are currently set.
         - the value of the counter.
         - the values of the 8 alternate counters.
         - the values of the 6 alternate room registers.
 - ```*vocab```
   - prints the adventure's verb and noun tables.
    - the tables usually only contain the first 3-5 significant characters of each word.
    - an entry preceded by a `+` is a synonym for the previous entry.
   - the noun table does not necessarily contain the nouns for all the adventure's objects, see the output of ```*objects```.
   - WARNING! may contain spoilers.
 - ```*walkthrough```
     - replays walkthrough file (.wlk) for the current adventure if present.
     - walkthrough files should be placed in the same directory as the corresponding "\<adventure\>.dat" file and named "\<adventure\>.wlk".
     - walkthrough files have the same format as the script files created by the ```*record``` command.
     - however the walkthrough files included in this repository are encrypted to avoid spoilers; passwords are available on request.

## The "dump" utility

SAAINT comes with a utility `src/dump.bas` that converts adventure `.dat` files into a (more)
human-readable format:

```
*dump [OPTION]... [FILE]...

Options:
  -r, --raw  Outputs adventure(s) in original TRS-80 / ScottFree ".dat"
             format. In theory excluding any slight nuances in formatting the
             output files should be the same as the input files.

Notes:
  - One or more adventure files may be specified with or without .dat extension.
  - Files may be absolute paths or relative to the current working directory or
    relative to the 'adventures/' directory or its immediate subdirectories.
  - If the list of files includes the entry * then all the .dat files in
    'adventures' and its immediate subdirectories will be processed, i.e.
      *dump *
```

## FAQ

**1. What is the Colour Maximite 2 ?**

The Colour Maximite 2 is a small self contained "Boot to BASIC" computer inspired by the home
computers of the early 80's such as the Tandy TRS-80, Commodore 64 and Apple II.

While the concept of the Colour Maximite 2 is borrowed from the computers of the 80's the technology
used is very much up to date.  Its CPU is an ARM Cortex-M7 32-bit RISC processor running at 480MHz
and it generates a VGA output at resolutions up to 800x600 pixels with up 65,536 colours.

The power of the ARM processor means it is capable of running BASIC at speeds comparable to running
native machine-code on an 8-bit home computer with the additional advantage of vastly more memory
and superior graphics and audio capabilities.

More information can be found on the official Colour Maximite 2 website at
http://geoffg.net/maximite.html

**2. How do I find out more about Interactive Fiction ?**

Visit https://intfiction.org/

**3. Where can I find out more about the ADVENTURE database format used by SAAINT ?**

SAAINT interprets adventures saved in the TRS-80 /
[ScottFree](http://www.ifwiki.org/index.php/ScottFree) / .dat file format which is documented in
detail [here](https://github.com/pdxiv/LuaScott/blob/master/doc/The_ADVENTURE_Data_Base_Format_(1980).md).

**4. How do I contact the author ?**

The author can be contacted via:
 - https://github.com as user "thwill1000"
 - https://www.thebackshed.com/forum/ViewForum.php?FID=16 as user "thwill"
