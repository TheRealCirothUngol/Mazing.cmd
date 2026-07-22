:: 
::        Mazing.cmd - WinNT Maze Generator and Solver
:: __________________________________________________________
:: A maze program written in native WinNT batch script that
:: includes several maze generation and solving algorithms as
:: well as a small plethora of options for console display,
:: stack size, stack orientation, node selection/direction
:: bias, entrance/exit points, color selection, wall/box
:: characters, and real-time shifting and rhythmic pulsing
:: random colors, each with an automatic randomizer, and all
:: of it easily accessible through an animated custom menu.
:: Mazes are limited to a maximum practical string length of
:: 8186 characters. The maze dimensions will be automatically
:: increased/decreased if minimum/maximum size is exceeded.
:: 
:: Mazing operates using 100% WinNT batch script, but it will
:: use either BG.EXE or CursorPos.exe to place the cursor at
:: the upper-left if they are located in the system path. It
:: can also use BG.EXE to animate the screen in full color.
:: 
:: 
::               Command Line / Mazing.ini File
:: __________________________________________________________
:: In addition to the menu, other User Variables are passed
:: by using either the Mazing.ini file or on the command line
:: by using the following syntax:
:: Mazing.cmd ["variable=value"] [variable:value] [...]
:: 
:: Several options for minimum/maximum columns/rows, lists
:: of characters for random walls/crumbs/colors, keys used by
:: the menu, output logfile and anything else not included in
:: the menu are accessed by command line or the .ini file.
:: A list of available user variables may be found in the
:: Mazing.ini file that is auto-generated on first run.
::
::                        Menu Options
:: __________________________________________________________
:: Maze Generators: BackTracker - random depth-first search
::   Hunt & Kill  - like BackTracker, but with random stack
::   Growing Tree - highly versatile list-based generator
::   Wall Division - recursively divide rooms with walls
::   Eller's Algorithm - elegant, and the fastest generator
::   Prim's Algorithm  - hard ugly mazes with short dead ends
::   Kruskal's Algorithm - creates even measured mazes, slow
::   Wilson's Algorithm  - classic loop-erased random walk
:: Maze Solvers: always find the 1 solution to perfect mazes
::   Wall Follow - left or right hand on wall, depth-first
::   Dead Filler - remove dead-ends until path is revealed
::   Path Finder - flood maze until exit found, retrace path
:: Entrance/Exit: where to place the maze entrance and exit
::   Inside - entrance=any random point  exit=farthest point
::   Border - entrance=point on border  exit=farthest border
::   Corner - entrance=random corner    exit=farthest corner
:: Width: # of vertical columns, limited by minCols/maxCols
:: Height: # of horizontal rows, limited by minRows/maxRows
:: Ancillary Setting: different for each maze generator
::   Hunt & Kill  - type of stack, <0=FIFO, else LIFO
::   Growing Tree - list size, 0=all+LIFO, <0=FIFO, >0=LIFO
::   Division - wall open, 0=NW,1=SE,2=NW/SE,3=Mid,4+=Random
:: Node Selection Bias: % chance of choosing random or stack
::   Hunt & Kill   - 0=random from stack,100=next from stack
::   Growing Tree  - 0=random from list, 100=next from list
::   Wall Division - stack order, 0-7=pre-sets, 8+=random
:: Node Direction Bias: % chance of choosing each direction
::   0=most vertical, 50=even chance, 100=most horizontal
:: Rebuild Box:      Rebuild Off - continue with current maze
::     Random Box  - replace walls with 1 of 12 pre-set boxes
::     Random Wall - replace wall character from random list
::
::                        Menu Options
:: __________________________________________________________
:: Solver Display Settings: value to affect visual display
:: Wall Character:  wall used for initial maze generation
:: Crumb Character: trail used for initial maze generation
::   These two may be altered by Rebuild if it's active
:: Start Character:  used to indicate entrance to maze
:: Finish Character: used to indicate exit from maze
::   Never use the same characters for these four settings^!
:: Background Color: console display, random=078F
:: Foreground color: console display, random=1234569ABCDE
::   Random      - select randomly from user color lists
::   Very Random - select randomly from all 16 colors
::   Colors are displayed immediately to aid in selection
:: Background and Foreground Color Shift: allows changing
::   console colors at timed intervals during operation
::   using a self-regulating macro timed to shiftFrequency.
::   Chooses colors from current color lists.
:: Black & White Pulse: rhythmic alternating B/W flash is
::   timed as a multiple of the shiftFrequency setting and
::   presents a contrasting B/W pulse at the given interval.
:: Delay: amount of time to delay each iteration of the
::   generation/solving loop, to better view the algorithm.
:: Display Type: how to display maze in the console window
::   No Display - only window title and logFile are active
::   16 Color - change window size+color, show maze animation
::   BG Color - full color + smooth animation requires BG.EXE
::              which is auto-generated if not found in PATH
:: 
::  If using Windows 10+ enable 'properties/legacy console'
:: 
:: 
:: project by CirothUngol                  v0.3 July 21, 2026
::
:: Added Prim's, Kruskal's, and Wilson's Algorithms as generators.
:: Gave Wilson's lots of entry options, now it's one of the best!
:: Added menu option for solvers with lots of new display stuff.
:: Updated badColor filter. Fast. No more eye-searing colors.
:: Improved and unified the title bar layout. Lots of small
:: cosmetic changes throughout. Mazing now contains all of the
:: notable algorithms to produce perfect mazes as well as the only
:: three suitable solvers I know of. v0.3 is it, I think I'm done?
:: If there's ever a v0.4 it'll be for ANSI console integration.
:: 
::                                         v0.2 June 21, 2026
:: There were a host of display issues using the new Win10 terminal.
:: Nearly all of them were fixed by enabling 'legacy console'.
:: Fixed the Win10 poison characters by removing from character lists.
:: :mazing_grabKey doesn't seem to work in WinXP, so I've added a macro
:: to support using BG.EXE to grab quitKey, useGrabKey=Y to disable it.
:: Updated extraction for BG.EXE, now extracts + auto-restarts. It's also
:: available on github if you are unable/unwilling to auto-extract it.
:: https://github.com/carlos-montiers/consolesoft-mirror/releases
:: Split Maze.log for option of separate files for Mazes & Solutions.
:: Added additional characters and display options to menu.
:: Added colorShift macro + menu support to shift color at even intervals.
:: Added Mazing.ini to identify user variables and give easier access.
:: Turned Mazing.cfg into a batch file, it runs at end of :mazing_init
:: Too many changes to actually count. It's a tinker toy, after all.
::
:: originally completed               v0.1 September 27, 2018
::

@ECHO OFF
IF "%~1"=="grabKey" GOTO :mazing_grabKey

REM initialize script, start main loop
SETLOCAL EnableExtensions EnableDelayedExpansion
CALL :mazing_init %*
CALL :mazing_loop
ENDLOCAL
EXIT /B 0

:mazing_wait centiseconds
REM high CPU load, only suitable for very short delays
FOR /F "tokens=1-4 delims=:." %%W IN ("%TIME: =0%") DO SET/A "waitTime=(((1%%W*60)+1%%X)*60+1%%Y)*100+1%%Z-36610100"
IF NOT DEFINED waitStart SET/A waitStart=waitEnd=waitTime,waitEnd+=%~1-1
IF %waitTime% LSS %waitStart% SET /A waitTime+=8640000
IF %waitTime% LSS %waitEnd% GOTO :mazing_wait
SET waitStart=
EXIT /B 0

