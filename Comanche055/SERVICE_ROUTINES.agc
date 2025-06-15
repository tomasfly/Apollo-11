# Copyright:    Public domain.
# Filename:     SERVICE_ROUTINES.agc
# Purpose:      Part of the source code for Comanche, build 055. It
#               is part of the source code for the Command Module's
#               (CM) Apollo Guidance Computer (AGC), Apollo 11.
# Assembler:    yaYUL
# Reference:    pp. 1485-1492
# Contact:      Ron Burkey <info@sandroid.org>
# Website:      http://www.ibiblio.org/apollo.
# Mod history:  2009-05-07 RSB	Adapted from Colossus249 file of the same
#				name, and page images. Corrected various
#				typos in the transcription of program
#				comments, and these should be back-ported
#				to Colossus249.
#               2024-03-XX     Enhanced error handling and documentation
#
# The contents of the "Comanche055" files, in general, are transcribed
# from scanned documents.
#
#       Assemble revision 055 of AGC program Comanche by NASA
#       2021113-051.  April 1, 1969.
#
#       This AGC program shall also be referred to as Colossus 2A
#
#       Prepared by
#                       Massachusetts Institute of Technology
#                       75 Cambridge Parkway
#                       Cambridge, Massachusetts
#
#       under NASA contract NAS 9-4065.
#
# Refer directly to the online document mentioned above for further
# information.  Please report any errors to info@sandroid.org.

# Page 1485
# SERVICE ROUTINES MODULE
# This module provides core service routines for the AGC.
#
# Key Features:
# - Flag word manipulation
# - Interrupt handling
# - Job scheduling and timing
# - Memory management
#
# Service Categories:
# 1. Flag Operations (UPFLAG, DOWNFLAG)
# 2. Job Control (DELAYJOB)
# 3. Memory Management (VAC5STOR)
# 4. Interrupt Processing

		BLOCK	3
		SETLOC	FFTAG6
		BANK
		COUNT	03/FLAG

# UPENT2 - Flag Word Update Entry Point
# Updates a specified flag word with new bit information
# Input: L register contains flag word index and bit information
# Output: Updated flag word in memory
UPENT2		TS	L		# Get flag word index
		MASK	OCT7		# Extract index bits
		XCH	L		# Save index for later use

		MASK	OCT77770	# Get bit information
		INHINT			# Disable interrupts during update
		TS	ITEMP1		# Store bit information temporarily

		NDX	L		# Index to correct flag word
		CS	FLAGWRD0	# Get current flag word
		MASK	ITEMP1		# Apply bit mask
		NDX	L		# Index back to flag word
		ADS	FLAGWRD0	# Update flag word
		RELINT			# Re-enable interrupts

		INCR	Q		# Get return address
		TC	Q		# Return to caller

# DOWNENT2 - Flag Word Clear Entry Point
# Clears specified bits in a flag word
# Input: L register contains flag word index and bit information
# Output: Updated flag word in memory
DOWNENT2	TS	L		# Get flag word index
		MASK	OCT7		# Extract index bits
		XCH	L		# Save index for later use

		MASK	OCT77770	# Get bit information
		COM			# Invert for clearing

		INHINT			# Disable interrupts during update
		NDX	L		# Index to correct flag word
		MASK	FLAGWRD0	# Apply bit mask
		NDX	L		# Index back to flag word
		TS	FLAGWRD0	# Update flag word
		RELINT			# Re-enable interrupts

		INCR	Q		# Get return address
		TC	Q		# Return to caller

OCT7		EQUALS	SEVEN
		BANK	10

# Page 1486
#
# UPFLAG AND DOWNFLAG SUBROUTINES
# These routines provide general flag setting and clearing capabilities.
# They can be used in both interrupt and non-interrupt contexts to modify
# any named bit in any erasable register, subject to EBANK setting.
#
# A "named" bit is any bit with a name formally assigned by the YUL assembler.
# Currently, only bits in FLAGWORDS are named, but future assembler changes
# will allow naming any bit in erasable memory.
#
# Calling Sequences:
#   TC  UPFLAG          TC  DOWNFLAG
#   ADRES NAME OF FLAG  ADRES NAME OF FLAG
#
# Return is to the location following the "ADRES" about .58 ms after the "TC".
# Upon return, A contains the current FLAGWRD setting.

		BLOCK	02
		SETLOC	FFTAG1
		BANK
		COUNT*	$$/FLAG

