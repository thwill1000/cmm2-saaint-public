The Interpreter includes some meta-commands you can type to help with debugging/testing.

*debug {on | off}
   With debugging on:
       - room descriptions are prefixed with the room number.
       - object names are prefixed with the object number.
       - messages are prefixed with the message number.

*record {on | off}
   Typing *record prompts you for a filename for a "script" and then
   starts copying every subsequent command you type into that script.

*replay {on | off}
   Typing *replay allows you to replay a script created by "record".

*seed
   Seeds the random number generator with a fixed value. Useful to
   ensure that any supposedly "random" behaviour is actually consistent.

*state
   Prints the current game state:
       - the number of the current room
       - the value of the "dark flag"
       - the value of the "remaining light" counter
       - the indexes of the status bits that are currently set.

You can also copy the walkthrough from the internet direcly into a .scr file and *replay that, you need to prefix with a 2 line header consisting of:

# DD-MM-YYYY hh:mm:ss
# ScriptName

There is a "gotcha" if the adventure has any random behaviour. Including *seed at the start of the script fixes that random behaviour, but it's still possible that any given walkthrough you find might need tweaking to get past the random spots the first time.

If you need the script to stop at any given point then insert *replay off into it at that point.