:mazing_grabKey "" quitKey keyFile
ECHO(^%key% >%3
SET "key="
FOR /F "skip=1 delims=" %%# IN ('replace ? . /u /w') DO IF NOT DEFINED key SET "key=%%#"
IF NOT EXIST %3 EXIT /B 0
IF /I "%key%" NEQ "%~2" GOTO :mazing_grabKey
DEL /F /Q /A %3 >NUL 2>&1
EXIT /B 0

:mazing_menu
REM replace random box characters and set color for 1st run
IF DEFINED fstClr SET/A bgClr=0,fgClr=!RANDOM!%%7+1
SET /A bx=!RANDOM!%%8,mPos=orgPos+mWide*mCh,pages=3,lastOp=mCnt=1
SET "mMsg5=!mMsg5[%mzOp0%]!"
SET "tMenu=!mzMenu!"
FOR /L %%y IN (0,1,5) DO FOR %%z IN ("!mBox_:~%%y,1!=!mBox%bx%:~%%y,1!") DO SET "tMenu=!tMenu:%%~z!"
FOR /L %%y IN (0,1,%opCnt%) DO FOR %%z IN (":%%y:=!mView%%y!") DO SET "tMenu=!tMenu:%%~z!"
REM replace menu keys, insert maze characters and other text
FOR %%# IN (":A:=%menuKeys:~0,2%" ":B:=%menuKeys:~2,2%" ":C:=%menuKeys:~4,3%" ":D:=%menuKeys:~7,1%") DO SET "tMenu=!tMenu:%%~#!"
SET "tMenu=!tMenu:~0,966!!wall!!tMenu:~967!"
SET "tMenu=!tMenu:~0,1026!!crumb!!tMenu:~1027!"
SET "tMenu=!tMenu:~0,1086!!player!!tMenu:~1087!"
SET "tMenu=!tMenu:~0,1146!!goal!!tMenu:~1147!"
SET "tMenu=!tMenu:~0,%mzOp5P1%!!mzOp5[%mzOp0%]!!tMenu:~%mzOp5P2%!"
SET "tMenu=!tMenu:~0,%mzOp6P1%!!mzOp6[%mzOp0%]!!tMenu:~%mzOp6P2%!"
SET "tMenu=!tMenu:~0,%mzOp9P1%!!mzOp9[%mzOp1%]!!tMenu:~%mzOp9P2%!"
IF !mzOp8! GEQ 1 IF !mzOp8! LEQ !numOfBoxes! SET "tMenu=!tMenu:~0,%mzOp8P1%!!box%mzOp8%!!tMenu:~%mzOp8P2%!"
SET "tMenu=!tMenu:~0,%msgP1%!!mMsg%mCh%!!tMenu:~%msgP2%!"
REM copy color settings, change mode, start menu
SET mbClr=!bgClr!& SET mfClr=!fgClr!
IF DEFINED firstRun (SET mbClr=0) & SET mfClr=F
IF DEFINED skipMenu (SET skipMenu=) & (SET mOp=5) & GOTO :mazing_menu_exit
MODE CON COLS=%mWide% LINES=%mHigh%

:mazing_menu_display
TITLE Maze#!mazeCnt! ^| !title0! %TIME: =0%
SET /A mrkPos=mPos-3
COLOR !mbClr!!mfClr!
!clear!
ECHO(
ECHO(!tMenu:~0,%mrkPos%!!mrk!!tMenu:~%mPos%!

:mazing_menu_loop
SET "mKey=" & SET /A mOp=-1,mt0=mt3=0,mt1=mWide-1
IF DEFINED firstRun (SET firstRun=) & (SET mOp=7) & GOTO :mazing_menu_exit
FOR /F "skip=1 delims=" %%# IN ('replace ? . /u /w') DO IF NOT DEFINED mKey SET "mKey=%%#"
REM mOp is 0=up, 1=down, 2=left, 3=right, 4=continue&resume, 5=quit&restart, 6=abort&exit, 7=display help
FOR /L %%A IN (0,1,7) DO IF /I "!mKey!"=="!menuKeys:~%%A,1!" SET mOp=%%A
IF !mOp! LSS 0 GOTO :mazing_menu_loop
IF !mOp! GEQ 4 GOTO :mazing_menu_exit
IF !mOp! EQU 0 SET /A mCh-=1 & IF !mCh! LSS 0 SET mCh=!opCnt!
IF !mOp! EQU 1 SET /A mCh+=1 & IF !mCh! GTR !opCnt! SET mCh=0
IF !mOp! LEQ 1 ( SET /A mPos=orgPos+mWide*mCh
	SET "tMenu=!tMenu:~0,%msgP1%!!mMsg%mCh%!!tMenu:~%msgP2%!"
	GOTO :mazing_menu_display)
IF !mOp! EQU 2 SET /A mzOp%mCh%-=1 & IF !mzOp%mCh%! LSS -1 SET /A mzOp%mCh%=maxOp%mCh%
IF !mOp! EQU 3 SET /A mzOp%mCh%+=1 & IF !mzOp%mCh%! GTR !maxOp%mCh%! SET mzOp%mCh%=-1

:mazing_menu_cfg
SET /A mt0=mt1=mzOp%mCh%,mt2=mPos+opSize
IF !mt0! LSS 0  SET mt1=Random
IF !mCh! EQU 0 ( REM Maze Generation Algorithm
				SET "tMenu=!tMenu:~0,%mzOp5P1%!!mzOp5[%mt0%]!!tMenu:~%mzOp5P2%!"
				SET "tMenu=!tMenu:~0,%mzOp6P1%!!mzOp6[%mt0%]!!tMenu:~%mzOp6P2%!"
				SET "mMsg5=!mMsg5[%mt0%]!"
				SET "mMsg6=!mMsg6[%mt0%]!"
				SET "mt1=!mzOp0[%mt0%]!")
IF !mCh! EQU 1 ( REM Maze Solving Algorithm
				SET "tMenu=!tMenu:~0,%mzOp9P1%!!mzOp9[%mt0%]!!tMenu:~%mzOp9P2%!"
				SET "mMsg9=!mMsg9[%mt0%]!"
				SET "mt1=!mzOp1[%mt0%]!")
IF !mCh! EQU 2  SET "mt1=!mzOp2[%mt0%]!" 'Select Entrance/Exit Point
IF !mCh! EQU 3  IF !mt0! EQU 0 ( REM Width in Vertical Columns
					SET /A mt1=mzOp3=minCols
				) ELSE IF !mt0! LSS !minCols! SET /A mt1=mzOp3=-1 & SET mt1=Random
IF !mCh! EQU 4  IF !mt0! EQU 0 ( REM Height in Horizontal Rows
					SET /A mt1=mzOp4=minRows
				) ELSE IF !mt0! LSS !minRows! SET /A mt1=mzOp4=-1 & SET mt1=Random
IF !mCh! EQU 5  ( REM Stack Size/Type/Wall Setting
				IF !mt0! GEQ 0 SET /A mt1=mt0-12)
IF !mCh! EQU 6  ( REM Node Selection %Bias
				IF !mt0! EQU 101 SET mt1=Newest/Oldest)
IF !mCh! EQU 8 ( REM Rebuild Box
				SET "tMenu=!tMenu:~0,%mzOp8P1%!               !tMenu:~%mzOp8P2%!"
				IF !mzOp8! EQU 0 (SET mt1=Rebuild Off
				) ELSE IF !mzOp8! EQU %nobRB% (SET mt1=Random Box
				) ELSE IF !mzOp8! EQU %nobRW% (SET mt1=Random Wall
				) ELSE IF !mzOp8! GTR 0  (SET mt1=Box#!mt0!
					SET "tMenu=!tMenu:~0,%mzOp8P1%!!box%mzOp8%!!tMenu:~%mzOp8P2%!"))
IF !mCh! EQU 9  ( REM Solver Display Settings
				IF !mt0! GEQ 0 SET /A mt1=mt0-30)
IF !mCh! GEQ 10 IF !mCh! LEQ 13 IF !mt0! GEQ 0 SET mt1=!chars:~%mt0%,1!
IF !mCh! EQU 14 ( REM Background Color
				SET bColors=!backColors!& SET bColorCnt=!backColorCnt!
				IF !mt0! LSS 0 (SET mbClr=!bgClr!
				) ELSE IF !mt0! LEQ 15 (SET mt1=!hex:~%mt0%,1!& SET mbClr=!mt1!
				) ELSE SET mbClr=!bgClr!& SET mt1=Very Random& SET bColors=!hex!& SET bColorCnt=16)
IF !mCh! EQU 15 ( REM Foreground Color
				SET fColors=!foreColors!& SET fColorCnt=!foreColorCnt!
				IF !mt0! LSS 0 (SET mfClr=!fgClr!
				) ELSE IF !mt0! LEQ 15 (SET mt1=!hex:~%mt0%,1!& SET mfClr=!mt1!
				) ELSE SET mfClr=!fgClr!& SET mt1=Very Random& SET fColors=!hex!& SET fColorCnt=16)
IF !mCh! GEQ 16 IF !mCh! LEQ 17 ( REM Color Shift
				IF !mCh! EQU !lastCh! (IF !mOp! EQU !lastOp! (SET/A mCnt+=1) ELSE SET mCnt=1) ELSE SET mCnt=1
				IF !mCnt! GEQ 20 IF !mOp! EQU 2 (SET/A mt0-=9)  ELSE SET/A mt0+=9
				IF !mCnt! GEQ 40 IF !mOp! EQU 2 (SET/A mt0-=20) ELSE SET/A mt0+=20
				IF !mt0! LSS -1 SET/A mt0=!maxOp%mCh%!,mCnt=1
				IF !mt0! GTR !maxOp%mCh%! SET/A mt0=-1,mCnt=1
				IF !mt0! LSS 0 SET "mt1=Random" & SET/A "csBtm=!RANDOM!%%1200+301,csFtm=!RANDOM!%%1200+301"
				IF !mt0! EQU 0 SET mt1=Shift Off
				IF !mt0! GTR 0 SET mt1=0.0!mt0! sec
				IF !mt0! GTR 9 SET mt1=0.!mt0! sec
				IF !mt0! GTR 99 SET mt1=!mt0:~0,-2!.!mt0:~-2! sec
				IF !mCh! EQU 16 (SET/A mzOp16=mt0) ELSE SET/A mzOp17=mt0)
IF !mCh! EQU 18 ( REM Foreground Pulse
				IF !mt0! LSS 0 SET pulse=!RANDOM!%%20+6
				IF !mt0! EQU 0 SET "mt1=Pulse Off"
				IF !mt0! GEQ 0 SET/A mt3=mt0*shiftFrequency
				IF !mt3! GTR 0 SET mt1=0.0!mt3! sec
				IF !mt3! GTR 9 SET mt1=0.!mt3! sec
				IF !mt3! GTR 99 SET mt1=!mt3:~0,-2!.!mt3:~-2! sec)
IF !mCh! EQU 19 ( REM Program Delay
				IF !mt0! LSS 0 SET /A mt0=mzOp19=maxOp19-1
				IF !mt0! EQU !maxOp19! SET /A mt0=mzOp19=0
				IF !mt0! EQU 0 SET mt1=Delay Off
				IF !mt0! GTR 0 SET mt1=0.0!mt0! sec
				IF !mt0! GTR 9 SET mt1=0.!mt0! sec
				IF !mt0! GTR 99 SET mt1=!mt0:~0,-2!.!mt0:~-2! sec)
IF !mCh! EQU 20 ( REM Console Display Type
				SET mt1=Display Off
				IF !mzOp20! LSS 0 SET mt1=16 Color
				IF !mzOp20! GTR 0 SET mt1=BG Color)
SET lastCh=!mCh!
SET lastOp=!mOp!
SET "mt1=!mt1!             "
SET "mView!mCh!=!mt1:~0,%opSize%!"
IF "%~1" EQU "init" EXIT /B 0
SET "tMenu=!tMenu:~0,%mPos%!!mView%mCh%!!tMenu:~%mt2%!"

GOTO :mazing_menu_display

:mazing_menu_exit
REM 4=continue&resume, 5=quit&restart, 6=abort&exit, 7=display help
IF !mOp! EQU 7 FOR /F "usebackq tokens=* delims=:" %%# IN ("%~f0") DO (
	IF "%%#"=="" (SET/A mt0+=1
		TITLE %~n0 Help ^| page# !mt0! of !pages! !TIME: =0!
		ECHO(
		%POZ% page !mt0! of !pages!, press any key to continue...
		ECHO(
		ECHO(
		IF !mt0! EQU !pages! (SET/A mh1=mSize-mWide*2-1
			FOR /L %%: IN (0,!mWide!,!mh1!) DO (ECHO(!tMenu:~%%:,%mt1%!
				CALL :mazing_wait 3)
			GOTO :mazing_menu_display)
	) ELSE (ECHO(%%#
		CALL :mazing_wait 3)
)
%mazingDebug% SET>%~f0.debug.menu.txt
SET "tMenu="

REM save menu configuration and check for exit
>"!cfgFile!" ECHO REM %~nx0 v%version% runs as batch file at end of :mazing_init
FOR /L %%A IN (0,1,%opCnt%) DO >>"!cfgFile!" ECHO SET mzOp%%A=!mzOp%%A!
>>"!cfgFile!" ECHO SET/A saveCh=!mCh!,hkMax=!hkMax!,gtMax=!gtMax!,kaMax=!kaMax!,w1Max=!w1Max!,w2Max=!w2Max!

REM check for new settings
SET "BGstart=" & SET "FGstart=" & SET /A csCnt=pCnt=0
SET bgClr=!mbClr!& SET fgClr=!mfClr!& SET fstClr=
IF !mzOp1!  GEQ 0 SET "svSelect=!mzOp1!"
IF !mzOp8!  GEQ 0 SET "rebuild=!mzOp8!"
IF !mzOp9!  GEQ 0 SET /A "solve=mzOp9-30"
IF !mzOp14! GEQ 0 IF !mzOp14! LEQ 15 SET "bgClr=!hex:~%mzOp14%,1!"
IF !mzOp15! GEQ 0 IF !mzOp15! LEQ 15 SET "fgClr=!hex:~%mzOp15%,1!"
IF !mzOp16! GEQ 0 SET "csBtm=!mzOp16!"
IF !mzOp17! GEQ 0 SET "csFtm=!mzOp17!"
IF !mzOp18! GEQ 0 SET "pulse=!mzOp18!"
IF !mzOp19! GEQ 0 SET "delay=!mzOp19!"
                  SET "display=!mzOp20!"

REM if colorShift is unnecessary disable it by setting the target too high
IF !csBtm!!csFtm!!pulse! EQU 0 (SET "csTrg=2147483647"& SET "titleCS=") ELSE (SET "csTrg=0"& SET "titleCS=cs:^!csTrg^!")
IF !display! EQU 0 (SET "csTrg=2147483647"& SET "titleCS=")

REM generate BG.EXE if needed
IF !display! GTR 0 ( BG.EXE >NUL 2>&1
	IF !ERRORLEVEL!==9009 ( REM if executable is not found
		CALL :makeBG
		IF !ERRORLEVEL!==1 (ECHO.& %POZ%Cannot Generate BG.EXE, press any key for Menu...
			GOTO :mazing_menu_display)
		IF !mOp! NEQ 6 SET /A BG_restart=mOp=6
	)
)
IF !mOp! EQU 6 EXIT /B 3%=   'check for script abort =%

REM start KeyGrabber, check for exit
REM.>"%keyFile%"
IF NOT DEFINED bgKey (
	START "" /B CMD /C ^""%~f0" grabKey "!quitKey!" "!keyFile!" 2^>NUL ^>NUL^" )
IF !mOp! EQU 5 EXIT /B 2
IF !display! EQU 0 EXIT /B 0
:: IF NOT DEFINED wide EXIT /B 0

REM reset console and display current maze
MODE CON COLS=%wide% LINES=%modeHigh%
ECHO(!mz!
IF "!title0:~0,5!" NEQ "Eller" %EKO%!msg:~1!
IF !display! GTR 0 CALL :mazing_BGcolor

EXIT /B 0

:mazing_BGcolor
REM use BG.EXE to set unique colors for entrance, exit, labelTop, labelBtm, and message.
SET /A "xr1=bgnPos/wide, xc1=bgnPos-xr1*wide, xr2=endPos/wide, xc2=endPos-xr2*wide, xr3=rows*2, xr4=high+1"
SET /A "exClr=!RANDOM!%%(colorCnt-2), pClr=!RANDOM!%%(colorCnt-3), gClr=!RANDOM!%%(colorCnt-4), ex2Clr=!RANDOM!%%(colorCnt-5)"
SET "tClr=!hex:%bgClr%=!"
SET "tClr=!tClr:%fgClr%=!"
SET "exClr=!tClr:~%exClr%,1!"
SET "tClr=!tClr:%exClr%=!"
SET "pClr=!tClr:~%pClr%,1!"
SET "tClr=!tClr:%pClr%=!"
SET "gClr=!tClr:~%gClr%,1!"
SET "tClr=!tClr:%gClr%=!"
SET "ex2Clr=!tClr:~%ex2Clr%,1!"
IF !bgClr! LSS 7 SET "lbClr=F"
IF !fgClr! EQU 0 IF !bgClr! NEQ F SET "lbClr=F"
BG.EXE FCPrint !xr1! !xc1! !bgClr!!pClr! "!player!"
BG.EXE FCPrint 0 2 !bgClr!!lbClr! "!labelTop!"
BG.EXE FCPrint !xr4! 0 !bgClr!!lbClr! "!msg:~1!"
IF NOT DEFINED labelBtm EXIT /B 0
BG.EXE FCPrint !xr2! !xc2! !bgClr!!gClr! "!goal!"
BG.EXE FCPrint !xr3! 2 !bgClr!!lbClr! "!labelBtm!"
IF NOT DEFINED dfMode EXIT /B 0
IF !dfMode! LSS 0 ( SET "dfClr=!bgClr!!exClr!"
) ELSE SET "dfClr=!exClr!!exClr!"

EXIT /B 0

REM randomize all choices and possible settings, create, rebuild, solve, repeat
:mazing_loop
SETLOCAL
SET "startTime=%TIME% %DATE%"

REM choose random valid colors
SET /A "p1=!RANDOM!%%bColorCnt,p2=!RANDOM!%%fColorCnt,csBtm=!RANDOM!%%600+201,csFtm=!RANDOM!%%600+201,yn=!RANDOM!%%2,ynm=!RANDOM!%%3,pulse=!RANDOM!%%20+6,mazeCnt+=1"
SET "bgClr=!bColors:~%p1%,1!"
SET "fgClr=!fColors:~%p2%,1!"
IF "!badColors!" NEQ "!badColors:%bgClr%%fgClr%=!" (IF !fgClr! EQU 0 (SET bgClr=5) ELSE SET bgClr=0)
IF !ynm! EQU 0 SET/A pulse*=yn

REM select random maze characters
SET /A "p1=!RANDOM!%%wallCnt, p2=!RANDOM!%%hallCnt, p3=!RANDOM!%%crumbCnt, p4=!RANDOM!%%playerCnt, p5=!RANDOM!%%goalCnt"
SET "wall=!walls:~%p1%,1!"
SET "hall=!halls:~%p2%,1!"
SET "crumb=!crumbs:~%p3%,1!"
SET "player=!players:~%p4%,1!"
SET "goal=!goals:~%p5%,1!"
SET "xWall=!wall!"
IF "!xWall!"=="ÿ" SET "xWall=!xWalls:~%ynm%,1!"

REM random maze creation settings
REM mzSelect=0-7, rsBias=random/stack=0-199, hvBias=horz/vert=0-149, endPos=0=farthest point,1=far point on border,2+=far corner
SET /A "cols=!RANDOM!%%(maxCols-minCols+1)+minCols, rows=!RANDOM!%%(maxRows-minRows+1)+minRows"
SET /A "mzSelect=!RANDOM!%%14,svSelect=!RANDOM!%%10+1,rsBias=!RANDOM!%%200,hvBias=!RANDOM!%%300"
SET /A "hk1=!RANDOM!%%6-3,gt1=wa1=!RANDOM!%%36-12,wd1=!RANDOM!%%16,wd2=!RANDOM!%%16"
SET /A "rebuild=!RANDOM!%%(numOfBoxes+3)-2,solve=!RANDOM!%%61-30"
IF !hvBias! GEQ 250 ( SET /A hvBias-=225%=        '1 in 6  set hvBias=25 to 75 mid-range =%
) ELSE IF !hvBias! GEQ 200 ( SET /A hvBias-=175%= '1 in 6  set hvBias=25 to 75 mid-range =%
) ELSE IF !hvBias! GEQ 150 ( SET /A hvBias-=125%= '1 in 6  set hvBias=25 to 75 mid-range =%
) ELSE IF !hvBias! GEQ 100 SET /A hvBias-=75%=    '1 in 6  set hvBias=25 to 75 mid-range =%
IF !rsBias! GEQ 175 ( SET /A rsBias=101%=         '1 in 8  set stack to alternate top/bottom =%
) ELSE IF !rsBias! GEQ 150 ( SET /A rsBias=0%=    '1 in 8  set stack always random =%
) ELSE IF !rsBias! GEQ 100 SET /A rsBias-=75%=    '1 in 4  set rsBias=25 to 75 mid-range =%
IF !gt1! GTR 12 SET "gt1=0"%=                     '1 in 3  set to list=all =%
IF !gt1! LSS -6 SET "gt1*=-1"%=                   '1 in 2  set greater half of FIFO=LIFO =%
IF !wd2! EQU  0 SET "solve=0"%=                   '1 in 16 set solvers to neutral (PathFinder=Flood)
IF !gt1:~-1! EQU 1 SET /A gt1+=1%=                'assure gtList NEQ 1 =%
REM if Wall Division, push 50% high-ends towards the middle
REM then set 20% high-ends = 50 for more even maze displays
SET /A wdBias=hvBias,wa2=rsBias
IF !wdBias! LEQ 25 (SET/A wdBias+=25) ELSE IF !wdBias! GEQ 75 SET/A wdBias-=25
IF !wdBias! LEQ 35 (SET/A wdBias=50 ) ELSE IF !wdBias! GEQ 65 SET/A wdBias=50

REM check for user/menu settings
IF NOT EXIST "%keyFile%" CALL :mazing_menu
IF ERRORLEVEL 3 GOTO :mazing_stop
IF !mzOp0!  GEQ 0 SET "mzSelect=!mzOp0!"
IF !mzSelect! EQU 7 (IF !hvBias! LEQ 25 (SET/A hvBias+=25) ELSE IF !hvBias! GEQ 75 SET/A hvBias-=25)
IF !mzOp1!  GEQ 0 SET "svSelect=!mzOp1!"
IF !mzOp3!  GEQ 0 SET "cols=!mzOp3!"
IF !mzOp4!  GEQ 0 SET "rows=!mzOp4!"
IF !mzOp5!  GEQ 0 SET /A "hk1=gt1=wd1=wa1=mzOp5-12"
IF !mzOp6!  GEQ 0 SET /A "rsBias=wd2=wa2=!mzOp6!"
IF !mzOp7!  GEQ 0 SET /A "hvBias=wdBias=!mzOp7!"
IF !mzOp8!  GEQ 0 SET "rebuild=!mzOp8!"
IF !mzOp9!  GEQ 0 SET /A "solve=mzOp9-30"
IF !mzOp10! GEQ 0 SET "wall=!chars:~%mzOp10%,1!"
IF !mzOp11! GEQ 0 SET "crumb=!chars:~%mzOp11%,1!"
IF !mzOp12! GEQ 0 SET "player=!chars:~%mzOp12%,1!"
IF !mzOp13! GEQ 0 SET "goal=!chars:~%mzOp13%,1!"
IF !mzOp14! GEQ 0 IF !mzOp14! LEQ 15 SET "bgClr=!hex:~%mzOp14%,1!"
IF !mzOp15! GEQ 0 IF !mzOp15! LEQ 15 SET "fgClr=!hex:~%mzOp15%,1!"
IF !mzOp16! GEQ 0 SET "csBtm=!mzOp16!"
IF !mzOp17! GEQ 0 SET "csFtm=!mzOp17!"
IF !mzOp18! GEQ 0 SET "pulse=!mzOp18!"
IF !mzOp19! GEQ 0 SET "delay=!mzOp19!"
SET /A display=mzOp20,mt0=-2
IF !wd1! LSS 0 SET /A wd1*=-1
REM mzOp2 set Start and End positions
FOR %%A IN (!RANDOM! 0 1 2) DO FOR %%B IN (!RANDOM! 0 1 2) DO ( SET /A mt0+=1
	IF !mt0! EQU !mzOp2! SET /A "bgnPos=%%B%%3,endPos=%%A%%3")

REM if colorShift is unnecessary disable it by setting the target too high
IF !csBtm!!csFtm!!pulse! EQU 0 (SET csTrg=2147483647& SET "titleCS=") ELSE (SET csTrg=0& SET "titleCS=cs:^!csTrg^!")
IF !display! EQU 0 (SET "csTrg=2147483647"& SET "titleCS=")

REM check for valid maze size
SET /A "size=(cols*2+1)*(rows*2+1)"
IF !size! LSS !minSize! FOR /L %%A IN (1,1,64) DO (
	IF !size! LSS !minSize! SET /A "cols+=1,size=(cols*2+1)*(rows*2+1)"
	IF !size! LSS !minSize! SET /A "rows+=1,size=(cols*2+1)*(rows*2+1)")
IF !size! GTR !maxSize! FOR /L %%A IN (1,1,64) DO (
	IF !size! GTR !maxSize! SET /A "rows-=1,size=(cols*2+1)*(rows*2+1)"
	IF !size! GTR !maxSize! SET /A "cols-=1,size=(cols*2+1)*(rows*2+1)")
SET /A wide=cols*2+1,high=rows*2+1,size=wide*high,modeHigh=high+2

REM random maze entrance
CALL :mazing_bgnPos %bgnPos%

REM resize console, set COLOR
IF !display! NEQ 0 (
	MODE CON COLS=%wide% LINES=%modeHigh%
	COLOR !bgClr!!fgClr!)

REM maze selection bias 0-13: 0x1,1x3,2x3,3x1,4x2,5x1,6x1,7x2
       IF !mzSelect! GEQ 12 (SET mzSelect=1
) ELSE IF !mzSelect! GEQ 10 (SET mzSelect=2
) ELSE IF !mzSelect! GEQ 9 (SET mzSelect=4
) ELSE IF !mzSelect! GEQ 8 SET mzSelect=7
REM solve selection bias 1-10: 1x3,2x2,3x5
       IF !svSelect! GEQ 9 (SET svSelect=1
) ELSE IF !svSelect! GEQ 8 (SET svSelect=2
) ELSE IF !svSelect! GEQ 4 SET svSelect=3

REM create maze
IF !mzSelect! LEQ 0 (%=   Depth-First BackTracker   =%
IF       !yn! EQU 0 CALL :mazing_hunt_kill 1 100 !hvBias!
IF       !yn! EQU 1 CALL :mazing_growing_tree 1 100 !hvBias! )
IF !mzSelect! EQU 1 CALL :mazing_hunt_kill !hk1! !rsBias! !hvBias!
IF !mzSelect! EQU 2 CALL :mazing_growing_tree !gt1! !rsBias! !hvBias!
IF !mzSelect! EQU 3 CALL :mazing_wall_division !wd1! !wd2! !wdBias!
IF !mzSelect! EQU 4 CALL :mazing_ellers !hvBias!
IF !mzSelect! EQU 5 CALL :mazing_growing_tree 0 0 !hvBias! %=  Prim's Algorithm  =%
IF !mzSelect! EQU 6 CALL :mazing_kruskals !hvBias!
IF !mzSelect! GEQ 7 CALL :mazing_wilsons !wa1! !wa2! !hvBias!
IF ERRORLEVEL 3 GOTO :mazing_stop
IF ERRORLEVEL 2 GOTO :mazing_restart

IF !display! GTR 0 ( BG.EXE Locate 1 0
	ECHO(!mz:~%wide%!
)
IF !display! LSS 0 ( !clear!
	ECHO(!mz!
	%EKO%!msg:~1!)

REM find goal/exit position
CALL :mazing_endPos %endPos%
IF ERRORLEVEL 3 GOTO :mazing_stop
IF ERRORLEVEL 2 GOTO :mazing_restart

REM rebuild maze with box characters
IF !rebuild! EQU !nobRB! SET /A "rebuild=!RANDOM!%%numOfBoxes+1"
IF !rebuild! EQU !nobRW! SET "rebuild=-1"
IF !rebuild! NEQ 0 CALL :mazing_rebuild !rebuild!
IF ERRORLEVEL 3 GOTO :mazing_stop
IF ERRORLEVEL 2 GOTO :mazing_restart
IF !display! NEQ 0 ( !clear!
	ECHO(!mz!
	%EKO%!msg:~1!)

CALL :timeSince %startTime%

REM write maze and info to logfile
IF DEFINED mazeFile (
	SET "bz=!mz:ÿ=%xWall%!"
	FOR /L %%A IN (0,!wide!,!size!) DO IF %%A LSS !size! ECHO(!bz:~%%A,%wide%!>>"!mazeFile!"
	ECHO(!mm!>>"!mazeFile!"
	ECHO(created in !TS_! at !TIME: =0! on !DATE!>>"!mazeFile!"
	SET bz=)
SET /A totalCnt=mazeCnt,loopCnt+=1

REM solve maze
IF !svSelect! GTR 0 ( SET "startTime=%TIME% %DATE%"
	IF !svSelect! EQU 1 CALL :mazing_wall_follow !solve!
	IF !svSelect! EQU 2 CALL :mazing_dead_filler !solve!
	IF !svSelect! GEQ 3 CALL :mazing_path_finder !solve!
	IF ERRORLEVEL 3 GOTO :mazing_stop
	IF ERRORLEVEL 2 GOTO :mazing_restart
	IF !display! NEQ 0 ( !clear!
		ECHO(!mz!
		%EKO%!msg:~1!)
	CALL :timeSince !startTime!
	REM write solution and info to logfile
	IF DEFINED solvFile (
		SET "mz=!mz:ÿ=%xWall%!"
		ECHO(>>"!solvFile!"
		FOR /L %%A IN (0,!wide!,!size!) DO IF %%A LSS !size! ECHO(!mz:~%%A,%wide%!>>"!solvFile!"
		ECHO(!mm!>>"!solvFile!"
		ECHO(solved in !TS_! at !TIME: =0! on !DATE!>>"!solvFile!"
	)
)

CALL :timeSince !totalTime!
	   IF !mazeCnt:~-2! EQU 11 ( SET "mm=!mazeCnt!th"
) ELSE IF !mazeCnt:~-2! EQU 12 ( SET "mm=!mazeCnt!th"
) ELSE IF !mazeCnt:~-2! EQU 13 ( SET "mm=!mazeCnt!th"
) ELSE IF !mazeCnt:~-1! EQU 1  ( SET "mm=!mazeCnt!st"
) ELSE IF !mazeCnt:~-1! EQU 2  ( SET "mm=!mazeCnt!nd"
) ELSE IF !mazeCnt:~-1! EQU 3  ( SET "mm=!mazeCnt!rd"
) ELSE SET "mm=!mazeCnt!th"
SET "mm= %mm% maze in !TS_!"
SET "mm=!mm:~0,%wide%!
IF DEFINED mazeFile ( ECHO(!mm:~1!>>"!mazeFile!"
	ECHO(>>"!mazeFile!")

REM flashy exit
IF !display! NEQ 0 IF !flashTime! NEQ 0 ( !clear!
	COLOR 47
	ECHO(!mz!
	%EKO%!mm:~1!
	SET gkTrg=0
	FOR %%A IN (4 5 1 0) DO FOR %%B IN (%%A7 %%AF %%A7 %%A8) DO (
		COLOR %%B
		%BGgrabKey%
		CALL :mazing_wait !flashTime!
		IF NOT EXIST "%keyFile%" GOTO :mazing_restart))

REM assemble return variable list, ENDLOCAL to clear all variables, restart loop
:mazing_restart
SET return=mCh=!mCh!" "mazeCnt=!mazeCnt!" "totalCnt=!totalCnt!" "loopCnt=!loopCnt!" "csBtm=!csBtm!" "csFtm=!csFtm!" "pulse=!pulse!" "fColors=!fColors!" "fColorCnt=!fColorCnt!" "bColors=!bColors!" "bColorCnt=!bColorCnt!" "hkMax=!hkMax!" "gtMax=!gtMax!" "kaMax=!kaMax!" "w1Max=!w1Max!" "w2Max=!w2Max!" "firstRun=" "skipMenu=" "fstClr=
FOR /L %%A IN (0,1,%opCnt%) DO SET return=!return!" "mzOp%%A=!mzOp%%A!" "mView%%A=!mView%%A!
%mazingDebug% SET>%~f0.debug.menu.txt
ENDLOCAL & FOR %%A IN ("%return%") DO SET %%A
IF !loopCnt! LSS !maxLoop! GOTO :mazing_loop
ECHO.
ECHO Max Loops = !maxLoop!, exiting...
IF DEFINED mazeFile ECHO Max Loops = !maxLoop!, exiting...>>"!mazeFile!"

:mazing_stop
CALL :timeSince %totalTime%
IF !loopCnt! GTR 0 IF DEFINED mazeFile ECHO(!totalCnt! total mazes, !loopCnt! this session in !TS_! >>"!mazeFile!"
IF !loopCnt! GTR 0 IF DEFINED mazeFile ECHO(_______________________________________________________________________________>>"!mazeFile!"
TITLE Maze#!mazeCnt! ^| %~n0: !loopCnt! mazes in !TS_!
IF DEFINED BG_restart START CMD /C "%~f0" skipMenu:Y %*
%mazingDebug% SET>%~f0.debug.stop.txt
ENDLOCAL
EXIT /B 0

:mazing_hunt_kill stackType rsBias hvBias
REM %1=stack direction. <0=FIFO, else=LIFO
REM %2=next node bias. 0=always random, 100=always stack, >100=oldest/newest
REM %3=directional bias. 1=most vertical, 99=most horizontal
REM If %1<>0 and %2=100 then algorithm is Depth-First BackTracker.
REM If %2>100 then stack will alternate between oldest and newest entries.

SET /A "ud=%~1%%5, curPos=bgnPos, nodes=cols*rows, lbClr=cnt=c1=0, nCnt=trail=far=1, d1=100-%~2, vBias=100-%~3, hBias=%~3, t1=curPos+1, cTmp=wide-4, exClr=!RANDOM!%%(colorCnt-2)"
IF %~3 GTR 99 SET /A "vBias=1, hBias=99"
IF %~3 LSS 1 SET /A "vBias=99, hBias=1"
SET "title0=Hunt & Kill"
IF %~1 GEQ 0 IF %~2 EQU 100 SET title0=BackTracker

REM set bottom message
IF %~1 LSS 0 ( SET "msg= FIFO"
) ELSE SET "msg= LIFO"
IF %~2 LSS 1 ( SET "msg= hunt=always:stack=never"
) ELSE IF %~2 EQU 100 ( SET "msg=!msg!:hunt=never:stack=always"
) ELSE IF %~2 GTR 100 ( SET "msg=!msg!:hunt=never:stack=old/new"
) ELSE SET "msg=!msg!:hunt=!d1!%%:stack=%~2%%"
SET "msg=!msg!:vrt=!vBias!%%:hrz=!hBias!%%"
SET "labelTop= %title0% %cols%x%rows% "
SET "mm=!msg:~1!"
SET "msg=!msg:~0,%wide%!"

REM fill maze with 8186 walls, clip to size, and open starting position
SET "labelTop=!labelTop:~0,%cTmp%!"
SET "mz=!wall!"
FOR /L %%A IN (1,1,6) DO SET "mz=!mz!!mz!!mz!!mz!"
SET "top=!mz:~-%wide%!"
SET "mz=!mz:~3!!mz:~3!"
SET "mz=!mz:~0,%size%!"
SET "mz=!mz:~0,%curPos%!!player!!mz:~%t1%!"
SET "r1=!wall!!wall!!labelTop!!top!"
SET "mazeTop=!r1:~0,%wide%!"
SET "mz=!mazeTop!!mz:~%wide%!"

REM set display
IF !display! NEQ 0 (!clear!
	ECHO(!mz!
	%EKO%!msg:~1!
)
IF !display! GTR 0 CALL :mazing_BGcolor

REM build directional bias lists
FOR %%A IN (n s e w) DO SET "%%ABias=%%A"%=                                  'start each list with a single character =%
FOR /L %%A IN (2,1,!hBias!) DO SET "eBias=!eBias!e" & SET "wBias=!wBias!w"%= 'stack characters to represent percentage =%
FOR /L %%A IN (2,1,!vBias!) DO SET "nBias=!nBias!n" & SET "sBias=!sBias!s"%= 'chance to select each direction =%
SET "cp=...!curPos!"%=                                                       'set cp=currentPosition to beginPosition =%
SET "stack= !cp:~-4! "%=                                                     'clip to 4-digits w/leading space+dots+trailing space, stack positions are always 5 characters long =%
FOR /L %%? IN (1,1,64) DO IF !nCnt! LSS !nodes! FOR /L %%@ IN (1,1,64) DO IF !nCnt! LSS !nodes! (
	%mazingDebug% SET>%~f0.debug.HuntKill.txt
	%BGgrabKey%
	IF NOT EXIST "%keyFile%" CALL :mazing_menu
	IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
	IF !delay! GTR 0 CALL :mazing_wait !delay!
	%colorShift%
	SET "rand="
	IF NOT DEFINED curPos (%= 'trail=#of positions in stack, ch=randomPosition in stack, cTmp=0-99 stackType selection, t1=odd/even stackCount =%
		SET /A "rCnt=0, ch=!RANDOM!%%trail*5, cTmp=!RANDOM!%%100, t1=cnt%%2"
		IF !cTmp! LSS %~2 ( SET "tList=!stack:~0,5!"%=             'tList=topOfStack=lastStackPosition=LIFO =%
			IF %~2 GTR 100 IF !t1! EQU 0 SET "tList=!stack:~-5!"%= 'tList=bottomOfStack=firstStackPosition=FIFO =%
			SET /A "curPos=!tList:.=!"%=                           'remove dots and assure numeracy =%
		) ELSE FOR %%A IN (!ch!) DO FOR /F "tokens=1 delims=. " %%B IN ("!stack:~%%A!") DO SET "curPos=%%B"
	)%=       'or choose randomly using ch and separating newPosition by delimiting dots and spaces in the stack =%
	SET /A "rCnt=rTmp=numD=0, cnt+=1, cTmp=curPos+1, np=curPos-wide*2, sp=curPos+wide*2, ep=curPos+2, wp=curPos-2, wChk=curPos/wide*wide, eChk=wChk+wide, nw=curPos-wide, sw=curPos+wide, ew=curPos+1, ww=curPos-1"
	FOR /F "tokens=1-4" %%A IN ("!np! !sp! !ep! !wp!") DO (%= 'cnt=#of entries in stack, np/sp/ep/wp=north/south/east/west hallPosition, nw/sw/ew/ww=north/south/east/west wallPosition, wChk/eChk=east/west check for maze border =%
		IF !np! GTR !wide! IF "!mz:~%%A,1!" EQU "!wall!" SET /A numD+=1,rCnt+=vBias & SET "rand=!nBias!!rand!"
		IF !sp! LSS !size! IF "!mz:~%%B,1!" EQU "!wall!" SET /A numD+=1,rCnt+=vBias & SET "rand=!sBias!!rand!"
		IF !ep! LSS !eChk! IF "!mz:~%%C,1!" EQU "!wall!" SET /A numD+=1,rCnt+=hBias & SET "rand=!eBias!!rand!"
		IF !wp! GTR !wChk! IF "!mz:~%%D,1!" EQU "!wall!" SET /A numD+=1,rCnt+=hBias & SET "rand=!wBias!!rand!"
	)%= 'build random selection list by including biasList for each direction that is within the maze borders and isn't already a hall =%
	IF !rCnt! NEQ 0 (%= 'new adjacent unvisited cell available =%
		SET /A "nCnt+=1, pct=nCnt*100/nodes, trail+=1, rChk=!RANDOM!%%rCnt"%= 'nCnt=nodeCount=#of nodes added to maze, trail=#of entries in stack, rChk=random entry in selection list =%
		FOR %%A IN (!rChk!) DO FOR %%B IN (!rand:~%%A^,1!) DO SET /A "newPos=!%%Bp!, nTmp=newPos+1, mw=!%%Bw!, mTmp=mw+1"
		SET "cp=...!newPos!"%= 'snag random character from selection list and use it to set directional variables =%
		IF %~1 LSS 0 (%=                      'param1<0=stack is FIFO, so place newPosition on bottom of stack =%
			SET "stack=!stack!!cp:~-4! "
		) ELSE SET "stack= !cp:~-4!!stack!"%= 'else it's LIFO, so place on top instead =%
		FOR /F "tokens=1-4" %%A IN ("!mw! !mTmp! !newPos! !nTmp!") DO (
			SET "mz=!mz:~0,%%A!!hall!!mz:~%%B!"%= 'replace walls with hall+crumb characters in the newPositions =%
			SET "mz=!mz:~0,%%C!!crumb!!mz:~%%D!"
			IF !display! GTR 0 ( SET /A "r1=%%A/wide, c1=%%A-r1*wide, r2=%%C/wide, c2=%%C-r2*wide"
				BG.EXE FCPrint !r1! !c1! !bgClr!!exClr! "!hall!"
				BG.EXE FCPrint !r2! !c2! !bgClr!!exClr! "!crumb!"
			)
		)
	)%= 'remove dead cell from the list =%
	IF !numD! LSS 2 (%= 'rCnt<2 means either 0 or 1 directions available from currentPos, either way remove node from stack =%
		SET /A trail-=1
		SET "cp=...!curPos!"%= 'reduce stack count, remove currentPosition from stack =%
		FOR /F "tokens=1-3" %%A IN ("!curPos! !cTmp! !cp:~-4!") DO (
			SET "stack=!stack: %%C = !"
			IF !curPos! NEQ !bgnPos! (%= 'replace crumb character with hall, but not if start/player position =%
				SET "mz=!mz:~0,%%A!!hall!!mz:~%%B!"
				IF !display! GTR 0 ( SET /A "r1=%%A/wide, c1=%%A-r1*wide"
					BG.EXE FCPrint !r1! !c1! !bgClr!!exClr! "!hall!"
				)
			)
		)
	)
	IF !display! LSS 0 ( !clear!
		ECHO(!mz!
		%EKO%!msg:~1!
	)%=    'check for user menu, animate by clearing and EKOing maze =%
	IF !trail! GTR !far! SET "far=!trail!"
	IF !far! GTR !hkMax! SET "hkMax=!far!"%= 'set highest stack count =%
	TITLE Maze#!mazeCnt! ^| !title0! ^| !pct!%% n:!nodes!/!nCnt! ^| #!cnt! mx:!hkMax!/!far!/!trail! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
	SET /A curPos=newPos%=      'rCnt=0 means no new direction found, so clear currentPosition to force new position from stack =%
	IF !rCnt! EQU 0 SET curPos=
)
REM clear crumbs and exit
SET "mz=!mz:%crumb%=%hall%!"
EXIT /B 0

:mazing_growing_tree stackSize rsBias hvBias
REM %1=size of list for selecting cells. 0=all, >0=LIFO, <0=FIFO.
REM %2=next node bias. 0=always random, 100=always stack, >100=oldest/newest
REM %3=directional bias. 1=most vertical, 99=most horizontal.
REM If %1=0 and %2=0 the algorithm is randomized Prim's.
REM If %1>0 and %2=100 then algorithm is Depth-First BackTracker.
REM If %2>100 then stack will alternate between oldest and newest entries.

SET "stk="
SET /A "lst=%~1, curPos=bgnPos, nodes=cols*rows, lbClr=cnt=c1=0, nCnt=trail=far=1, d1=100-%~2, vBias=100-%~3, hBias=%~3, t1=curPos+1, cTmp=wide-4, exClr=!RANDOM!%%(colorCnt-2)"
IF !lst! LSS 0 SET /A "stk=lst*=-1"
IF %~3 GTR 99 SET /A "vBias=1, hBias=99"
IF %~3 LSS 1 SET /A "vBias=99, hBias=1"
SET title0=Growing Tree
IF %~1 EQU 0 IF %~2 EQU 0 SET title0=Prim's Algo
IF %~1 EQU 1 IF %~2 EQU 100 SET title0=BackTracker

REM set bottom message
IF %~1 EQU 0 ( SET "msg= LIFO list=all"
	IF %~2 EQU 0 SET "msg= list=all"
) ELSE IF %~1 GTR 0 ( SET "msg= LIFO list=!lst!"
) ELSE SET "msg= FIFO list=!lst!"
IF %~2 LSS 1 ( SET "msg=!msg!:random=always:stack=never"
) ELSE IF %~2 EQU 100 ( SET "msg=!msg!:random=never:stack=always"
) ELSE IF %~2 GTR 100 ( SET "msg=!msg!:random=never:stack=old/new"
) ELSE SET "msg=!msg!:random=!d1!%%:stack=%~2%%"
SET "msg=!msg!:vrt=!vBias!%%:hrz=!hBias!%%"
SET "labelTop= %title0% %cols%x%rows% "
SET "mm=!msg:~1!"
SET "msg=!msg:~0,%wide%!"

REM fill maze with 8186 walls, clip to size, and open starting position
SET "labelTop=!labelTop:~0,%cTmp%!"
SET "mz=!wall!"
FOR /L %%A IN (1,1,6) DO SET "mz=!mz!!mz!!mz!!mz!"
SET "top=!mz:~-%wide%!"
SET "mz=!mz:~3!!mz:~3!"
SET "mz=!mz:~0,%size%!"
SET "mz=!mz:~0,%curPos%!!player!!mz:~%t1%!"
SET "r1=!wall!!wall!!labelTop!!top!"
SET "mazeTop=!r1:~0,%wide%!"
SET "mz=!mazeTop!!mz:~%wide%!"

REM set display
IF !display! NEQ 0 (!clear!
	ECHO(!mz!
	%EKO%!msg:~1!
)
IF !display! GTR 0 CALL :mazing_BGcolor

REM build directional bias lists
FOR %%A IN (n s e w) DO SET "%%ABias=%%A"%=                                  'start each list with a single character =%
FOR /L %%A IN (2,1,!hBias!) DO SET "eBias=!eBias!e" & SET "wBias=!wBias!w"%= 'stack characters to represent percentage =%
FOR /L %%A IN (2,1,!vBias!) DO SET "nBias=!nBias!n" & SET "sBias=!sBias!s"%= 'chance to select each direction =%
SET "cp=...!curPos!"%=                                                       'set cp=currentPosition to beginPosition =%
SET "stack= !cp:~-4! "%=                                                     'clip to 4-digits w/leading space+dots+trailing space, stack positions are always 5 characters long =%
REM start 4096 loops/until all nodes are visited, just like Hunt & Kill with different list selection
FOR /L %%? IN (1,1,64) DO IF !nCnt! LSS !nodes! FOR /L %%@ IN (1,1,64) DO IF !nCnt! LSS !nodes! (
	%mazingDebug% SET>%~f0.debug.GrowingTree.txt
	%BGgrabKey%
	IF NOT EXIST "%keyFile%" CALL :mazing_menu
	IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
	IF !delay! GTR 0 CALL :mazing_wait !delay!
	%colorShift%
	SET "rand="
	SET /A limit=trail
	IF !lst! NEQ 0 IF !trail! GTR !lst! SET /A limit=lst
	REM choose cell from visited list
	SET /A "rCnt=0, ch=!RANDOM!%%limit*5, cTmp=!RANDOM!%%100, t1=cnt%%2"
	IF !cTmp! LSS %~2 ( SET "tList=!stack:~0,5!"
		IF %~2 GTR 100 IF !t1! EQU 0 SET "tList=!stack:~-5!"
		SET /A "curPos=!tList:.=!"
	) ELSE FOR %%A IN (!ch!) DO FOR /F "tokens=1 delims=. " %%B IN ("!stack:~%%A!") DO SET "curPos=%%B"
	SET /A "rCnt=rTmp=numD=0, cnt+=1, cTmp=curPos+1, np=curPos-wide*2, sp=curPos+wide*2, ep=curPos+2, wp=curPos-2, wChk=curPos/wide*wide, eChk=wChk+wide, nw=curPos-wide, sw=curPos+wide, ew=curPos+1, ww=curPos-1"
	REM examine NSEW, set highest stack position
	FOR /F "tokens=1-4" %%A IN ("!np! !sp! !ep! !wp!") DO (
		IF !np! GTR !wide! IF "!mz:~%%A,1!" EQU "!wall!" SET /A numD+=1,rCnt+=vBias & SET "rand=!nBias!!rand!"
		IF !sp! LSS !size! IF "!mz:~%%B,1!" EQU "!wall!" SET /A numD+=1,rCnt+=vBias & SET "rand=!sBias!!rand!"
		IF !ep! LSS !eChk! IF "!mz:~%%C,1!" EQU "!wall!" SET /A numD+=1,rCnt+=hBias & SET "rand=!eBias!!rand!"
		IF !wp! GTR !wChk! IF "!mz:~%%D,1!" EQU "!wall!" SET /A numD+=1,rCnt+=hBias & SET "rand=!wBias!!rand!"
	)
	IF !rCnt! NEQ 0 ( REM adjacent unvisited cell available
		REM choose RANDOM direction from list, set new cursor position, add to stack, and write to maze
		SET /A "nCnt+=1, pct=nCnt*100/nodes, trail+=1, rChk=!RANDOM!%%rCnt"
		FOR %%A IN (!rChk!) DO FOR %%B IN (!rand:~%%A^,1!) DO SET /A "newPos=!%%Bp!, nTmp=newPos+1, mw=!%%Bw!, mTmp=mw+1"
		SET "cp=...!newPos!"
		IF DEFINED stk (
			SET "stack=!stack!!cp:~-4! "
		) ELSE SET "stack= !cp:~-4!!stack!"
		FOR /F "tokens=1-4" %%A IN ("!mw! !mTmp! !newPos! !nTmp!") DO (
			SET "mz=!mz:~0,%%A!!hall!!mz:~%%B!"
			SET "mz=!mz:~0,%%C!!crumb!!mz:~%%D!"
			IF !display! GTR 0 ( SET /A "r1=%%A/wide, c1=%%A-r1*wide, r2=%%C/wide, c2=%%C-r2*wide"
				BG.EXE FCPrint !r1! !c1! !bgClr!!exClr! "!hall!"
				BG.EXE FCPrint !r2! !c2! !bgClr!!exClr! "!crumb!"
			)
		)
	)
	IF !numD! LSS 2 ( REM remove dead cell from the list
		REM clear crumbs from maze, remove curPos from stack, and set new position
		SET /A trail-=1
		SET "cp=...!curPos!"
		FOR /F "tokens=1-3" %%A IN ("!curPos! !cTmp! !cp:~-4!") DO (
			SET "stack=!stack: %%C = !"
			IF !curPos! NEQ !bgnPos! (
				SET "mz=!mz:~0,%%A!!hall!!mz:~%%B!"
				IF !display! GTR 0 ( SET /A "r1=%%A/wide, c1=%%A-r1*wide"
					BG.EXE FCPrint !r1! !c1! !bgClr!!exClr! "!hall!"
				)
			)
		)
	)
	IF !display! LSS 0 ( !clear!
		ECHO(!mz!
		%EKO%!msg:~1!
	)
	IF !trail! GTR !far! SET "far=!trail!"
	IF !far! GTR !gtMax! SET "gtMax=!far!"%= 'set highest stack count =%
	TITLE Maze#!mazeCnt! ^| !title0! ^| !pct!%% n:!nodes!/!nCnt! ^| #!cnt! mx:!gtMax!/!far!/!trail! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
)
REM clear crumbs and exit
SET "mz=!mz:%crumb%=%hall%!"
EXIT /B 0

:mazing_wall_division wallOpen stackType hvBias
REM %1=open walls where? 0=NW, 1=SE, 2=alternate NW/SE, 
REM                      3=midNW, 4=midSE, 5+=random
REM %2=stack order. 0-7=static pre-sets, 8+=random.
REM %3=directional bias. 1=most vertical, 99=most horizontal.
REM if %3=50 walls are generated evenly (ie. vrt if W>H, hrz if H>W).

SET /A "mode=%~3%%20, nodes=cols*rows, lbClr=cnt=nCnt=pct=hPos=0, cTmp=wide-4"
SET /A "b1=bgnPos+1, p1=%~1, t1=rows-1, t2=cols-1, vBias=100-%~3, hBias=%~3"
SET "fill=!hall!"
IF !mode! EQU 0 SET "fill=!crumb!"
IF "!wall!" EQU "ÿ" SET "fill=!crumb!"
IF %~3 GTR 99 SET /A "vBias=1, hBias=99"
IF %~3 LSS 1 SET /A "vBias=99, hBias=1"
IF !bgClr! LSS 7 SET "lbClr=F"
SET "title0=Wall Division"

REM set bottom message
IF %~1 EQU 0 ( SET "msg= wallOpen=NW"
) ELSE IF %~1 EQU 1 ( SET "msg= wallOpen=SE"
) ELSE IF %~1 EQU 2 ( SET "msg= wallOpen=NW/SE"
) ELSE IF %~1 EQU 3 ( SET "msg= wallOpen=mid"
) ELSE SET "msg= wallOpen=random"
IF %~2 LSS 8 ( SET "msg=!msg!:stack=static%~2"
) ELSE SET "msg=!msg!:stack=random"
IF %~3 EQU 50 ( SET "msg=!msg!:vrt=even:hrz=even"
) ELSE SET "msg=!msg!:vrt=!vBias!%%:hrz=!hBias!%%"
SET "mm=!msg:~1!"
SET "msg=!msg:~0,%wide%!"

REM create empty maze with borders
SET "top=!wall!"
FOR /L %%A IN (1,1,5) DO SET "top=!top!!top!!top!!top!"
SET "top=!top:~-%wide%!"
SET "mazeTop= Wall Division %cols%x%rows% "
IF %~3 EQU 50 SET "mazeTop= Volvo Division %cols%x%rows% "
SET "labelTop=!mazeTop:~0,%cTmp%!"
SET "mazeTop=!wall!!wall!!labelTop!!top!"
SET "mazeTop=!mazeTop:~0,%wide%!"
SET "mid=!top:%wall%=%fill%!"
SET "mid=!wall!!mid:~2!!wall!"
SET "mz=!mazeTop!"
FOR /L %%A IN (3,1,%high%) DO SET "mz=!mz!!mid!"
SET "mz=!mz:~0,%bgnPos%!!player!!mz:~%b1%!!top!"

REM set display
IF !display! NEQ 0 (!clear!
	ECHO(!mz!
	%EKO%!msg:~1!
)
IF !display! GTR 0 CALL :mazing_BGcolor

REM 0=NS/WE-LIFO, +1=SN/EW, +2=NS/SN-FIFO, +4=WE/EW-FIFO
SET /A "r0=%~2 & 1, r1=(%~2 & 2)/2, r2=(%~2 & 4)/4, block=(nodes+3)/4"
SET "stack=0:0:!t1!:!t2! "

REM ULrow ULcolumn #wallsDown #wallsRight
FOR /L %%? IN (1,1,64) DO IF DEFINED stack FOR /L %%@ IN (1,1,64) DO IF DEFINED stack (
	%mazingDebug% SET>%~f0.debug.WallDivision.txt
	SET /A cnt+=1
	IF %~1 EQU 2 SET /A "p1=(p1+1)&1"
	FOR /F "tokens=1-4 delims=: " %%A IN ("!stack!") DO (
		%BGgrabKey%
		IF NOT EXIST "%keyFile%" CALL :mazing_menu
		IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
		IF !delay! GTR 0 CALL :mazing_wait !delay!
		%colorShift%
		SET "stack=!stack:* =!"
		SET /A "pct=nCnt*100/block, hv=!RANDOM!%%100"
		IF %~2 GEQ 8 SET /A "r0=!RANDOM! & 1, r1=!RANDOM! & 1, r2=!RANDOM! & 1"
		IF %~3 EQU 50 IF %%C GTR %%D ( SET "hv=0" ) ELSE IF %%C LSS %%D ( SET "hv=99" )
		IF !hv! LSS %~3 ( REM horizontal wall
			IF !p1! EQU 0 ( SET hPos=0
			) ELSE IF !p1! EQU 1 ( SET hPos=%%D
			) ELSE IF !p1! EQU 3 ( SET /A "hPos=(%%D+!RANDOM!%%2)/2"
			) ELSE SET /A "hPos=!RANDOM!%%(%%D+1)"
			SET /A "wPos=!RANDOM!%%%%C+%%A+1, wLen=%%D*2, rLen=wLen-hPos*2, lLen=wLen-rLen"
			SET /A "sPos=wPos*2*wide+%%B*2+1, ePos=sPos+wLen+1, t1=wPos-%%A-1, t2=%%C-t1-1"
			FOR /F "tokens=1-4" %%E IN ("!lLen! !rLen! !sPos! !ePos!") DO (
				SET "mz=!mz:~0,%%G!!top:~0,%%E!!fill!!top:~0,%%F!!mz:~%%H!"
			)
			IF !r0! EQU 0 ( REM randomizing the stack, could replace with a single line
				IF !t1! NEQ 0 ( SET /A "nCnt+=1"
					IF !r1! EQU 0 ( SET "stack=%%A:%%B:!t1!:%%D !stack!"
					) ELSE SET "stack=!stack!%%A:%%B:!t1!:%%D ")
				IF !t2! NEQ 0 ( SET /A "nCnt+=1"
					IF !r2! EQU 0 ( SET "stack=!wPos!:%%B:!t2!:%%D !stack!"
					) ELSE SET "stack=!stack!!wPos!:%%B:!t2!:%%D ")
			) ELSE (
				IF !t2! NEQ 0 ( SET /A "nCnt+=1"
					IF !r1! EQU 0 ( SET "stack=!wPos!:%%B:!t2!:%%D !stack!"
					) ELSE SET "stack=!stack!!wPos!:%%B:!t2!:%%D ")
				IF !t1! NEQ 0 ( SET /A "nCnt+=1"
					IF !r2! EQU 0 ( SET "stack=%%A:%%B:!t1!:%%D !stack!"
					) ELSE SET "stack=!stack!%%A:%%B:!t1!:%%D ")
			)
		) ELSE ( REM vertical wall
			IF !p1! EQU 0 ( SET hPos=0
			) ELSE IF !p1! EQU 1 ( SET hPos=%%C
			) ELSE IF !p1! EQU 3 ( SET /A "hPos=(%%C+!RANDOM!%%2)/2"
			) ELSE SET /A "hPos=!RANDOM!%%(%%C+1)"
			SET /A "wPos=!RANDOM!%%%%D+%%B+1, wLen=%%C*2, rLen=hPos*2, t1=wPos-%%B-1, t2=%%D-t1-1"
			SET /A "sPos=(%%A*2+1)*wide+wPos*2, ePos=sPos+wLen*wide, hCnt=-1"
			FOR /L %%E IN (!sPos!,!wide!,!ePos!) DO (
				SET /A "mTmp=%%E+1, hCnt+=1"
				IF !hCnt! NEQ !rLen! FOR %%F IN (!mTmp!) DO SET "mz=!mz:~0,%%E!!wall!!mz:~%%F!"
			)
			IF !r0! EQU 0 (
				IF !t1! NEQ 0 ( SET /A "nCnt+=1"
					IF !r1! EQU 0 ( SET "stack=%%A:%%B:%%C:!t1! !stack!"
					) ELSE SET "stack=!stack!%%A:%%B:%%C:!t1! ")
				IF !t2! NEQ 0 ( SET /A "nCnt+=1"
					IF !r2! EQU 0 ( SET "stack=%%A:!wPos!:%%C:!t2! !stack!"
					) ELSE SET "stack=!stack!%%A:!wPos!:%%C:!t2! ")
			) ELSE (
				IF !t2! NEQ 0 ( SET /A "nCnt+=1"
					IF !r1! EQU 0 ( SET "stack=%%A:!wPos!:%%C:!t2! !stack!"
					) ELSE SET "stack=!stack!%%A:!wPos!:%%C:!t2! ")
				IF !t1! NEQ 0 ( SET /A "nCnt+=1"
					IF !r2! EQU 0 ( SET "stack=%%A:%%B:%%C:!t1! !stack!"
					) ELSE SET "stack=!stack!%%A:%%B:%%C:!t1! ")
			)
		)
	)
	IF !display! GTR 0 ( BG.EXE Locate 1 0
		ECHO(!mz:~%wide%!
	)
	IF !display! LSS 0 ( !clear!
		ECHO(!mz!
		%EKO%!msg:~1!
	)
	IF !nCnt! LEQ !block! TITLE Maze#!mazeCnt! ^| !title0! ^| !pct!%% #!cnt! block:!block!/!nCnt! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
)
TITLE Maze#!mazeCnt! ^| !title0! ^| 100%% #!cnt! block:!block!/!block! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
SET "mz=!mz:%crumb%=%hall%!"
EXIT /B 0

:mazing_ellers hvBias
REM %1=directional bias. 0=most vertical, 99=most horizontal
SET /A "curPos=bgnPos, b1=bgnPos+1, b2=bgnPos/(wide*2)+1, lbClr=sCnt=cnt=c1=0, nCnt=trail=far=1, cTmp=wide-4, vBias=100-%~1, hBias=%~1"
SET "fill=!hall!"
IF "!wall!" EQU "ÿ" SET "fill=!crumb!"
IF %~1 GTR 99 SET /A "vBias=1, hBias=99"
IF %~1 LSS 1 SET /A "vBias=99, hBias=1"
SET "msg= vrt=!vBias!%%:hrz=!hBias!%%"
SET "mm=!msg:~1!"
SET "title0=Eller's Algo"

REM create border and mazeTop
SET "top=!wall!"
FOR /L %%A IN (1,1,5) DO SET "top=!top!!top!!top!!top!"
SET "top=!top:~-%wide%!"
SET "mazeTop= Eller's Algo %cols%x%rows% "
SET "labelTop=!mazeTop:~0,%cTmp%!"
SET "mazeTop=!wall!!wall!!labelTop!!top!"
SET "mazeTop=!mazeTop:~0,%wide%!"
SET "wlz=!mazeTop!"
SET "hlz="
SET "mz="

IF !display! NEQ 0 (!clear!
	COLOR !bgClr!!fgClr!
	ECHO(!wlz!
)
IF !display! GTR 0 CALL :mazing_BGcolor

FOR /L %%A IN (1,1,%cols%) DO SET "c%%A="
FOR /L %%A IN (1,1,%rows%) DO (
	%mazingDebug% SET>%~f0.debug.Ellers.txt
	%BGgrabKey%
	IF NOT EXIST "%keyFile%" CALL :mazing_menu
	IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
	IF !delay! GTR 0 CALL :mazing_wait !delay!
	%colorShift%
	SET "mz=!mz!!wlz!"
	IF !display! GTR 0 ( BG.EXE Locate 1 0
		ECHO(!mz:~%wide%!
	)
	IF !display! LSS 0 ( !clear!
		ECHO(!mz!
	)
	FOR /L %%B IN (1,1,%cols%) DO IF NOT DEFINED c%%B SET /A "c%%B=sCnt, sCnt+=1"
	SET "hlz=!wall!!fill!"
	SET "stack=;!c1! "
	SET /A "last=c1, pct=%%A*100/rows"
	TITLE Maze#!mazeCnt! ^| !title0! ^| !pct!%% hrz=!hBias!%% vrt=!vBias!%% ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
	FOR /L %%B IN (2,1,%cols%) DO (
		SET /A "rc=!RANDOM!%%100"
		IF %%A EQU %rows% SET rc=0
		IF !rc! LSS !hBias! (
			IF !c%%B! NEQ !last! (
				SET /A rc=c%%B
				FOR /L %%C IN (1,1,%cols%) DO IF !c%%C! EQU !rc! SET /A "c%%C=last"
				SET "hlz=!hlz!!fill!!fill!"
			) ELSE SET "hlz=!hlz!!wall!!fill!"
		) ELSE SET "hlz=!hlz!!wall!!fill!"
		SET "stack=!stack!;!c%%B! "
		SET /A "last=c%%B"
	)
	SET "mz=!mz!!hlz!!wall!"
	IF %%A EQU !b2! SET "mz=!mz:~0,%bgnPos%!!player!!mz:~%b1%!"
	IF !display! GTR 0 ( BG.EXE Locate 1 0
		ECHO(!mz:~%wide%!
	)
	IF !display! LSS 0 ( !clear!
		ECHO(!mz!
	)
	SET "stack=!stack!A"
	SET "wlz=!wall!"
	IF %%A NEQ %rows% FOR /L %%B IN (1,1,%cols%) DO (
		SET /A "rr=!RANDOM!%%100"
		SET "stack=!stack:* =!"
		FOR %%C IN (!c%%B!) DO IF "!stack:;%%C =!" EQU "!stack!" SET "rr=99"
		IF !rr! LSS !hBias! (
			SET "c%%B="
			SET "wlz=!wlz!!wall!!wall!"
		) ELSE (
			SET "stack=!stack!;!c%%B! "
			SET "wlz=!wlz!!fill!!wall!"
		)
	)
)
SET "mz=!mz!!top!"
SET "mz=!mz:%crumb%=%hall%!"
IF !display! GTR 0 ( BG.EXE Locate 1 0
	ECHO(!mz:~%wide%!
	BG.EXE Print !bgClr!!lbClr! "!msg:~1!"
)
EXIT /B 0

:mazing_kruskals hvBias
REM %1=directional bias. 1=most vertical, 99=most horizontal
SET /A "vwCnt=hwCnt=pctN=pctW=umCnt=0,nCnt=1,vBias=100-%~1,hBias=%~1,bp1=bgnPos+1,lt1=wide-4"
IF %~1 GTR 99 SET /A "vBias=1, hBias=99"
IF %~1 LSS 1 SET /A "vBias=99, hBias=1"
SET "title0=Kruskal's Algo"

REM set bottom message
SET "msg= vrt=!vBias!%%:hrz=!hBias!%%"
SET "labelTop= %title0% %cols%x%rows% "
SET "mm=!msg:~1!"
SET "msg=!msg:~0,%wide%!"

REM fill maze with 8186 walls, clip to size, and open starting position
SET "labelTop=!labelTop:~0,%lt1%!"
SET "mz=!wall!"
FOR /L %%A IN (1,1,6) DO SET "mz=!mz!!mz!!mz!!mz!"
SET "top=!mz:~-%wide%!"
SET "mz=!mz:~3!!mz:~3!"
SET "mz=!mz:~0,%size%!"
SET "mz=!mz:~0,%bgnPos%!!player!!mz:~%bp1%!"
SET "r1=!wall!!wall!!labelTop!!top!"
SET "mazeTop=!r1:~0,%wide%!"
SET "mz=!mazeTop!!mz:~%wide%!"
SET "fil1=!hall!"
SET "fil2=!hall!"
SET "fil!ynm!=!crumb!"
IF "!wall!" EQU "ÿ" SET "fil1=!crumb!" & SET "fil2=!crumb!"

REM set display
IF !display! NEQ 0 (!clear!
	ECHO(!mz!
	%EKO%!msg:~1!
)
IF !display! GTR 0 CALL :mazing_BGcolor

REM create findMerge.cmd, by far the fastest way I've found for union-Find/Merge in batch
IF NOT EXIST %~n0.uMerge.cmd (
	ECHO :mazing_uMerge
	ECHO SET/A umCnt+=1
	ECHO IF ^^^!ka_%%um1%%^^^! NEQ %%um1%% ^( SET um1=^^^!ka_%%um1%%^^^!
	ECHO SET umFix=%%umFix%% %%um1%%
	ECHO GOTO :mazing_uMerge ^)
	ECHO IF ^^^!ka_%%um2%%^^^! NEQ %%um2%% ^( SET um2=^^^!ka_%%um2%%^^^!
	ECHO SET umFix=%%umFix%% %%um2%%
	ECHO GOTO :mazing_uMerge ^)
	ECHO FOR %%%%X IN ^(%%um1%% %%umFix:~1%%^) DO SET ka_%%%%X=%%um2%%
	ECHO IF %%um1%% NEQ %%um2%% EXIT /B 1
	ECHO EXIT /B 0
) > %~n0.uMerge.cmd

REM build wall list and disjoint set for :unionMerge
FOR /L %%A IN (1,1,%rows%) DO (
	TITLE Maze#!mazeCnt! ^| !title0! sorting walls ^| row# %%A of %rows% ^| vw:!vwCnt! hw:!hwCnt! mx:!kaMax!/!umCnt! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
	%BGgrabKey%
	IF NOT EXIST "%keyFile%" CALL :mazing_menu
	IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
	%colorShift%
	FOR /L %%B IN (1,1,%cols%) DO (
		SET /A "np=wide*%%A*2-wide+%%B*2-1,vp=np+2,hp=np+wide*2,vChk=wide*%%A*2"
		IF !vp! LSS !vChk! SET /A "vn!vwCnt!=np,vw!vwCnt!=np+1,vp!vwCnt!=vp,vwCnt+=1"
		IF !hp! LSS !size! SET /A "hn!hwCnt!=np,hw!hwCnt!=np+wide,hp!hwCnt!=hp,hwCnt+=1"
		SET "ka_!np!=!np!"
	)
)
IF !display! NEQ 0 SET "BGstart=" & SET "FGstart=" & SET /A csCnt=csTrg=pCnt=0

REM loop through #walls, select from V/H wallLists, uMerge positions, and carve new openings
SET /A "numWalls=cols*rows*2-cols-rows-1,numNodes=cols*rows"
FOR /L %%@ IN (!numWalls!,-1,0) DO (
	SET /A "pctN=nCnt*100/numNodes,tn=numNodes-nCnt,pctW=(numWalls-%%@)*100/numWalls,rBias=!RANDOM!%%100,umFix=umt1=umt2=0"
	%mazingDebug% SET>%~f0.debug.Kruskals.txt
	%BGgrabKey%
	IF NOT EXIST "%keyFile%" CALL :mazing_menu
	IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
	IF !delay! GTR 0 CALL :mazing_wait !delay!
	%colorShift%
	REM check directionalbias and select from wall lists
	IF !vwCnt! LEQ 0 SET rBias=99
	IF !hwCnt! LEQ 0 SET rBias=0
	IF !rBias! LSS !hBias! ( SET /A vwRnd=!RANDOM!%%vwCnt,vwCnt-=1
		SET /A rn=rn1=um1=vn!vwRnd!,rw=rw1=vw!vwRnd!,rp=rp1=um2=vp!vwRnd!,vn!vwRnd!=vn!vwCnt!,vw!vwRnd!=vw!vwCnt!,vp!vwRnd!=vp!vwCnt!,rn1+=1,rw1+=1,rp1+=1
		SET "vn!vwCnt!=" & SET "vw!vwCnt!=" & SET "vp!vwCnt!="
	) ELSE ( SET/A hwRnd=!RANDOM!%%hwCnt,hwCnt-=1
		SET /A rn=rn1=um1=hn!hwRnd!,rw=rw1=hw!hwRnd!,rp=rp1=um2=hp!hwRnd!,hn!hwRnd!=hn!hwCnt!,hw!hwRnd!=hw!hwCnt!,hp!hwRnd!=hp!hwCnt!,rn1+=1,rw1+=1,rp1+=1
		SET "hn!hwCnt!=" & SET "hw!hwCnt!=" & SET "hp!hwCnt!="
	)	
	REM check positional sets and carve wall if merged
	CALL %~n0.uMerge.cmd
	IF ERRORLEVEL 1 FOR /F "tokens=1-6" %%A IN ("!rn! !rp! !rw! !rn1! !rp1! !rw1!") DO (
		IF "!mz:~%%A,1!" EQU "!wall!" SET "alt1=!fil1!" & SET /A nCnt+=1
		IF "!mz:~%%A,1!" EQU "!fil1!" SET "alt1=!fil2!"
		IF "!mz:~%%B,1!" EQU "!wall!" SET "alt2=!fil1!" & SET /A nCnt+=1
		IF "!mz:~%%B,1!" EQU "!fil1!" SET "alt2=!fil2!"
		IF !rBias! LSS !hBias! (
			SET "mz=!mz:~0,%%A!!alt1!!hall!!alt2!!mz:~%%E!"
		) ELSE (
			SET "mz=!mz:~0,%%A!!alt1!!mz:~%%D!"
			SET "mz=!mz:~0,%%B!!alt2!!mz:~%%E!"
			SET "mz=!mz:~0,%%C!!hall!!mz:~%%F!"
		)
		IF %%A EQU !bgnPos! SET "mz=!mz:~0,%bgnPos%!!player!!mz:~%bp1%!"
		IF %%B EQU !bgnPos! SET "mz=!mz:~0,%bgnPos%!!player!!mz:~%bp1%!"
		IF !display! LSS 0 ( !clear!
			ECHO(!mz!
			%EKO%!msg:~1!
		)
		IF !display! GTR 0 ( SET /A "r1=%%A/wide,c1=%%A-r1*wide,r2=%%B/wide,c2=%%B-r2*wide,r3=%%C/wide,c3=%%C-r3*wide"
			IF %%A NEQ !bgnPos! BG.EXE FCPrint !r1! !c1! !bgClr!!exClr! "!alt1!"
			IF %%B NEQ !bgnPos! BG.EXE FCPrint !r2! !c2! !bgClr!!exClr! "!alt2!"
			BG.EXE FCPrint !r3! !c3! !bgClr!!exClr! "!hall!"
		)
	)
	IF !umCnt! GTR !kaMax! SET "kaMax=!umCnt!"
	TITLE Maze#!mazeCnt! ^| !title0! ^| !pctN!%% n:!numNodes!/!tn! ^| !pctW!%% w:!numWalls!/%%@ ^| vw:!vwCnt! hw:!hwCnt! mx:!kaMax!/!umCnt! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
)
REM clear crumbs and variables then exit
FOR /F "delims==" %%A IN ('SET ka_') DO SET "%%A="
SET "mz=!mz:%crumb%=%hall%!"
EXIT /B 0

REM uFind/Merge pared down to a for loop, still 2-3 times slower than the batch file
SET "ufFix="
FOR /L %%A IN (1,1,12) DO ( SET /A t1=ka_!uf1!,t2=ka_!uf2!
	IF !uf1! NEQ !t1! SET /A "uf1=ka_!uf1!" & SET "ufFix=!ufFix! !uf1!"
	IF !uf2! NEQ !t2! SET /A "uf2=ka_!uf2!" & SET "ufFix=!ufFix! !uf2!"
)
FOR %%A IN (!uf1! !ufFix!) DO SET ka_%%A=!uf2!
IF !uf1! NEQ !uf2! ...

:mazing_wilsons #ofAdditionalEntryPoints hvBias
REM %1 number of additional entry points, maze=crumbs if negative
REM %1 odd=reverse crumbs+halls in walk / don't show loop animation
REM %1 mod3 0=crumb+hall / 1=all crumbs / 2=all halls
REM %2 minumum length of 1st random walk from 1-11% numNodes, if %2=0 use addEntry
REM %3=directional bias. 1=most vertical, 99=most horizontal
SET /A "addEntry=%~1,lr=%~1%%2,uds=%~1%%3,vBias=100-%~3,hBias=%~3,numNodes=cols*rows,curPos=bt=bgnPos,waStop=minWalk=bgCnt=nCnt=pct=cnt=t1=t2=t3=0,rWalk=1,t4=wide-4,bt+=1"
IF %~1 LSS 0  SET /A addEntry*=-1
IF %~2 NEQ 0  SET /A "minWalk=(%~2+9)*numNodes/1000"
IF %~3 LSS 1  SET /A vBias=99,hBias=1
IF %~3 GTR 99 SET /A vBias=1,hBias=99
SET "title0=Wilson's Algo"

REM set bottom message
SET "msg= addEntry=!addEntry!:vrt=!vBias!%%:hrz=!hBias!%%"
IF !minWalk! NEQ 0 SET "msg= 1stWalk=!minWalk!:vrt=!vBias!%%:hrz=!hBias!%%"
SET "labelTop= %title0% %cols%x%rows% "
SET "mm=!msg:~1!"
SET "msg=!msg:~0,%wide%!"

REM fill maze with 8186 walls, clip to size, and open starting position
SET "labelTop=!labelTop:~0,%t4%!"
SET "mz=!wall!"
FOR /L %%A IN (1,1,6) DO SET "mz=!mz!!mz!!mz!!mz!"
SET "top=!mz:~-%wide%!"
SET "mz=!mz:~3!!mz:~3!"
SET "mz=!mz:~0,%size%!"
SET "mz=!mz:~0,%bgnPos%!!player!!mz:~%bt%!"
SET "r1=!wall!!wall!!labelTop!!top!"
SET "mazeTop=!r1:~0,%wide%!"
SET "mz=!mazeTop!!mz:~%wide%!"

REM set display
IF !display! NEQ 0 (!clear!
	ECHO(!mz!
	%EKO%!msg:~1!
)

REM set display characters
SET "tMaze=!hall!"
SET "tHall=!hall!"
SET "tCrumb=!crumb!"
IF %~1   LSS 0 SET /A uds*=-1
IF %~1   LSS 0 SET "tMaze=!crumb!"
IF !lr!  NEQ 0 SET "tHall=!crumb!" & SET "tCrumb=!hall!"
IF !uds! EQU 1 SET "tHall=!crumb!" & SET "tCrumb=!crumb!"
IF !uds! EQU 2 IF "!wall!" NEQ "ÿ" SET "tHall=!hall!" & SET "tCrumb=!hall!"
IF "!wall!" EQU "ÿ" SET "tMaze=!crumb!"

REM build node list for random entry
TITLE Maze#!mazeCnt! ^| !title0! sorting nodes, please wait...  !TIME: =0!
FOR /L %%A IN (1,1,%rows%) DO FOR /L %%B IN (1,1,%cols%) DO (
	SET /A np=wide*%%A*2-wide+%%B*2-1
	SET /A mz_!np!=nCnt,rn_!nCnt!=np,nCnt+=1
)

REM set beginPosition as first currentPosition
SET /A nCnt-=1
SET /A t1=rn_!mz_%bgnPos%!=rn_!nCnt!,walk!bgnPos!=rWalk
SET /A mz_!t1!=!mz_%bgnPos%!
SET "mz_!bgnPos!="
SET "rn_!nCnt!="

REM create random entry point(s)
IF !minWalk! EQU 0 FOR /L %%A IN (0,1,!addEntry!) DO (
	SET /A tr=!RANDOM!%%nCnt,nCnt-=1
	SET /A t1=t2=rn_!tr!,t3=rn_!tr!=rn_!nCnt!,t2+=1
	SET  "mz_!t3!=!tr!"
	FOR %%B IN (!t1!) DO FOR %%C IN (!t2!) DO (
		SET "mz=!mz:~0,%%B!!tMaze!!mz:~%%C!"
		SET "ae_%%A=%%B %%C"
		SET "rn_!nCnt!="
		SET "mz_%%B="
	)
)

IF !display! NEQ 0 (!clear!
	ECHO(!mz!
	%EKO%!msg:~1!
)
IF !display! GTR 0 CALL :mazing_BGcolor

REM build directional bias lists
FOR %%A IN (n s e w) DO SET "%%ABias=%%A"%=                                  'start each list with a single character =%
FOR /L %%A IN (2,1,!hBias!) DO SET "eBias=!eBias!e" & SET "wBias=!wBias!w"%= 'stack characters to represent percentage =%
FOR /L %%A IN (2,1,!vBias!) DO SET "nBias=!nBias!n" & SET "sBias=!sBias!s"%= 'chance to select each direction =%
FOR /L %%? IN (1,1,1024) DO IF DEFINED waStop FOR /L %%@ IN (1,1,1024) DO IF DEFINED waStop (
	%mazingDebug% SET>%~f0.debug.Wilsons.txt
	%BGgrabKey%
	IF NOT EXIST "%keyFile%" CALL :mazing_menu
	IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
	IF !delay! GTR 0 CALL :mazing_wait !delay!
	%colorShift%
	IF !curPos! EQU 0 ( REM start new random walk
		SET /A tr=!RANDOM!%%nCnt,nCnt-=1,rWalk=1,bgCnt=cnt+9
		SET /A t1=t2=rn_!tr!,t3=rn_!tr!=rn_!nCnt!,t2+=1
		SET "mz_!t3!=!tr!"
		FOR %%A IN (!t1!) DO FOR %%B IN (!t2!) DO (
			SET "mz=!mz:~0,%%A!!tCrumb!!mz:~%%B!"
			SET /A curPos=%%A,walk%%A=rWalk
			SET "rn_!nCnt!="
			SET "mz_%%A="
			IF !display! GTR 0 ( SET /A r1=%%A/wide,c1=%%A-r1*wide
				BG.EXE FCPrint !r1! !c1! !bgClr!!pClr! "!tCrumb!"
			)
		)
	)
	REM calculate positions and build directional bias list
	SET "rBias="
	SET /A "np=curPos-wide*2,sp=curPos+wide*2,ep=curPos+2,wp=curPos-2,nw=curPos-wide,sw=curPos+wide,ew=curPos+1,ww=curPos-1,wChk=curPos/wide*wide,eChk=wChk+wide,rCnt=0,cnt+=1"
	FOR /F "tokens=1-4" %%A IN ("!nw! !sw! !ew! !ww!") DO (%= 'np/sp/ep/wp=north/south/east/west hallPosition, nw/sw/ew/ww=north/south/east/west wallPosition, wChk/eChk=east/west check for maze border =%
		IF !np! GTR !wide! IF "!mz:~%%A,1!" EQU "!wall!" SET /A rCnt+=vBias & SET "rBias=!nBias!!rBias!"
		IF !sp! LSS !size! IF "!mz:~%%B,1!" EQU "!wall!" SET /A rCnt+=vBias & SET "rBias=!sBias!!rBias!"
		IF !ep! LSS !eChk! IF "!mz:~%%C,1!" EQU "!wall!" SET /A rCnt+=hBias & SET "rBias=!eBias!!rBias!"
		IF !wp! GTR !wChk! IF "!mz:~%%D,1!" EQU "!wall!" SET /A rCnt+=hBias & SET "rBias=!wBias!!rBias!"
	)
	REM snag random character from bias list and use it to set directional variables
	SET /A "rChk=!RANDOM!%%rCnt"
	FOR %%A IN (!rChk!) DO FOR %%B IN (!rBias:~%%A^,1!) DO SET /A "newPos=pt=!%%Bp!,newWall=wt=!%%Bw!,pt+=1,wt+=1"
	IF !minWalk! NEQ 0 IF !rWalk! GEQ !minWalk! IF DEFINED mz_!newPos! (
		SET /A t1=mz_!newPos!,nCnt-=1,minWalk=0
		SET /A t2=rn_!t1!=rn_!nCnt!
		SET /A mz_!t2!=t1
		SET "mz_!newPos!="
		SET "rn_!nCnt!="
		FOR %%A IN (!newPos!) DO FOR %%B IN (!pt!) DO SET "mz=!mz:~0,%%A!!tMaze!!mz:~%%B!"
	)
	IF DEFINED mz_!newPos! ( REM cell is unvisited if mz_# variable is defined for this position
		FOR /F "tokens=1-4" %%A IN ("!newWall! !wt! !newPos! !pt!") DO (
			SET "mz=!mz:~0,%%A!!tHall!!mz:~%%B!"
			SET "mz=!mz:~0,%%C!!tCrumb!!mz:~%%D!"
			SET "step!rWalk!=%%A %%B %%C %%D"
			SET /A walk%%C=rWalk+=1,curPos=newPos,nCnt-=1
			SET /A t3=rn_!mz_%%C!=rn_!nCnt!
			SET "mz_!t3!=!mz_%%C!"
			SET "mz_%%C="
			IF !display! GTR 0 ( SET /A r1=%%A/wide,c1=%%A-r1*wide,r2=%%C/wide,c2=%%C-r2*wide
				BG.EXE FCPrint !r1! !c1! !bgClr!!pClr! "!tHall!"
				BG.EXE FCPrint !r2! !c2! !bgClr!!pClr! "!tCrumb!"
			)
		)
	) ELSE IF DEFINED walk!newPos! ( REM cell is part of random walk if walk# variable is defined for this position
		SET /A loopEnd=rWalk-1,rWalk=walk!newPos!,curPos=newPos
		FOR /L %%A IN (!rWalk!,1,!loopEnd!) DO FOR /F "tokens=1-4" %%B IN ("!step%%A!") DO (
			SET "mz=!mz:~0,%%B!!wall!!mz:~%%C!"
			SET "mz=!mz:~0,%%D!!wall!!mz:~%%E!"
			SET /A mz_%%D=nCnt,rn_!nCnt!=%%D,nCnt+=1
			SET "step%%A="
			SET "walk%%D="
			IF !display! LSS 0 IF !lr! EQU 0 ( !clear!
				ECHO(!mz!
				%EKO%!msg:~1!
			)
			IF !display! GTR 0 ( SET /A r1=%%B/wide,c1=%%B-r1*wide,r2=%%D/wide,c2=%%D-r2*wide
				BG.EXE FCPrint !r1! !c1! !bgClr!!gClr! "!wall!"
				BG.EXE FCPrint !r2! !c2! !bgClr!!gClr! "!wall!"
			)
		)
	) ELSE ( REM cell is part of maze if the other two conditions are untrue
		REM correct additional entry points if they exist
		IF DEFINED ae_0 FOR /L %%A IN (0,1,!addEntry!) DO (
			FOR /F "tokens=1,2" %%B IN ("!ae_%%A!") DO IF %%B NEQ !newPos! (
				SET "mz=!mz:~0,%%B!!wall!!mz:~%%C!"
				SET /A mz_%%B=nCnt,rn_!nCnt!=%%B,nCnt+=1
			)
			SET "ae_%%A="
		)
		FOR /F "tokens=1,2" %%A IN ("!newWall! !wt!") DO SET "mz=!mz:~0,%%A!!tHall!!mz:~%%B!"
		FOR /F "delims==" %%A IN ('SET step 2^>NUL') DO SET "%%A="
		FOR /F "delims==" %%A IN ('SET walk') DO SET "%%A="
		IF "!tMaze!" NEQ "!tHall!" ( SET "mz=!mz:%tHall%=%tMaze%!"
		) ELSE IF "!tMaze!" NEQ "!tCrumb!" SET "mz=!mz:%tCrumb%=%tMaze%!"
		SET "mz=!mazeTop!!mz:~%wide%!"
		IF !nCnt! EQU 0 SET "waStop="
		SET "curPos=0"
		IF !display! GTR 0 ( !clear!
			ECHO(!mz!
			%EKO%!msg:~1!
			IF !cnt! GTR !bgCnt! CALL :mazing_BGcolor
		)
	)
	IF !display! LSS 0 ( !clear!
		ECHO(!mz!
		%EKO%!msg:~1!
	)
	SET /A "pct=(numNodes-nCnt)*100/numNodes"
	IF !cnt! GTR !w1Max! SET "w1Max=!cnt!"
	IF !rWalk! GTR !far! SET "far=!rWalk!"
	IF !far! GTR !w2Max! SET "w2Max=!far!"
	TITLE Maze#!mazeCnt! ^| !title0! ^| !pct!%% n:!numNodes!/!nCnt! ^| mx#!w1Max!/!cnt! mx:!w2Max!/!far!/!rWalk! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
)
SET "mz=!mz:%crumb%=%hall%!"
EXIT /B 0

:mazing_rebuild boxType
REM %1=type of maze produced. %1<0=random single character, %1>0=box characters 1-12
SET /A "wd=cols*2,bx=%~1%%(%numOfBoxes%+1),t1=!RANDOM!%%bColorCnt,t2=!RANDOM!%%fColorCnt,t3=!RANDOM!%%wallCnt,t4=!RANDOM!%%crumbCnt,b1=bgnPos+1,e1=endPos+1"
IF !t1!==!t2! GOTO :mazing_rebuild
IF %mzOp14% LSS 0  SET "bgClr=!bColors:~%t1%,1!"
IF %mzOp14% GTR 15 SET "bgClr=!bColors:~%t1%,1!"
IF %mzOp15% LSS 0  SET "fgClr=!fColors:~%t2%,1!"
IF %mzOp15% GTR 15 SET "fgClr=!fColors:~%t2%,1!"
IF "!badColors!" NEQ "!badColors:%bgClr%%fgClr%=!" (IF !fgClr! EQU 0 (SET bgClr=5) ELSE SET bgClr=0)
SET "mTmp=!walls:~%t3%,1!"
SET "title0=Rebuild: Box#%~1"

REM change color and wall character and exit
IF %~1 LSS 0 (
	SET "mz=!mz:%wall%=%mTmp%!"
	SET "wall=!mTmp!"
	SET "top=!mz:~-%wide%!"
	SET "mazeTop=!wall!!wall!!labelTop!!top!"
	SET "mazeTop=!mazeTop:~0,%wide%!"
	SET "mz=!mazeTop!!mz:~%wide%!
	IF !display! NEQ 0 ( !clear!
		COLOR !bgClr!!fgClr!
		ECHO(!mz!
		%EKO%!msg:~1!
	)
	EXIT /B 0
)

REM clear special characters from maze
SET "mz=!mz:%player%=%hall%!"
SET "mz=!mz:%goal%=%hall%!"
SET "mz=!top!!mz:~%wide%!"
IF !display! NEQ 0 ( !clear!
	COLOR !fgClr!!bgClr!
	ECHO(!mz!
	%EKO%!msg:~1!
)
REM check every character and replace walls with box characters
FOR /L %%? IN (0,%wide%,%size%) DO IF %%? LSS %size% (
	%mazingDebug% SET>%~f0.debug.rebuild.txt
	%BGgrabKey%
	IF NOT EXIST "%keyFile%" CALL :mazing_menu
	IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
	SET /A "et=%%?+wide, pct=%%?*100/size"
	TITLE Maze#!mazeCnt! ^| !title0! ^| !pct!%% ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
	FOR /L %%@ IN (0,1,%wd%) DO (
		SET /A "cp=%%?+%%@, ct=cp+1, nw=cp-wide, sw=cp+wide, ew=cp+1, ww=cp-1, list=-1"
		FOR /F "tokens=1-6" %%A IN ("!nw! !sw! !ew! !ww! !cp! !ct!") DO IF "!mz:~%%E,1!" EQU "!wall!" (
			IF !nw! GEQ 0      IF "!mz:~%%A,1!" NEQ "!hall!" SET /A list+=1
			IF !sw! LSS !size! IF "!mz:~%%B,1!" NEQ "!hall!" SET /A list+=2
			IF !ew! LSS !et!   IF "!mz:~%%C,1!" NEQ "!hall!" SET /A list+=4
			IF !ww! GEQ %%?    IF "!mz:~%%D,1!" NEQ "!hall!" SET /A list+=8
			IF !list! GEQ 0 FOR %%G IN (!list!) DO SET "mz=!mz:~0,%%E!!box%bx%:~%%G,1!!mz:~%%F!"
		)
	)
	IF %%? GTR !b1! SET b1=!size!& SET "mz=!mz:~0,%bgnPos%!!player!!mz:~%b1%!"
	IF %%? GTR !e1! SET e1=!size!& SET "mz=!mz:~0,%endPos%!!goal!!mz:~%e1%!"
	IF !display! GTR 0 (
		IF %%? EQU 0 ( BG.EXE Locate 0 0
			ECHO(!mz:~0,%wide%!
			CALL :mazing_BGcolor)
		BG.EXE Locate 1 0
		ECHO(!mz:~%wide%!
	)
	IF !display! LSS 0 ( !clear!
		ECHO(!mz!
		%EKO%!msg:~1!
	)
)
TITLE Maze#!mazeCnt! ^| !title0! ^| 100%% ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
SET "mazeTop=!mz:~0,%wide%!  !labelTop!"
SET "mazeTop=!mazeTop:~-%wide%!"
SET "mazeTop=!mz:~0,2!!labelTop!!mazeTop!"
SET "mazeTop=!mazeTop:~0,%wide%!"
SET "mz=!mazeTop!!mz:~%wide%!
IF !mzOp11! LSS 0  SET "crumb=!crumbs:~%t4%,1!"
IF !display! NEQ 0 ( !clear!
	COLOR !bgClr!!fgClr!
	ECHO(!mz!
	%EKO%!msg:~1!
)
EXIT /B 0

:mazing_wall_follow fillType
REM %1=write what to maze as backfill? %1<0=walls, %1>=0=halls
REM %1=odd=use walls as crumbs (with solid backfill if negative) on rebuilt mazes
SET /A "curPos=bgnPos, nodes=cols*rows, lbClr=c1=0, nCnt=nTmp=cnt=trail=1, cTmp=wide-4, wTmp=!RANDOM!%%2, mTmp=!RANDOM!%%4+1, p1=!RANDOM!%%wallCnt, ud=%~1%%2"
IF !wTmp! EQU 0 ( REM pick random starting hand
	SET "hand=Left"
	SET "listN=s e n w"
	SET "listW=e n w s"
	SET "listS=n w s e"
	SET "listE=w s e n"
) ELSE (
	SET "hand=Right"
	SET "listN=s w n e"
	SET "listW=e s w n"
	SET "listS=n e s w"
	SET "listE=w n e s"
)
FOR %%A IN (!listN!) DO (
	IF !mTmp! EQU !nTmp! SET "list=!list%%A!"
	SET /A nTmp+=1
)

SET "title0=Wall Follow"
SET "r1= Wall Follow !hand! "
SET "labelBtm=!r1:~0,%cTmp%!"
SET "r1=!mz:~-%wide%!  !labelBtm!"
SET "r1=!r1:~0,2!!labelBtm!!r1:~-%wide%!"
SET "mazeBtm=!r1:~0,%wide%!"
SET "mz=!mz:~0,-%wide%!!mazeBtm!"
SET "bz=!mz!"
SET "fill=!hall!"
SET "tCrumb=!crumb!"
IF "!wall!"=="ÿ" SET "wall=!walls:~%p1%,1!"
IF "!wall!"=="ÿ" SET "wall=!xWall!"
IF %~1 LSS 0 ( SET "fill=!wall!"
	IF !ud! NEQ 0 IF !rebuild! GEQ 6 IF !rebuild! LEQ 9 SET "fill=Û"
	IF !ud! NEQ 0 IF !rebuild! EQU 10 SET "fill=²"
)
IF !ud! NEQ 0 IF !rebuild! GTR 0 ( SET "tCrumb=!wall!"
	SET "t1=!box%rebuild%!"
	FOR /L %%A IN (0,1,15) DO IF "!t1:~%%A,1!" EQU "!tCrumb!" SET "tCrumb=!crumb!"
)

REM set display
IF !display! NEQ 0 ( !clear!
	ECHO(!mz!
	%EKO%!msg:~1!
)
IF !display! GTR 0 CALL :mazing_BGcolor

SET "stack=" & SET "stk="
FOR /L %%? IN (1,1,64) DO IF !curPos! NEQ !endPos! FOR /L %%@ IN (1,1,64) DO IF !curPos! NEQ !endPos! (
	%mazingDebug% SET>%~f0.debug.WallFollow.txt
	%BGgrabKey%
	IF NOT EXIST "%keyFile%" CALL :mazing_menu
	IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
	IF !delay! GTR 0 CALL :mazing_wait !delay!
	%colorShift%
	SET /A "cnt+=1, cTmp=curPos+1, np=curPos-wide*2, sp=curPos+wide*2, ep=curPos+2, wp=curPos-2, wChk=curPos/wide*wide, eChk=wChk+wide, nw=curPos-wide, sw=curPos+wide, ew=curPos+1, ww=curPos-1"
	FOR %%A IN (!list!) DO FOR /F "tokens=1,2" %%B IN ("!%%Aw! !%%Ap!") DO (
		SET "wTmp=!mz:~%%B,1!"
		IF "!wTmp!" EQU "!tCrumb!" SET "wTmp=!hall!"
		IF "!wTmp!" EQU "!hall!" IF %%C GTR !wide! IF %%C LSS !size! (
			SET "cw=%%B"
			SET "newPos=%%C"
			SET "newList=!list%%A!"
			SET "char=!mz:~%%B,1!"
		)
	)
	SET /A wTmp=cw+1, nTmp=newPos+1
	IF "!char!" EQU "!tCrumb!" ( SET /A trail-=1
		SET "stack=!stack:* =!"
		FOR /F "tokens=1-4" %%A IN ("!curPos! !cTmp! !cw! !wTmp!") DO (
			SET "mz=!mz:~0,%%A!!fill!!mz:~%%B!"
			SET "mz=!mz:~0,%%C!!fill!!mz:~%%D!"
			IF !display! GTR 0 ( SET /A "r1=%%A/wide, c1=%%A-r1*wide, r2=%%C/wide, c2=%%C-r2*wide"
				BG.EXE FCPrint !r1! !c1! !bgClr!!ex2Clr! "!fill!"
				BG.EXE FCPrint !r2! !c2! !bgClr!!ex2Clr! "!fill!"
			)	
		)
	) ELSE (
		SET "stack=!newPos! !stack!"
		SET /A "nCnt+=1, pct=nCnt*100/nodes, trail+=1"
		FOR /F "tokens=1-4" %%A IN ("!cw! !wTmp! !newPos! !nTmp!") DO (
			SET "mz=!mz:~0,%%A!!tCrumb!!mz:~%%B!"
			SET "mz=!mz:~0,%%C!!tCrumb!!mz:~%%D!"
			IF !display! GTR 0 ( SET /A "r1=%%A/wide, c1=%%A-r1*wide, r2=%%C/wide, c2=%%C-r2*wide"
				BG.EXE FCPrint !r1! !c1! !bgClr!!exClr! "!tCrumb!"
				BG.EXE FCPrint !r2! !c2! !bgClr!!exClr! "!tCrumb!"
			)
		)
	)
	IF !trail! GTR !far! SET /A far=trail
	SET /A curPos=newPos
	SET "list=!newList!"
	TITLE Maze#!mazeCnt! ^| !title0! ^| !pct!%% n:!nodes!/!nCnt! ^| #!cnt! trail:!trail! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
	IF !display! LSS 0 ( !clear!
		ECHO(!mz!
		%EKO%!msg:~1!
	)
)
IF !curPos! NEQ !endPos! CALL :mazing_failure WallFollow
REM write maze with crumb trail
SET /A "b1=bgnPos+1, e1=endPos+1"
SET "mz=!bz!"
FOR %%A IN (!bgnPos! !stack! !endPos!) DO ( SET /A "t1=%%A+1"
	FOR %%B IN (!t1!) DO SET "mz=!mz:~0,%%A!!crumb!!mz:~%%B!
)
FOR %%A IN (!bgnPos! !stack! !endPos!) DO (
	SET /A "sp=%%A+wide*2, ep=%%A+2, sw=%%A+wide, ew=%%A+1"
	FOR /F "tokens=1-4" %%B IN ("!sp! !sw! !ep! !ew!") DO (
		IF "!mz:~%%B,1!" EQU "!crumb!" IF "!mz:~%%C,1!" EQU "!hall!" SET "stk=!stk!%%C "
		IF "!mz:~%%D,1!" EQU "!crumb!" IF "!mz:~%%E,1!" EQU "!hall!" SET "stk=!stk!%%E "
	)
)
FOR %%A IN (!stk!) DO ( SET /A "t1=%%A+1"
	FOR %%B IN (!t1!) DO (
		SET "mz=!mz:~0,%%A!!crumb!!mz:~%%B!"
	)
)
SET "mz=!mz:~0,%bgnPos%!!player!!mz:~%b1%!"
SET "mz=!mz:~0,%endPos%!!goal!!mz:~%e1%!"
EXIT /B 0

:mazing_dead_filler fillType
REM %1<0=backfill empty halls with walls, %1>=0=clear crumbfill with empty halls
REM %1 mod 3 0=straight sort, 1=reverse sort, 2=random sort
SET /A "dfMode=%~1%%3, nodes=cols*rows, lbClr=nCnt=c1=t1=0, nTmp=cnt=trail=1, cTmp=wide-4, nChk=wide*2, sChk=size-wide*2"
SET "r1= Dead Filler "
SET "labelBtm=!r1:~0,%cTmp%!"
SET "r1=!mz:~-%wide%!  !labelBtm!"
SET "r1=!r1:~0,2!!labelBtm!!r1:~-%wide%!"
SET "mazeTop=!mz:~0,%wide%!"
SET "mazeBtm=!r1:~0,%wide%!"
SET "fix=!crumb!"
SET "fill=!hall!"
IF %~1 LSS 0 (
	IF "!wall!"=="ÿ" SET "wall=Û"
	SET "fix=!hall!"
	SET "fill=!wall!"
) ELSE SET "mz=!mz:%hall%=%crumb%!"
SET "mz=!mazeTop!!mz:~%wide%,-%wide%!!mazeBtm!"
SET "bz=!mz!"
SET "rw0= " & SET "rw1= "
SET "title0=Dead Filler"

REM set display
IF !display! NEQ 0 ( !clear!
	ECHO(!mz!
	%EKO%!msg:~1!
)
IF !display! GTR 0 CALL :mazing_BGcolor

REM create stacks of cell positions for each row, omit start and end
TITLE Maze#!mazeCnt! ^| !title0! sorting nodes, please wait... !TIME: =0!
SET /A cp=np=t1=0, b1=bgnPos+1, e1=endPos+1
FOR /L %%A IN (0,1,16) DO ( SET "np%%A=" ) & ( SET "wp%%A=" )
REM dfMode straight sort
IF !dfMode! EQU 0 FOR /L %%A IN (1,1,%rows%) DO FOR /L %%B IN (1,1,%cols%) DO (
	SET /A "np=wide*%%A*2-wide+%%B*2-1, t1+=1"
	IF !np! NEQ !bgnPos! IF !np! NEQ !endPos! (
		IF !t1! LSS 1500 ( SET "rw0=!rw0!!np! "
		) ELSE SET "rw1=!rw1!!np! "
	)
)
REM reverse sort
IF !dfMode:~-1! EQU 1 FOR /L %%A IN (1,1,%rows%) DO FOR /L %%B IN (1,1,%cols%) DO (
	SET /A "np=wide*%%A*2-wide+%%B*2-1, t1+=1"
	IF !np! NEQ !bgnPos! IF !np! NEQ !endPos! (
		IF !t1! LSS 1500 ( SET "rw1= !np!!rw1!"
		) ELSE SET "rw0= !np!!rw0!"
	)
)
REM random sort
IF !dfMode:~-1! EQU 2 (
	FOR /L %%A IN (1,1,%rows%) DO FOR /L %%B IN (1,1,%cols%) DO (
		SET /A "np=wide*%%A*2-wide+%%B*2-1, t1+=1"
		IF !np! NEQ !bgnPos! IF !np! NEQ !endPos! SET df!t1!=!np!
	)
	FOR /L %%A IN (!t1!,-1,0) DO (
		SET /A "rand=!RANDOM!%%(%%A+1), t1-=1"
		SET /A "t2=df!rand!"
		IF !t1! LSS 1500 ( SET "rw0=!rw0!!t2! "
		) ELSE SET "rw1=!rw1!!t2! "
		SET /A "df!rand!=df%%A"
		SET "df%%A="
	)
)

REM loop through stack looking for cells with only one 'hall'
REM fill it in and remove it from the stack, repeat until no change
FOR /L %%@ IN (1,1,64) DO IF DEFINED t1 ( SET "t1="
	FOR %%A IN (0 1) DO FOR %%B IN (!rw%%A!) DO (
		%mazingDebug% SET>%~f0.debug.DeadFiller.txt
		%BGgrabKey%
		IF NOT EXIST "%keyFile%" CALL :mazing_menu
		IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
		IF !delay! GTR 0 CALL :mazing_wait !delay!
		%colorShift%
		IF !cp! EQU 0 SET /A "cp=%%B"
		SET /A "wp1=cp-wide, wp2=cp+wide, wp4=cp+1, wp8=cp-1, cnt+=1, pow=1"
		SET /A "np1=cp-wide*2, np2=cp+wide*2, np4=cp+2, np8=cp-2, np=cp, cp=wl=0"
		IF !np! LSS !nChk! SET "wp1=0"
		IF !np! GTR !sChk! SET "wp2=0"
		FOR %%C IN (!wp1! !wp2! !wp4! !wp8!) DO (
			IF "!mz:~%%C,1!" EQU "!fix!" SET /A "wl+=pow"
			SET /A "pow*=2"
		)
		FOR %%C IN (!wl!) DO FOR /F "tokens=1-2" %%D IN ("!wp%%C! !np%%C!") DO (
			SET /A "t1=%%D+1, nCnt+=1, pct=nCnt*100/nodes"
			IF %%E NEQ !bgnPos! IF %%E NEQ !endPos! SET /A "cp=%%E"
			FOR /F "tokens=1-3" %%F IN ("!np! !wp4! !t1!") DO (
				SET "mz=!mz:~0,%%F!!fill!!mz:~%%G!"
				SET "mz=!mz:~0,%%D!!fill!!mz:~%%H!"
				SET "rw0=!rw0: %%F = !"
				SET "rw1=!rw1: %%F = !"
			)
			IF !display! GTR 0 (
				SET /A "r1=np/wide, c1=np-r1*wide, r2=!wp%%C!/wide, c2=!wp%%C!-r2*wide"
				BG.EXE FCPrint !r1! !c1! !dfClr! "!fill!"
				BG.EXE FCPrint !r2! !c2! !dfClr! "!fill!"
			)
			IF !display! LSS 0 ( !clear!
				ECHO(!mz!
				%EKO%!msg:~1!
			)
		)
		TITLE Maze#!mazeCnt! ^| !title0! ^| !pct!%% #!cnt! pass#%%@ ^| n:!nodes!/!nCnt!/n!np! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
	)
)
IF DEFINED t1 CALL :mazing_failure DeadFiller
IF !pct! GEQ 99 CALL :mazing_failure DeadFiller
IF %~1 LSS 0 (
	SET "t0= "
	SET "mz=!bz!"
	FOR %%A IN (!bgnPos! !rw0! !rw1! !endPos!) DO ( SET /A "t1=%%A+1"
		FOR %%B IN (!t1!) DO SET "mz=!mz:~0,%%A!!crumb!!mz:~%%B!
	)
	FOR %%A IN (!bgnPos! !rw0! !rw1! !endPos!) DO (
		SET /A "sp=%%A+wide*2, ep=%%A+2, sw=%%A+wide, ew=%%A+1"
		FOR /F "tokens=1-4" %%B IN ("!sp! !sw! !ep! !ew!") DO (
			IF "!mz:~%%B,1!" EQU "!crumb!" IF "!mz:~%%C,1!" EQU "!hall!" SET "t0=!t0!%%C "
			IF "!mz:~%%D,1!" EQU "!crumb!" IF "!mz:~%%E,1!" EQU "!hall!" SET "t0=!t0!%%E "
		)
	)
	FOR %%A IN (!t0!) DO ( SET /A "t1=%%A+1"
		FOR %%B IN (!t1!) DO (
			SET "mz=!mz:~0,%%A!!crumb!!mz:~%%B!"
		)
	)
)
SET "mz=!mz:~0,%bgnPos%!!player!!mz:~%b1%!"
SET "mz=!mz:~0,%endPos%!!goal!!mz:~%e1%!"
EXIT /B 0

:mazing_path_finder fillType
REM %1=length of worms (limit ~30) <0=walls, >0=crumbs, 0=random wall flood
REM %1=odd=backfill/plug with walls (solids if rebuild GEQ 6 LEQ 10)
SET /A "nodes=cols*rows, lbClr=chk=cnt=wormCnt=0, trail=nCnt=1, cTmp=wide-4, pfMode=%~1, lr=%~1%%2, rw=!RANDOM!%%wallCnt"
SET "title0=Path Finder"
SET "r1= Path Finder "
SET "labelBtm=!r1:~0,%cTmp%!"
SET "r1=!mz:~-%wide%!  !labelBtm!"
SET "r1=!r1:~0,2!!labelBtm!!r1:~-%wide%!"
SET "mazeTop=!mz:~0,%wide%!"
SET "mazeBtm=!r1:~0,%wide%!"
SET "mz=!mazeTop!!mz:~%wide%,-%wide%!!mazeBtm!"
SET "bz=!mz!"
SET "fill=!crumb!"
SET "plug=!hall!"
IF !pfMode! EQU 0 SET "fill=!walls:~%rw%,1!"
IF !pfMode! LSS 0 SET "fill=!wall!" & SET /A "pfMode*=-1"
REM IF !pfMode! LSS 0 IF !rebuild! GTR 0 SET "fill=!wall!"
IF "!fill!"=="ÿ" SET "fill=°"
IF !lr! NEQ 0 ( SET "plug=!wall!"
	IF !rebuild! GEQ 1 IF !rebuild! LEQ 10 SET "plug=²")

REM set display
IF !display! NEQ 0 ( !clear!
	ECHO(!mz!
	%EKO%!msg:~1!
) ELSE SET pfMode=0
IF !display! GTR 0 CALL :mazing_BGcolor

SET "pf%bgnPos%=-1"
SET "stack=!bgnPos! "
FOR /L %%? IN (1,1,64) DO IF NOT DEFINED pf%endPos% FOR /L %%@ IN (1,1,64) DO IF NOT DEFINED pf%endPos% (
	SET "newStk="
	SET /A trail+=1
	FOR %%A IN (!stack!) DO ( SET "stack=!stack:* =!"
		%BGgrabKey%
		IF NOT EXIST "%keyFile%" CALL :mazing_menu
		IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
		IF !delay! GTR 0 CALL :mazing_wait !delay!
		%colorShift%
		SET /A "cnt+=1, np=nt=%%A-wide*2, sp=st=%%A+wide*2, ep=et=%%A+2, wp=wt=%%A-2, nw=nq=%%A-wide, sw=sq=%%A+wide, ew=eq=%%A+1, ww=wq=%%A-1, nt+=1, st+=1, et+=1, wt+=1, nq+=1, sq+=1, eq+=1, wq+=1"
		FOR %%B IN (n s e w) DO FOR /F "tokens=1-4" %%C IN ("!%%Bw! !%%Bq! !%%Bp! !%%Bt!") DO (
			%mazingDebug% SET>%~f0.debug.PathFinder.txt
			IF "!mz:~%%C,1!" EQU "!hall!" IF NOT DEFINED pf%%E IF %%E GTR !wide! IF %%E LSS !size! (
				SET /A "nCnt+=1, pct=nCnt*100/nodes"
				SET "mz=!mz:~0,%%C!!fill!!mz:~%%D!"
				IF %%E NEQ !endPos! SET "mz=!mz:~0,%%E!!fill!!mz:~%%F!"
				SET "stack=!stack!%%E "
				SET "pf%%E=%%C %%D %%A !ew!"
				SET "newStk=!newStk!%%C %%E "
				IF !display! GTR 0 (
					SET /A "r1=%%C/wide, c1=%%C-r1*wide, r2=%%E/wide, c2=%%E-r2*wide"
					BG.EXE FCPrint !r1! !c1! !bgClr!!exClr! "!fill!"
					IF %%E NEQ !endPos! BG.EXE FCPrint !r2! !c2! !bgClr!!exClr! "!fill!"
				)
			)
		)
		TITLE Maze#!mazeCnt! ^| !title0! ^| !pct!%% n:!nodes!/!nCnt! ^| #!cnt! trail:!trail! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
	)
	IF !display! LSS 0 ( !clear!
		ECHO(!mz!
		%EKO%!msg:~1!
	)
	IF !pfMode! NEQ 0 ( SET/A wormCnt+=1
		IF !wormCnt! GTR !pfMode! FOR /F "tokens=1* delims=;" %%A IN ("!crmStk!") DO ( SET "crmStk=%%B"
			FOR %%C IN (%%A) DO ( SET/A t1=%%C+1
				FOR %%D IN (!t1!) DO SET "mz=!mz:~0,%%C!!plug!!mz:~%%D!"
				IF !display! GTR 0 ( SET/A "r1=%%C/wide,c1=%%C-r1*wide
					BG.EXE FCPrint !r1! !c1! !bgClr!!exClr! "!plug!"
				)
			)
		)
		SET "crmStk=!crmStk!!newStk:~0,-1!;"
	)
)
IF NOT DEFINED pf%endPos% CALL :mazing_failure PathFinder
SET "mz=!bz!"
SET "pf=!pf%endPos%!"
FOR /L %%@ IN (2,1,!trail!) DO FOR /F "tokens=1-4" %%A IN ("!pf!") DO (
	SET "mz=!mz:~0,%%A!!crumb!!mz:~%%B!"
	IF %%@ LSS !trail! SET "mz=!mz:~0,%%C!!crumb!!mz:~%%D!"
	SET "pf=!pf%%C!"
)
EXIT /B 0

:mazing_bgnPos where
REM %1=place entrance where?
REM 0<=random point, 1=random point on border, 2>=random corner
REM bgnPos=maze entrance position, curPos=current cursor position
SET /A "p1=!RANDOM!%%4"
IF %1 LEQ 0 SET /A "bgnPos=(!RANDOM!%%cols*2+1)+(!RANDOM!%%rows*2+1)*wide"
IF %1 EQU 1 ( SET /A "bgnPos=wide+!RANDOM!%%cols*2+1"
	IF !p1! EQU 1 SET /A "bgnPos=size-wide-!RANDOM!%%cols*2-2"
	IF !p1! EQU 2 SET /A "bgnPos=(!RANDOM!%%rows*2+1)*wide+1"
	IF !p1! EQU 3 SET /A "bgnPos=size-(!RANDOM!%%rows*2+1)*wide-2")
IF %1 GEQ 2 ( SET /A "bgnPos=wide+1"
	IF !p1! EQU 1 SET /A "bgnPos=wide*2-2"
	IF !p1! EQU 2 SET /A "bgnPos=size-wide*2+1"
	IF !p1! EQU 3 SET /A "bgnPos=size-wide-2")
SET /A curPos=bgnPos
EXIT /B 0

:mazing_endPos where
REM %1=place exit where?
REM 0=farthest point, 1=farthest point on border, 2>=farthest corner
SETLOCAL
SET /A "cnt=trail=ep%bgnPos%=0,numNodes=cols*rows"
SET "stack=!bgnPos! "
IF %1 EQU 0 SET title0=Inside
IF %1 EQU 1 SET title0=Border
IF %1 GTR 1 ( SET /A "endPos%1=wide+1, r1=bgnPos/wide, c1=bgnPos-r1*wide"
	IF !r1! LSS !rows! SET /A endPos%1=size-wide*2+1
	IF !c1! LSS !cols! SET /A endPos%1+=wide-3
) ELSE FOR /L %%? IN (1,1,64) DO IF DEFINED stack FOR /L %%@ IN (1,1,64) DO IF DEFINED stack (
	%BGgrabKey%
	IF NOT EXIST "%keyFile%" CALL :mazing_menu
	IF ERRORLEVEL 2 EXIT /B !ERRORLEVEL!
	%colorShift%
	FOR %%A IN (!stack!) DO ( SET "stack=!stack:* =!"   'remove opening spaces
		%mazingDebug% SET>%~f0.debug.EndPos.txt
		SET /A "cnt+=1, pct=cnt*100/numNodes, np=%%A-wide*2, sp=%%A+wide*2, ep=%%A+2, wp=%%A-2, nw=%%A-wide, sw=%%A+wide, ew=%%A+1, ww=%%A-1, wk=%%A/wide*wide, ek=wk+wide-1"
		FOR %%B IN (n s e w) DO FOR /F "tokens=1-2" %%C IN ("!%%Bw! !%%Bp!") DO (
			IF %%D LSS !wide! ( SET "endPos1=%%A"
			) ELSE IF %%D GTR !size! ( SET "endPos1=%%A"
			) ELSE IF %%C EQU !wk! ( SET "endPos1=%%A"
			) ELSE IF %%C EQU !ek! ( SET "endPos1=%%A"
			) ELSE IF "!mz:~%%C,1!" EQU "!hall!" IF NOT DEFINED ep%%D (
				SET "stack=!stack!%%D "
				SET "endPos0=%%D"
				SET "ep%%D=1"
			)
		)
	)
	SET /A trail+=1
	TITLE Maze#!mazeCnt! ^| End Position:!title0! ^| !pct!%% #!cnt! trail:!trail! ^| %titleCS% %titleGK% ^| !title1! !TIME: =0!
)
SET "endPos=!endPos%1!"
ENDLOCAL & SET /A "endPos=%endPos%, trail=%trail%, t1=endPos+1"
SET "mz=!mz:~0,%endPos%!!goal!!mz:~%t1%!"
EXIT /B !ERRORLEVEL!

:timeSince %TIME% [%DATE% [part whole]]
REM input  - hh:mm:ss.cc [Day MM/DD/YYYY [integer integer]]
REM output - [Wwks, ][Dday, ][Hhrs, ][Mmin, ]S.Csec
REM returns time lapsed from %TIME% [%DATE%] to present in TS_ or if given
REM part/whole will return estimate of time remaining to completion in TR_.
REM raw time and day info for given(1) and current(2) are also available.
REM TM1,TM2=# of centiseconds since last midnight.
REM DY1,DY2=# of days since noon on January 1, 4713 BCE (Julian calendar).
REM usage:
REM SET "startTime=%TIME%" or "startTime=%TIME% %DATE%" before event then:
REM CALL :timeSince %startTime%                      - for current elapsed time.
REM CALL :timeSince %startTime% %partCnt% %wholeCnt% - to estimate by count.
REM CALL :timeSince %startTime% %partKb%  %wholeKb%  - to estimate by size.
REM v0.2 2018/08/06

SETLOCAL EnableDelayedExpansion
SET res=
SET inp=%*
SET var=TS_
SET/A p=t=t1=tm1=t2=tm2=d=d1=dy1=d2=dy2=y=z=0
IF "!inp:~1,1!"==":" SET inp=0!inp!
FOR %%@ IN ("!inp!" "!TIME: =0! !DATE!") DO (SET/A p+=1
	FOR /F "tokens=1-10 delims=:./ " %%A IN ("%%~@")DO IF "%%D" NEQ "" (
		SET/A"tm!p!=t!p!=(((1%%A*60)+1%%B)*60+1%%C)*100+1%%D-36610100"
		IF "%%H" NEQ "" (SET/A mm=100%%F%%100,dd=100%%G%%100,yy=10000%%H%%10000
			SET/A"dy!p!=d!p!=!dd!-32075+1461*(!yy!+4800+(!mm!-14)/12)/4+367*(!mm!-2-(!mm!-14)/12*12)/12-3*((!yy!+4900+(!mm!-14)/12)/100)/4")
			IF "%%J" NEQ "" SET/A y=%%I,z=%%J))
IF !t1! GEQ !t2! SET/A t2+=8640000,d2-=1
IF !d1! EQU 0 SET d2=0
SET/A t=t2-t1,d=d2-d1
FOR %%A IN (1 2 3) DO IF !z! GTR 9999999 SET/A y/=10,z/=10
IF !y! LSS 1 SET y=1
IF !z! NEQ 0 SET/A "t=(z-y)*100/y*((d*8640000+t)/100),d=t/8640000,t=t%%8640000"^& SET var=TR_
SET/A w=d/7,d=d%%7,h=t%%8640000/360000,m=t%%360000/6000,s=t%%6000/100,c=t%%100
IF !c! LEQ 9 SET c=0!c!
IF !w! GTR 0 SET "res=!w!wks, "
IF !d! GTR 0 SET "res=!res!!d!day, "
IF !h! GTR 0 SET "res=!res!!h!hrs, "
IF !m! GTR 0 SET "res=!res!!m!min, "
SET res=!res!!s!.!c!sec
(	ENDLOCAL
	SET "%var%=%res%"
	REM SET "tm1=%tm1%"
	REM SET "tm2=%tm2%"
	REM SET "dy1=%dy1%"
	REM SET "dy2=%dy2%"
)
EXIT /B 0

:mazing_init
REM start with clean environment, nothing but the PATH
TITLE %~n0 initializing, please wait... !TIME: =0!
(	FOR /F "tokens=1 delims==" %%A IN ('SET 2^>NUL') DO SET "%%A="
	SET "PATH=%~dp0;%PATH%")

::::::::::::::::::::::::::
:: Start User Variables ::
::::::::::::::::::::::::::
SET "maxCols=63"                'maximum # of columns allowed in menu
SET "minCols=30"                'mainmum # of columns allowed in menu
SET "maxRows=28"                'maximum # of rows allowed in menu
SET "minRows=14"                'minimum # of rows allowed in menu
SET "maxSize=8186"              'maximum # of characters allowed in maze
SET "minSize=1024"              'minimum # of characters allowed in maze
SET "menuKeys=WSAD123H"         'up,down,left,right,continue+resume,quit+restart,abort+exit,help
SET "quitKey=Q"                 'which keypress will interrupt the script/show menu
SET "maxLoop=2147483647"        'maximum number of loops allowed in :mazing_loop
SET "useGrabKey="               'if defined always use :mazing_grabKey instead of BGgrabKey
SET "flashTime=20"              'time interval between flashes at completion of maze
SET "grabKeyFrequency=50"		'target interval (centiseconds) for macro BGgrabKey occurance
SET "shiftFrequency=50"         'target interval (centiseconds) for macro colorShift occurance
REM "pulseFrequency=10"         'multiple of shiftFrequency, pulse lasts 1 'click'
SET "numOfBoxes=10"             '# of different boxes for Rebuilder, #11-12 require 'legacy console'
SET "mazeFile=%~n0.mazes.nfo"   'file to save created mazes, no file if undefined
SET "solvFile=%~n0.mazes.nfo"   'file to save solved mazes, no file if undefined
REM default character strings for random generation
REM these seem safe for non-legacy Win10 console
SET "walls=##%%%%&&0889BDGMQQWYZ@@¬¬««²²ÛÛáãäèéï÷ÿÿ"
SET "halls= "                   'space is the only hall character that seems to work well
SET "crumbs=°°±±øúþþx"          'chosen for being small and centered
SET "players=êŽS"          'chosen because they look like a player or entrance
SET "goals=F$X¨û"            'chosen because they look like an exit or goal
SET "backColors=0123456"        'color list of hex numbers for random background selection
SET "foreColors=789ABCDEF"      'color list of hex numbers for random foreground selection
REM these color combos will be avoided by setting the bgClr=0 (or 5 if fgClr=0)
SET "badColors=15 51 23 32 29 92 2C C2 3C C3 4D D4 6A A6 7B B7 89 98 8C C8 9C C9 AB BA EF FE"


::::::::::::::::::::::::
:: End User Variables ::
::::::::::::::::::::::::

SET "totalTime=%TIME% %DATE%" 'script startTime for :timeSince function
SET "keyFile=%~n0.key"        'filename used by :mazing_grabKey subroutine
SET "iniFile=%~n0.ini"        'file for setting user variables
SET "cfgFile=%~n0.cfg"        'file for saving mzOp# values

REM set code page, set constants
MODE CON CP SELECT=437 >NUL%=       'IBM-PC codepage required for box characters, if no rebuild, ascii should be OK =%
SET "display=-1"                    '0=no display/log only, -1=display, 1=display+color using BG.EXE
SET "version=0.3"                   'current version # for Mazing.cmd
SET "EKO=<NUL SET/P="               'display to screen without CR/LF, faster than the executables
SET "clear=CLS"                     'will be replaced by BG or CursorPos if available
SET "delay=0"                       'delay in centiseconds to slow process for viewing
SET "title0=Mazing Menu"            'string showing current operation in TITLE
SET "title1='%quitKey%' Quit/Menu"  'notice displayed at the end of TITLE
SET "hex=0123456789ABCDEF"          'hexadecimal table for COLOR command
SET "xWalls=#@Û"                    'walls used to display 'ÿ' (invisible wall)
SET "mazingDebug=REM "              'clear or comment this to output SET.txt for each function

REM read character list from last line of Mazing.cmd or Mazing.bak.ini
SET "t1=%~f0"
IF EXIST "%~dpn0.bak.ini" SET "t1=%~dpn0.bak.ini"
FOR /F %%A IN ('TYPE "%t1%"^|FIND "" /v /c') DO SET /A t2=%%A-1
FOR /F "usebackq skip=%t2%" %%A IN ("%t1%") DO SET "chars=%%A"

REM clear key file, create/read ini file and command line options
DEL /F /Q /A "%keyFile%" >NUL 2>&1
IF EXIST "%iniFile%" ( FOR /F "skip=2 tokens=1* delims=:=" %%A IN ('FIND /V ";" "%iniFile%"') DO SET "%%~A=%%~B"
) ELSE ( ECHO ; %~nx0 v%version% variable=value or variable:value, lines containing ';' are ignored
	ECHO.
	FOR %%A IN (maxCols minCols maxRows minRows maxSize minSize menuKeys quitKey maxLoop useGrabKey flashTime shiftFrequency grabKeyFrequency mazeFile solvFile walls halls crumbs players goals backColors foreColors badColors) DO ECHO(%%A=!%%A!
	ECHO.
	ECHO ; larger maximums for larger displays, default is max for 1024x768
	ECHO ;maxCols=118
	ECHO ;maxRows=38
	ECHO.
	ECHO ; many of the characters below will not work in Win10 without 'properties/legacy console' mode enabled
	ECHO ;walls="##%%%%&&0889BDGMQQWYZ@@¬¬««²²ÛÛáãäèéï÷ÿÿ"
	ECHO ;crumbs="°°±±øúþþx"
	ECHO ;players="êŽS"
	ECHO ;goals="?$X¨û"
	ECHO ;numOfBoxes=12
	ECHO.
	ECHO ; uncomment the following line to throw out debug.txt for all functions
	ECHO ;mazingDebug=
	ECHO.
	) > "%iniFile%"
FOR %%A IN (%*) DO FOR /F "tokens=1* delims=:=" %%B IN ("%%~A") DO SET "%%~B=%%~C"

REM discover the length of each character string
FOR %%A IN (wall hall crumb player goal foreColor backColor char) DO ( SET %%ACnt=0& SET "t1=!%%As!0"
	FOR %%B IN (128 64 32 16 8 4 2 1) DO IF "!t1:~%%B,1!" NEQ "" SET /A %%ACnt+=%%B & SET "t1=!t1:~%%B!")
SET /A charCnt-=1%=               'adjust for zero-indexing =%

REM gather user variables
SET/A nobRB=numOfBoxes+1,nobRW=numOfBoxes+2,fColorCnt=foreColorCnt,bColorCnt=backColorCnt
SET "badColors=!badColors! 00 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF"
SET "bColors=!backColors!"
SET "fColors=!foreColors!"

REM box characters for rebuild
REM
REM       2
REM   6 C E C A
REM   3   3   3       +1
REM 4 7 C F C B 8   +8 0 +4
REM   3   3   3       +2
REM   5 C D C 9
REM       1

REM  "box?=123456789ABCDEF" no zero, because all walls are connected
SET "box0=|||-\/+-/\+-+++"
SET "box1=|||-\/+-/\+-+++"
SET "box2=³³³ÄÀÚÃÄÙ¿´ÄÁÂÅ"
SET "box3=ºººÍÈÉÌÍ¼»¹ÍÊËÎ"
SET "box4=ºººÄÓÖÇÄ½·¶ÄÐÒ×"
SET "box5=³³³ÍÔÕÆÍ¾¸µÍÏÑØ"
SET "box6=ÞÝÛÜßÜÛßßÜÛÛÛÛÛ"
SET "box7=ÝÞÛßßÜÛÜßÜÛÛÛÛÛ"
SET "box8=ßÜÛÞÛÛÛÝÛÛÛÛÛÛÛ"
SET "box9=ÛÛÛÛÛÛÛÛÛÛÛ"
SET "box10=²²²²²²²²²²²"
REM last 2 boxes will not work in Win10 without 'legacy console' mode enabled
SET "box11=³ÀÚÃ!chars:~20,1!Ù¿´ÄÁÂÅ"
SET "box12=|\/+!chars:~20,1!/\+-+++"

REM box characters for menu
REM @=3 {=6 [=5 }=9 ]=A $=C
REM  "mBox?=012345"
SET "mBox_=@{[}]$"
SET "mBox0=|\//\-"
SET "mBox1=³ÀÚÙ¿Ä"
SET "mBox2=ºÈÉ¼»Í"
SET "mBox3=ºÓÖ½·Ä"
SET "mBox4=³ÔÕ¾¸Í"
SET "mBox5=ÛßÜßÜÛ"
SET "mBox6=ÛÛÛÛÛÛ"
SET "mBox7=²²²²²²"

REM main menu, %version%=3 chars, @ { } [ ] $ are reserved
SET "mrk=>> " 'menu selection marker
SET mzMenu=  [$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$]  ^
  @                                                      @  ^
  @  Mazing.cmd - WinNT Maze Generator and Solver  v%version%  @  ^
  @                                                      @  ^
  @ [$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$] @  ^
  @ @                                                  @ @  ^
  @ @   Maze Generation Algorithm       :0:  @ @  ^
  @ @   Maze Solving Algorithm          :1:  @ @  ^
  @ @   Select Entrance/Exit Point      :2:  @ @  ^
  @ @   Width in Vertical Columns       :3:  @ @  ^
  @ @   Height in Horizontal Rows       :4:  @ @  ^
  @ @   Stack Size/Type/Wall Setting    :5:  @ @  ^
  @ @   Node Selection %%Bias            :6:  @ @  ^
  @ @   Node Direction %%Bias            :7:  @ @  ^
  @ @   Rebuild Box                     :8:  @ @  ^
  @ @   Solver Display Settings         :9:  @ @  ^
  @ @   Wall Character                  :10:  @ @  ^
  @ @   Crumb/Trail Character           :11:  @ @  ^
  @ @   Start/Entrance Character        :12:  @ @  ^
  @ @   Finish/Exit Character           :13:  @ @  ^
  @ @   Background Color                :14:  @ @  ^
  @ @   Foreground Color                :15:  @ @  ^
  @ @   Background Color Shift          :16:  @ @  ^
  @ @   Foreground Color Shift          :17:  @ @  ^
  @ @   Black ^& White Pulse             :18:  @ @  ^
  @ @   Program Delay                   :19:  @ @  ^
  @ @   Console Display Type            :20:  @ @  ^
  @ @                                                  @ @  ^
  @ @  :A:=  :B:=   :C:=Resume/Restart/Exit  :D:=Help  @ @  ^
  @ {$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$} @  ^
  @                                                      @  ^
  @                                                      @  ^
  @                                                      @  ^
  {$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$} 

REM mWide,mHigh=menu WxH, opCnt=#of menu items-1, opSize=length of option text, orgPos=default position in menu, mt#=mazingTemp variables
REM opSize=string length of menu items to be injected into %mzMenu%, orgPos=position in %mzMenu% for 1st menu item
REM mzOp#P#=menu position for option titles, for retitling options
SET /A mWide=60,mHigh=36,mSize=mWide*mHigh,opSize=13,orgPos=400,mt0=mt1=mt2=mt3=mt4=mt5=-1,opCnt=mCh=csTrg=csCnt=pCnt=gkCnt=gkTrg=mazeCnt=totalCnt=loopCnt=fstClr=hkMax=gtMax=kaMax=w1Max=w2Max=0
SET /A mzOp5P1=mzOp5P2=668,mzOp5P2+=28,mzOp6P1=mzOp6P2=728,mzOp6P2+=28,mzOp8P1=mzOp8P2=860,mzOp8P2+=15,mzOp9P1=mzOp9P2=908,mzOp9P2+=28,msgP1=msgP2=1865,msgP2+=50

REM load arrays for menu display, user variables, and maximum size for menuOps
FOR %%A IN ("Random" "BackTracker" "Hunt & Kill" "Growing Tree" "Wall Division" "Eller's Algo" "Prim's Algo" "Kruskals Algo" "Wilson's Algo") DO SET "mzOp0[!mt0!]=%%~A" & SET /A mt0+=1
FOR %%A IN ("Random" "Solve Off" "Wall Follow" "Dead Filler" "Path Finder") DO SET "mzOp1[!mt1!]=%%~A" & SET /A mt1+=1
FOR %%A IN (Random Inside Border Corner) DO FOR %%B IN (Random Inside Border Corner) DO SET "mzOp2[!mt2!]=%%B/%%A" & SET /A mt2+=1
FOR %%A IN ("Stack Size/Type/Wall Setting" "Unused by BackTracker       " "Stack Type LIFO/FIFO        " "Stack Type + List Size      " "Placement of Wall Openings  " "Unused by Eller's Algorithm " "Unused by Prim's Algorithm  "  "Unused by Kruskals Algorithm" "#addEntry / Display Settings") DO SET "mzOp5[!mt3!]=%%~A" & SET /A mt3+=1
FOR %%A IN ("Node Selection %%Bias        " "Unused by BackTracker       " "Node Selection %%Bias        " "Node Selection %%Bias        " "Order of Iterative Stack    " "Unused by Eller's Algorithm " "Unused by Prim's Algorithm  " "Unused by Kruskals Algorithm" "Length of 1st Random Walk   ") DO SET "mzOp6[!mt4!]=%%~A" & SET /A mt4+=1
FOR %%A IN ("Solver Display Settings     " "Solvers Currently Inactive  " "<0=BackFill odd=Wall Crumbs " "<0=BackFill >0=Crumb Clear  " "<0=Walls >0=Crumbs 0=Flood  ") DO SET "mzOp9[!mt5!]=%%~A" & SET /A mt5+=1
FOR %%A IN (7 3 14 !maxCols! !maxRows! 24 101 100 !nobRW! 60 !charCnt! !charCnt! !charCnt! !charCnt! 16 16 6000 6000 40 101 1) DO SET /A maxOp!opCnt!=%%A,opCnt+=1
SET /A opCnt-=1
FOR /L %%A IN (0,1,%opCnt%) DO SET mzOp%%A=-1& SET "mView%%A=Random       "%= 'mzOp#=menu values, mView#=menu option display, -1=Random =%
SET "mView2=Random/Random"
SET "mView19=Delay Off    "
SET "mView20=16 Color     "
SET "mzOp19=0"
SET mt3=
REM messages shown at the bottom of the menu for each option chosen
SET "mMsg0=generate perfect maze with 1 path for any 2 points"
SET "mMsg1= then find the unique solution for generated maze "
SET "mMsg2=entrance is random,exit is furthest possible point"
SET "mMsg3=  maze width=# of columns, character width=W*2+1  "
SET "mMsg4=  maze height=# of rows, character height=H*2+1   "
SET "mMsg5= stack/wall setting, different for each generator "
SET "mMsg6=    0=always random, 50=even, 100=always stack    "
SET "mMsg7=  0=most vertical, 50=even, 100=most horizontal   "
SET "mMsg8= rebuild single character maze to box characters  "
SET "mMsg9= display settings for solvers, different for each "
SET "mMsg10=        single character to use for walls         "
SET "mMsg11=     single character to use for crumbs/trail     "
SET "mMsg12=    single character to use for start/entrance    "
SET "mMsg13=     single character to use for finish/exit      "
SET "mMsg14=   hexadecimal background color, remains static   "
SET "mMsg15=   hexadecimal foreground color, remains static   "
SET "mMsg16=     time interval for background color shift     "
SET "mMsg17=     time interval for foreground color shift     "
SET "mMsg18=      time interval for black & white pulse       "
SET "mMsg19=   # of centisecond to delay for better viewing   "
SET "mMsg20=   native 16 color, BG.EXE color, or no display   "

REM arrays to allow multiple messages for any option, keyed to mzOp#
SET "mMsg5[-1]=%mMsg5%"
SET "mMsg5[0]=  setting is not used by Depth-First BackTracker  "
SET "mMsg5[1]=    stack direction setting <0=FIFO, else LIFO    "
SET "mMsg5[2]=   list size+direction 0=all, >0=LIFO, <0=FIFO    "
SET "mMsg5[3]=wall open 0=NW, 1=SE, 2=NW/SE, 3=center, 4+=random"
SET "mMsg5[4]=     setting is not used by Eller's Algorithm     "
SET "mMsg5[5]=     setting is not used by Prim's Algorithm      "
SET "mMsg5[6]=    setting is not used by Kruskal's Algorithm    "
SET "mMsg5[7]= odd=altCrumbs mod3=all crumbs/halls <0=crumbMaze "

SET "mMsg6[-1]=%mMsg6%"
SET "mMsg6[0]=%mMsg5[0]%"
SET "mMsg6[1]=%mMsg6%"
SET "mMsg6[2]=%mMsg6%"
SET "mMsg6[3]=    stack order 0-7=static pre-sets, 8+=random    "
SET "mMsg6[4]=%mMsg5[4]%"
SET "mMsg6[5]=%mMsg5[5]%"
SET "mMsg6[6]=%mMsg5[6]%"
SET "mMsg6[7]=required 1st walk length 1-11%% #nodes, 0=addEntry "

SET "mMsg9[-1]=%mMsg9%"
SET "mMsg9[0]=        all solvers are currently inactive        "
SET "mMsg9[1]=  <0=backfill with walls odd=use walls as crumbs  "
SET "mMsg9[2]= <0=backfill >0=crumb clear mod3=sorting options  "
SET "mMsg9[3]= wormSize <0=walls >0=crumbs 0=flood odd=backfill "

REM run config file as batch file or set firstRun
IF EXIST "!cfgFile!" ( COPY /Y "!cfgFile!" "!cfgFile!.cmd" >NUL
	CALL "!cfgFile!.cmd"
	DEL /Q /F /A "!cfgFile!.cmd"
	FOR /L %%A IN (0,1,%opCnt%) DO SET mCh=%%A& CALL :mazing_menu_cfg init
	SET/A mCh=saveCh
	SET "tMenu=") ELSE SET firstRun=1

REM read logFile for mazeCount
IF EXIST "%mazeFile%" FOR /F "skip=2 delims=stndrh " %%A IN ('FIND "maze" "%mazeFile%"') DO SET/A mazeCnt=totalCnt=%%A

REM set macros
(SET \n=^^^
%= This defines an escaped Line Feed - DO NOT ALTER =%
)
SET "POZ=FOR %%# IN (1 2)DO IF %%#==2 (PAUSE>NUL&ECHO.)ELSE <NUL SET/P="
SET colorShift=IF ^^^!csCnt^^^! LSS ^^^!csTrg^^^! (SET/A csCnt+=1%\n%
)ELSE (SET/A pCnt+=1,csCnt=0%\n%
	FOR /F "tokens=1-4 delims=:.," %%W IN ("^!TIME: =0^!")DO (%\n%
		SET/A "BGtime=FGtime=(((1%%W*60)+1%%X)*60+1%%Y)*100+1%%Z-36610100,clrF=BGtime-csLast,bgr=^!RANDOM^!%%bColorCnt,fgr=^!RANDOM^!%%fColorCnt"%\n%
		IF ^^^!clrF^^^! LSS ^^^!shiftFrequency^^^! (SET/A csTrg+=1) ELSE IF ^^^!csTrg^^^! GTR 0 SET/A csTrg-=1%\n%
		IF ^^^!csBtm^^^! GTR 0 (IF NOT DEFINED BGstart SET/A BGstart=BGend=BGtime,BGend+=csBtm%\n%
			IF ^^^!BGtime^^^! LSS ^^^!BGstart^^^! SET/A BGtime+=8640000%\n%
			IF ^^^!BGtime^^^! GEQ ^^^!BGend^^^! (SET BGstart=%\n%
				FOR %%X IN (^^^!bgr^^^!)DO SET bgClr=^^^!bColors:~%%X,1^^^!%\n%
				SET bgr=-1))%\n%
		IF ^^^!csFtm^^^! GTR 0 (IF NOT DEFINED FGstart SET/A FGstart=FGend=FGtime,FGend+=csFtm%\n%
			IF ^^^!FGtime^^^! LSS ^^^!FGstart^^^! SET/A FGtime+=8640000%\n%
			IF ^^^!FGtime^^^! GEQ ^^^!FGend^^^! (SET FGstart=%\n%
				FOR %%X IN (^^^!fgr^^^!)DO SET fgClr=^^^!fColors:~%%X,1^^^!%\n%
				SET bgr=-1))%\n%
		IF ^^^!pulse^^^! GTR 0 (IF ^^^!pCnt^^^! EQU ^^^!pulse^^^! (SET bgr=0%\n%
				IF ^^^!bgClr^^^! EQU 0 (COLOR 70) ELSE COLOR 0F)%\n%
			IF ^^^!pCnt^^^! GTR ^^^!pulse^^^! SET pCnt=0^& SET bgr=-1)%\n%
		IF ^^^!bgr^^^! LSS 0 FOR %%[ IN (^^^!bgClr^^^!^^^!fgClr^^^!)DO (%\n%
			IF "^!badColors^!" NEQ "^!badColors:%%[=^!" (IF ^^^!fgClr^^^! EQU 0 (SET bgClr=5) ELSE SET bgClr=0)%\n%
			COLOR ^^^!bgClr^^^!^^^!fgClr^^^!%\n%
			IF ^^^!display^^^! GTR 0 CALL :mazing_BGcolor)%\n%
		SET csLast=^^^!BGtime^^^!))

%mazingDebug% SET>%~f0.debug.init.txt

REM use CursorPos or BG if found in path
CursorPos.exe >NUL 2>&1
IF %ERRORLEVEL% NEQ 9009 SET clear=CursorPos.exe 0 0
BG.EXE >NUL 2>&1
IF %ERRORLEVEL% EQU 9009 EXIT /B 0

REM BG.EXE found
BG.EXE Cursor 0
SET clear=BG.EXE Locate 0 0
IF DEFINED useGrabKey EXIT /B 0

REM get ASCII value of quitKey, find upper/lower, set macro, 113=q
SET t1=113
CALL :chr "!quitKey!" bgKey
IF !bgKey! GEQ 65 IF !bgKey! LEQ 90   SET /A t1=bgKey+32
IF !bgKey! GEQ 97 IF !bgKey! LEQ 122  SET /A t1=bgKey-32
SET BGgrabKey=IF ^^^!gkCnt^^^! LSS ^^^!gkTrg^^^! (SET/A gkCnt+=1%\n%
)ELSE (SET gkCnt=0%\n%
	FOR /F "tokens=1-4 delims=:.," %%W IN ("^!TIME: =0^!")DO SET/A "GKtime=(((1%%W*60)+1%%X)*60+1%%Y)*100+1%%Z-36610100,gtkF=GKtime-gkLast"%\n%
	IF ^^^!gtkF^^^! LSS ^^^!grabKeyFrequency^^^! (SET/A gkTrg+=1) ELSE IF ^^^!gkTrg^^^! GTR 0 SET/A gkTrg-=1%\n%
	SET gkLast=^^^!GKtime^^^!%\n%
	BG.EXE LastKbd%\n%
	IF ^^^!ERRORLEVEL^^^!==%bgKey% DEL/Q/A "^!keyFile^!"%\n%
	IF ^^^!ERRORLEVEL^^^!==%t1% DEL/Q/A "^!keyFile^!"%\n%
	CALL )

SET "titleGK=gk:^!gkTrg^!"

%mazingDebug% SET>%~f0.debug.init.txt

EXIT /B 0

REM returns the ASCII value of single/1st character of string "character"
REM decimal value placed in [variable] (if supplied) and in ERRORLEVEL
:CHR "character" [variable]
FOR %%x IN (" =32" "!=33" ""=34" "#=35" "$=36" "%%=37" "^&=38" "'=39" 
	"(=40" ")=41" "*=42" "+=43" ",=44" "-=45" ".=46" "/=47" 
	"0=48" "1=49" "2=50" "3=51" "4=52" "5=53" "6=54" "7=55" 
	"8=56" "9=57" ":=58" ";=59" "<=60" "==61" ">=62" "?=63" 
	"@=64" "A=65" "B=66" "C=67" "D=68" "E=69" "F=70" "G=71" 
	"H=72" "I=73" "J=74" "K=75" "L=76" "M=77" "N=78" "O=79" 
	"P=80" "Q=81" "R=82" "S=83" "T=84" "U=85" "V=86" "W=87" 
	"X=88" "Y=89" "Z=90" "[=91" "\=92" "]=93" "^=94" "_=95" 
	"`=96" "a=97" "b=98" "c=99" "d=100" "e=101" "f=102" "g=103"
	"h=104" "i=105" "j=106" "k=107" "l=108" "m=109" "n=110" "o=111" 
	"p=112" "q=113" "r=114" "s=115" "t=116" "u=117" "v=118" "w=119" 
	"x=120" "y=121" "z=122" "{=123" "|=124" "}=125" "~=126") DO (
	FOR /F "tokens=1-2 delims==" %%y IN ("%%~x") DO (
		IF "%~1"=="%%~y" (
			IF NOT "%~2"=="" SET %~2=%%~z
			EXIT /B %%~z
		)
	)
)
EXIT /B 256

:mazing_failure
ECHO(%1 with Maze#%mazeCnt% at %TIME: =0% on %DATE% >>"%~f0.Failure.txt"
SET>>"%~f0.Failure.txt"
ECHO(_______________________________________________________________________________>>"%~f0.Failure.txt"
EXIT /B 0

:makeBG [target\folder] [noExpand]
REM ErrorLevel: 0=success, 1=no CertUtil, install Administration Tools
FOR /F "tokens=3-12" %%A IN ('Expand') DO (
	SETLOCAL EnableExtensions EnableDelayedExpansion
	SET "fn=bg.exe.cab"
	IF "%~1"=="" (SET "tf=%~dp0") ELSE SET "tf=%~1" & MD "%~1"
	IF "!tf:~-1!"=="\" SET "tf=!tf:~0,-1!"
	CertUtil -decode -f "%~f0" "%~dp0!fn!"
	IF !ERRORLEVEL!==9009 ENDLOCAL & EXIT /B 1
	IF "%~2"=="" (SET /A "ev=%%J%%I%%H%%G%%F%%E%%D%%C%%B%%A"
		IF !ev! GEQ 6 (Expand -R "%~dp0!fn!" -F:* "!tf!"
		) ELSE Extract /Y /E /L "!tf!" "%~dp0!fn!"
		IF !ERRORLEVEL!==9009 START "" /MIN /WAIT Extrac32 /Y /E /L "!tf!" "%~dp0!fn!"
		IF !ERRORLEVEL!==0 DEL /F /A "%~dp0!fn!")
	MOVE /Y "%~dp0!fn!" "!tf!" & RD "%~1"
	ENDLOCAL & EXIT /B 0) >NUL 2>&1

-----BEGIN CERTIFICATE-----
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
FyYyWEnEzOlbu2PKX7alp8JSKnDaRlzkn9J8Hb/nfvoSVjwOBqlW5idGpYJ+ZnBb
cM0yeu74T2BsFMcoJEf8tmkTOs452PZWJvbmxk/qpqTKa9oPbdBt5AvFmFrenQOe
HnzLxJGdUDCxi1VSObREUy6DwWOzDlUbrAwksDdkyX+MUC9x1aFVK+RAT9ZaSheL
vELTLME+i+hZ66ZybGux7Jr0Web4R4lDYHuNrLkRNpbLbEuRmnYMzQxtE/6J+3uM
giYsksJq20r3JypXY+MjG2or7ikUjRUQH7tticvFpb1XmuyqDM3orFREktHzVbQJ
OJSZ7CZSf15OMxNNjo8TSo4SlIR0aSbvsupqOdz+VvD6mb7dVr6I9gZIqFhz2VAE
5nM5hyJsclZK/cel1XGYOob2xYqydd++sWP7unKP1dR9A/S+Nd3x4nXUhx3ZYdx8
NGzQP0/ulh7Me2hoc3eeBqOd9Yvi+1j8ppwqV4n60b2JhUUYKgYle3eMdjlPcrl8
nRTxxBpXBfP5logUInZr77aeI12eD5oxz6yVOT8Aar2B6a5ctrWvEFtK3sd1zOpg
YczwyaxsSoh1wDWA1oYoK2wzgc0zts8GDlzOuF4dHbqudkIbaEVmQhAaivmMxCSS
l97XQW2I1rUrg19HviYAHe78A2UNGZ84vH4zFDyvq2YSHEQmUdFFA5/yXZUntrva
RDt8wXOzHBvygpnJj0DepdpachmIYUjyejfFOYQfP57C4VnZDjqk2FBZF8sOEZaW
/r/zhnSucpcsXc1FqkgOp88lsXkpCslJaamWaqvE/3c+Yf+pHPGeGo9/4nU8acun
o+qpVdFUa8s6lF/K3ZdyvAj9Q4Ihbu6vfSIqX/0yrwQZbwshbUudiLt0Ken24PJP
0dDVZG494n82bJsm5XSWmzXfFPUkL06Mr3ugnmNHplYfIdlEzNWlIdD7M6yZsqS6
lGzeWnOTZjDnfbWULTMJphJ6DRrxQKgRr00qQygeivZccsc5yoec2HHD3yCyYvYQ
XKn2oWrJJ4ctWTV7nQjFZ0X7ddqhPuNR1TiT+usEo8ofD9XIJnlPLjl3krnWrH2a
t7f/alpJbfuUg7ewpTcLh4sbm5ORpcvWnTtZy/ysor2k0t+5XXJ5aswpyloWvftS
Jt1DlJZP28e7bbeZXL83LncvDe/cv57umvfNObqdTsCB1tz3v+/zu//cdOuvHzrw
gx/oeGK/evP66N9L/cKHn+l8v6/2E3W6yiXjVS47Ss2dz3zaLPXRsf4YttcZ+uQP
++2PjMnRMXc8OVSkdV88lQ==
-----END CERTIFICATE-----

BG v3.9 se (unicode)

BG.EXE is a tool for print text color in cmd.exe. It accepts regular
expressions for print ascii characters. It also have useful functions.

Notice: This version fixes a problem happened on windows 7 sp1 with the function font.

::::: Parameters :::::

Kbd
::mazing_wait until you press any key, and returns the ascii code.
::If an extended key was pressed, returns the second code plus 256.
::Example. If you pressed the up arrow (224, 72) returns 327 (72+256).

LastKbd
::If any key was pressed, returns the ascii code, else return 0.
::If the key pressed is extended, it returns the second code plus 256.
::Example. If you pressed the up arrow (224, 72) returns 327 (72+256).

Mouse
::mazing_wait until you press primary button into console area.
::When you press a valid button of mouse print: rowNumber colNumber (both 0 index based).
::Also, is returned a number, where you can get the same info:
::Set /A "mouseRow=%ErrorLevel% >> 0x10 , mouseCol=%ErrorLevel% & 0xFFFF"

DateTime
::Print eight numbers, separated by a space, that corresponds to the current:
::DayOfWeek Year Month Day Hour Minute Second Milliseconds
::
::DayOfWeek value is from 0 to 6. 0 is Sunday, 1 is Monday, ..., 6 is Saturday
::Year value is from 1601 to 30827
::Month value is from 1 to 12
::Day value is from 1 to 31
::Hour value is from 0 to 23
::Minute value is from 0 to 59
::Second value is from 0 to 59
::Milliseconds value is from 0 to 999

Cursor 0 | 1 | 25 | 50 | 100
::hide or show cursor of keyboard or change the size.
::0 hide
::1 show
::25 small size
::50 medium size
::100 large size

Font 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
::change the size of font to terminal font according this next table:
:: index    size
:: 0        4x6
:: 1        6x8
:: 2        8x8
:: 3        16x8
:: 4        5x12
:: 5        7x12
:: 6        8x12
:: 7        16x12
:: 8        12x16
:: 9        10x18

Sleep milliseconds
::do a wait or sleep in milliseconds. milliseconds should be greater than 0.

Locate row column
::locate the position of cursor in row and column specified (both 0 index based).
::if row is less than 0, is interpreted as 0.
::if row is greater than the max row (in the console screen buffer), is interpreted as the max row.
::if column is less than 0, is interpreted as 0.
::if column is greater than the max row (in the console screen buffer), is interpreted as the max row.

Print text
::print text without new line to end. The text can use oem escape sequences.
::please see the regular expressions in down.

Print color text ...
::print text in HEXADECIMAL color without new line to end. You can repeat arguments.
::the text recognize the next oem escape sequences:
\n print a newline
\\ print \
\Number  HEXADECIMAL ascii number code from 00 to FF.
Example: \01 is face character
Example: \41 is A
Note 2: You can repeat arguments.
Example: BG.EXE Print A "Text in color A" B "Text in color B"

FCPrint row column [color text ...]
::begin printing of colored text in the row and col (zero index based). The column is fixed.
::row and column can be outside the console screen buffer limits.

Play soundfile.wav [ntimes]
::play soundfile.wav from begin to the end
::if ntimes is specified the play is repeated the number of times specified.
::(this function is different from the utility sound.exe where the second parameter correspond to seconds.)

::::: Colours :::::
[background]foreground
colours values is a one hexadecimal (0123456789ABCDEF) digit for each concept.

0 = Black
1 = Blue
2 = Green
3 = Aqua
4 = Red
5 = Purple
6 = Yellow
7 = White
8 = Gray
9 = Light Blue
A = Light Green
B = Light Aqua
C = Light Red
D = Light Purple
E = Light Yellow
F = Bright White

:: these characters must remain the last line of the script - DO NOT REMOVE!
"#$%&'()+,-./0123456789:;<>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ¡¢£¤¥¦§¨«¬­®¯°±²Ûàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