# UPFLAG - Set Flag Bit
# Sets a specified flag bit to 1
# Input: Q register contains return address
#        ADRES contains flag name
# Output: A contains updated flag word
UPFLAG		CA	Q		# Get return address
		TC	DEBIT		# Process bit information
		COM			# Invert for setting
		EXTEND
		ROR	LCHAN		# Set bit
COMFLAG		INDEX	ITEMP1		# Index to flag word
		TS	FLAGWRD0	# Update flag word
		LXCH	ITEMP3		# Restore return address
		RELINT			# Re-enable interrupts
		TC	L		# Return to caller

# DOWNFLAG - Clear Flag Bit
# Clears a specified flag bit to 0
# Input: Q register contains return address
#        ADRES contains flag name
# Output: A contains updated flag word
DOWNFLAG	CA	Q		# Get return address
		TC	DEBIT		# Process bit information
		MASK	L		# Clear bit
		TCF	COMFLAG		# Update flag word

# DEBIT - Process Bit Information
# Extracts bit position and flag word information
# Input: Q register contains return address
#        ADRES contains flag name
# Output: ITEMP1 contains flag word index
#         L contains bit position
DEBIT		AD	ONE		# Get bit information
		INHINT			# Disable interrupts
		TS	ITEMP3		# Save return address
		CA	LOW4		# Get bit position
		TS	ITEMP1		# Save bit position
		INDEX	ITEMP3		# Index to flag name
		CA	0 -1		# Get flag name
		TS	L		# Save flag name
		CA	ZERO		# Clear accumulator
		EXTEND
		DV	ITEMP1		# Calculate flag word index
		DXCH	ITEMP1		# Save flag word index
		INDEX	ITEMP1		# Index to flag word
		CA	FLAGWRD0	# Get current flag word
		TS	L		# Save flag word
		INDEX	ITEMP2		# Index to bit position
		CS	BIT15		# Get bit mask
		TC	Q		# Return to caller

# Page 1488
# DELAYJOB - Job Delay Routine
# Delays execution of a job for a specified time period
#
# Input Requirements:
#   CAF  DT    # Delay job for DT centiseconds
#   TC   BANKCALL
#   CADR DELAYJOB
#
# The routine must remain in Bank 0 for proper operation.

		BANK	06
		SETLOC	DLAYJOB
		BANK

# THIS MUST REMAIN IN BANK 0 ****************************************

		COUNT	00/DELAY

# DELAYJOB - Schedule Job Delay
# Schedules a job to be delayed for a specified time period
# Input: Q register contains delay time in centiseconds
# Output: Job scheduled for delayed execution
DELAYJOB	INHINT			# Disable interrupts
		TS	Q		# Store delay time

		CAF	DELAYNUM	# Get number of delay slots
DELLOOP		TS	RUPTREG1	# Save delay slot number
		INDEX	A		# Index to delay slot
		CA	DELAYLOC	# Check if slot available
		EXTEND
		BZF	OK2DELAY	# Slot available

		CCS	RUPTREG1	# Try next slot
		TCF	DELLOOP		# Continue searching

		TC	BAILOUT		# No slots available
		OCT	1104		# Error code

# OK2DELAY - Process Available Delay Slot
# Sets up the delay slot for job execution
OK2DELAY	CA	TCSLEEP		# Get sleep return address
		TS	WAITEXIT	# Set wait exit

		CA	FBANK		# Get bank information
		AD	RUPTREG1	# Add slot number
		TS	L		# Save bank info

		CAF	WAKECAD		# Get wake address
		TCF	DLY2 -1		# Process delay

# TCGETCAD - Get Caller's Address
# Retrieves the caller's address for delayed execution
TCGETCAD	TC	MAKECADR	# Get caller's address

		INDEX	RUPTREG1	# Index to delay slot
		TS	DELAYLOC	# Save delay address

		TC	JOBSLEEP	# Put job to sleep

