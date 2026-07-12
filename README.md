# Mazing.cmd - WinNT Maze Generator and Solver

           Mazing.cmd - WinNT Maze Generator and Solver
    __________________________________________________________
    A maze program written in native WinNT batch script that
    includes several maze generation and solving algorithms as
    well as a small plethora of options for console display,
    stack size, stack orientation, node selection/direction
    bias, entrance/exit points, color selection, wall/box
    characters, and real-time shifting and rhythmic pulsing
    random colors, each with an automatic randomizer, and all
    of it easily accessible through an animated custom menu.
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
    
                           Menu Options
    __________________________________________________________
    Maze Generators: BackTracker - random depth-first search
      Hunt & Kill  - like BackTracker, but with random stack
      Growing Tree - highly versatile list-based generator
      Wall Division - recursively divide rooms with walls
      Eller's Algorithm - elegant, and the fastest generator
      Prim's Algorithm  - hard ugly mazes with short dead ends
      Kruskal's Algorithm - creates even measured mazes, slow
      Wilson's Algorithm  - classic loop-erased random walk
    Maze Solvers: always find the 1 solution to perfect mazes
      Wall Follow - left or right hand on wall, depth-first
      Dead Filler - remove dead-ends until path is revealed
      Path Finder - flood maze until exit found, retrace path
    Entrance/Exit: where to place the maze entrance and exit
      Inside - entrance=any random point  exit=farthest point
      Border - entrance=point on border  exit=farthest border
      Corner - entrance=random corner    exit=farthest corner
    Width: # of vertical columns, limited by minCols/maxCols
    Height: # of horizontal rows, limited by minRows/maxRows
    Ancillary Setting: different for each maze generator
      Hunt & Kill  - type of stack, <0=FIFO, else LIFO
      Growing Tree - list size, 0=all+LIFO, <0=FIFO, >0=LIFO
      Division - wall open, 0=NW,1=SE,2=NW/SE,3=Mid,4+=Random
    Node Selection Bias: % chance of choosing random or stack
      Hunt & Kill   - 0=random from stack,100=next from stack
      Growing Tree  - 0=random from list, 100=next from list
      Wall Division - stack order, 0-7=pre-sets, 8+=random
    Node Direction Bias: % chance of choosing each direction
      0=most vertical, 50=even chance, 100=most horizontal
    Rebuild Box:      Rebuild Off - continue with current maze
        Random Box  - replace walls with 1 of 12 pre-set boxes
        Random Wall - replace wall character from random list
    
                           Menu Options
    __________________________________________________________
    Solver Display Settings: value to affect visual display
    Wall Character:  wall used for initial maze generation
    Crumb Character: trail used for initial maze generation
      These two may be altered by Rebuild if it's active
    Start Character:  used to indicate entrance to maze
    Finish Character: used to indicate exit from maze
      Never use the same characters for these four settings^!
    Background Color: console display, random=078F
    Foreground color: console display, random=1234569ABCDE
      Random      - select randomly from user color lists
      Very Random - select randomly from all 16 colors
      Colors are displayed immediately to aid in selection
    Background and Foreground Color Shift: allows changing
      console colors at timed intervals during operation
      using a self-regulating macro timed to shiftFrequency.
      Chooses colors from current color lists.
    Foreground B/W Pulse: rhythmic foreground flash is
      a multiple of shiftFrequency and presents a contrasting
      B/W foreground pulse at the given interval.
    Delay: amount of time to delay each iteration of the
      generation/solving loop, to better view the algorithm.
    Display Type: how to display maze in the console window
      No Display - only window title and logFile are active
      16 Color - change window size+color, show maze animation
      BG Color - full color + smooth animation requires BG.EXE
                 which is auto-generated if not found in PATH
    
     If using Windows 10+ enable 'properties/legacy console'
    
    
    project by CirothUngol                  v0.3 July 11, 2026
