# Copyright:    Public domain.
# Filename:     ALARM_AND_ABORT.agc
# Purpose:      Part of the source code for Comanche, build 055. It
#               is part of the source code for the Command Module's
#               (CM) Apollo Guidance Computer (AGC), Apollo 11.
# Assembler:    yaYUL
# Reference:    pp. 1493-1496
# Contact:      Ron Burkey <info@sandroid.org>
# Website:      http://www.ibiblio.org/apollo.
# Mod history:  2009-05-07 RSB	Adapted from Colossus249 file of the same
#				name, and page images. Corrected various
#				typos in the transcription of program
#				comments, and these should be back-ported
#				to Colossus249.
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

# Page 1493
# ALARM_AND_ABORT MODULE
# This module handles alarm and abort routines for the AGC.

# ALARM SUBROUTINE
# Displays a non-abortive alarm condition. Can be called in interrupt or under executive control.
ALARM		INHINT
		CA	Q
ALARM2		TS	ALMCADR
		INDEX	Q
		CA	0
BORTENT		TS	L
PRIOENT		CA	BBANK
 +1		EXTEND
		ROR	SUPERBNK	# Add super bits.
		TS	ALMCADR +1
LARMENT		CA	Q		# Store return for alarm
		TS	ITEMP1
		CA	LOC
		TS	LOCALARM
		CA	BANKSET
		TS	BANKALRM
CHKFAIL1	CCS	FAILREG		# Check FAILREG
		TCF	CHKFAIL2	# Try next register if set
		LXCH	FAILREG
		TCF	PROGLARM	# Turn alarm light on for first alarm
CHKFAIL2	CCS	FAILREG +1
		TCF	FAIL3
		LXCH	FAILREG +1
		TCF	MULTEXIT
FAIL3		CA	FAILREG +2
		MASK	POSMAX
		CCS	A
		TCF	MULTFAIL
		LXCH	FAILREG +2
		TCF	MULTEXIT
PROGLARM	CS	DSPTAB +11D
		MASK	OCT40400
		ADS	DSPTAB +11D
MULTEXIT	XCH	ITEMP1		# Obtain return address
		RELINT
		INDEX	A
		TC	1
MULTFAIL	CA	L
		AD	BIT15
		TS	FAILREG +2
		TCF	MULTEXIT

# PRIOLARM SUBROUTINE
# Displays V05N09 via PRIODSPR with multiple returns to the user.
PRIOLARM	INHINT
		TS	L		# Save alarm code
		CA	BUF2		# 2 CADR of PRIOLARM user
		TS	ALMCADR
		CA	BUF2 +1
		TC	PRIOENT +1
-2SEC		DEC	-200		# Delay
		CAF	V05N09
		TCF	PRIODSPR

# BAILOUT SUBROUTINE
# Handles bailout scenarios.
BAILOUT		INHINT
		CA	Q
		TS	ALMCADR
		TC	BANKCALL
		CADR	VAC5STOR
		INDEX	ALMCADR
		CAF	0
		TC	BORTENT

# POODOO SUBROUTINE
# Handles debugging and error storage.
POODOO		INHINT
		CA	Q
		TS	ALMCADR
		TC	BANKCALL
		CADR	VAC5STOR	# Store erasables for debugging.
		INDEX	ALMCADR
		CAF	0
ABORT2		TC	BORTENT
		CA	V37FLBIT	# Check if average G is on
		MASK	FLAGWRD7
		CCS	A
		TC	WHIMPER -1	# Skip POODOO if set
		TC	DOWNFLAG
		ADRES	STATEFLG
		TC	DOWNFLAG
		ADRES	REINTFLG
		TC	DOWNFLAG
		ADRES	NODOFLAG
		TC	BANKCALL
		CADR	MR.KLEAN
		TC	WHIMPER

# VARALARM SUBROUTINE
# Turns on program alarm light without display.
VARALARM	INHINT
		TS	L		# Save user's alarm code
		CA	Q		# Save user's Q
		TS	ALMCADR
		TC	PRIOENT
		TC	ALMCADR		# Return to user

# ABORT ALIAS
# Temporary alias for BAILOUT.
ABORT		EQUALS	BAILOUT