# WAKER - Wake Delayed Job
# Wakes up a delayed job for execution
WAKER		CAF	ZERO		# Clear accumulator
		INDEX	BBANK		# Index to bank
		XCH	DELAYLOC	# Clear delay slot
		TC	JOBWAKE		# Wake job

		TC	TASKOVER	# End task

TCSLEEP		GENADR	TCGETCAD -2	# Sleep return address
WAKECAD		GENADR	WAKER		# Wake address

# Page 1490
# GENTRAN, A BLOCK TRANSFER ROUTINE.
#
# WRITTEN BY D. EYLES
# MOD 1 BY KERNAN				UTILITYM REV 17 11/18/67
#
# MOD 2 BY SCHULENBERG (REMOVE RELINT)	SKIPPER REV 4 2/28/68
#
#	THIS ROUTINE IS USEFULL FOR TRANSFERING N CONSECUTIVE ERASABLE OR FIXED QUANTITIES TO SOME OTHER N
# CONSECUTIVE ERASABLE LOCATIONS.  IF BOTH BLOCKS OF DATA ARE IN SWITCHABLE EBANKS, THEY MUST BE IN THE SAME ONE.
#
#	GENTRAN IS CALLABLE IN A JOB AS WELL AS A RUPT.  THE CALLING SEQUENCE IS:
#
#					I	CA	N-1		# # OF QUANTITIES MINUS ONE.
#					I +1	TC	GENTRAN		# IN FIXED-FIXED.
#					I +2	ADRES	L		# STARTING ADRES OF DATA TO BE MOVED.
#					I +3	ADRES	M		# STARTING ADRES OF DUPLICATION BLOCK.
#					I +4				# RETURNS HERE.
#
#	GENTRAN TAKES 25 MCT'S (300 MICROSECONDS) PER ITEM + 5 MCT'S (60 MICS) FOR ENTERING AND EXITING.
#
#	A, L AND ITEMP1 ARE NOT PRESERVED.

		BLOCK	02
		SETLOC	FFTAG4
		BANK

		EBANK=	ITEMP1

		COUNT*	$$/TRAN

GENTRAN		INHINT
		TS	ITEMP1		# SAVE N-1.
		INDEX	Q		# C(Q) = ADRES L.
		AD	0		# ADRES (L + N - 1).
		INDEX	A
		CA	0		# C(ABOVE).
		TS	L		# SAVE DATA.
		CA	ITEMP1
		INDEX	Q
		AD	1		# ADRES (M + N - 1).
		INDEX	A
		LXCH	0		# STUFF IT.
		CCS	ITEMP1		# LOOP UNTIL N-1 = 0.
		TCF	GENTRAN +1
		TCF	Q+2		# RETURN TO CALLER.

# Page 1491
# B5OFF		ZERO BIT 5 OF EXTVBACT, WHICH IS SET BY TESTXACT.
#
#		MAY BE USED AS NEEDED BY ANY EXTENDED VERB WHICH HAS DONE TESTXACT

		COUNT*	$$/EXTVB

B5OFF		CS	BIT5
		MASK	EXTVBACT
		TS	EXTVBACT
		TC	ENDOFJOB

# Page 1492
# SUBROUTINES TO TURN OFF AND TURN ON TRACKER FAIL LIGHT.


TRFAILOF	INHINT
		CS	OCT40200	# TURN OFF TRACKER LIGHT
		MASK	DSPTAB +11D
		AD	BIT15
		TS	DSPTAB +11D
		CS	OPTMODES	# TO INSURE THAT OCDU FAIL WILL GO ON
		MASK	BIT7		# AGAIN IF IT WAS ON IN ADDITION TO
		ADS	OPTMODES	# TRACKER FAIL.

REQ		RELINT
		TC	Q

TRFAILON	INHINT
		CS	DSPTAB	+11D	# TURN ON
		MASK	OCT40200
		ADS	DSPTAB +11D
		TCF	REQ
