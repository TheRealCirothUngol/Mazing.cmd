# Mazing.cmd

           Mazing.cmd - WinNT Maze Generator and Solver
    __________________________________________________________
    A maze program written in native WinNT batch script that
    includes several maze generation and solving algorithms as
    well as a small plethora of options for console display,
    stack size, stack orientation, node selection/direction
    bias, entrance/exit points, color selection, real-time
    shifting and rhythmic pulsing random colors, and wall/box
    characters, each with an automatic randomizer, and all of
    it easily accessible through an animated custom menu.
    Mazes are limited to a maximum practical string length of
    8186 characters. The maze dimensions will be automatically
    increased/decreased if minimum/maximum size is exceeded.
    
    Mazing operates using 100% WinNT batch script, but it will
    use either BG.EXE or CursorPos.exe to place the cursor at
    the upper-left if they are located in the system path. It
    can also use BG.EXE to animate the screen in full color.
    
                  Command Line / Mazing.ini File
    __________________________________________________________
    In addition to the menu, other User Variables are passed
    by using either the Mazing.ini file or on the command line
    by using the following syntax:
    Mazing.cmd ["variable=value"] [variable:value] [...]
    
    Several options for minimum/maximum columns/rows, lists
    of characters for random walls/crumbs/colors, keys used by
    the menu, output logfile and anything else not included in
    the menu are accessed by command line or the .ini file.
    A list of available user variables may be found in the
    Mazing.ini file that is auto-generated on first run.

    project by CirothUngol                  v0.2 June 21, 2026

    
