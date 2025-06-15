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

# Page 1493
# ALARM_AND_ABORT MODULE
# This module handles alarm and abort routines for the AGC.
# It provides critical error handling and recovery mechanisms for the spacecraft.
#
# Key Features:
# - Non-abortive alarm handling
# - Priority-based alarm processing
# - Bailout and emergency procedures
# - Debug and error storage capabilities
#
# Error Categories:
# 1. Non-critical alarms (ALARM)
# 2. Priority alarms (PRIOLARM)
# 3. Critical failures (BAILOUT)
# 4. Debug conditions (POODOO)

# ALARM SUBROUTINE
# Displays a non-abortive alarm condition. Can be called in interrupt or under executive control.
# Input: Q register contains alarm code
# Output: Sets appropriate alarm indicators and stores error information
ALARM		INHINT			# Disable interrupts during alarm processing
		CA	Q		# Get alarm code
ALARM2		TS	ALMCADR		# Store alarm code
		INDEX	Q
		CA	0		# Get alarm data
BORTENT		TS	L		# Store alarm data
PRIOENT		CA	BBANK		# Get bank information
 +1		EXTEND
		ROR	SUPERBNK	# Add super bits for bank tracking
		TS	ALMCADR +1	# Store bank info
LARMENT		CA	Q		# Store return for alarm
		TS	ITEMP1		# Save return address
		CA	LOC		# Get current location
		TS	LOCALARM	# Store alarm location
		CA	BANKSET		# Get bank setting
		TS	BANKALRM	# Store bank setting

# Check failure registers in priority order
CHKFAIL1	CCS	FAILREG		# Check primary failure register
		TCF	CHKFAIL2	# Try next register if set
		LXCH	FAILREG		# Store failure info
		TCF	PROGLARM	# Turn alarm light on for first alarm
CHKFAIL2	CCS	FAILREG +1	# Check secondary failure register
		TCF	FAIL3		# Try tertiary register
		LXCH	FAILREG +1	# Store failure info
		TCF	MULTEXIT	# Handle multiple failures
FAIL3		CA	FAILREG +2	# Check tertiary failure register
		MASK	POSMAX		# Mask for valid failure codes
		CCS	A
		TCF	MULTFAIL	# Handle multiple failures
		LXCH	FAILREG +2	# Store failure info
		TCF	MULTEXIT	# Exit after storing

# Activate program alarm indicators
PROGLARM	CS	DSPTAB +11D	# Get display table entry
		MASK	OCT40400	# Mask for alarm indicators
		ADS	DSPTAB +11D	# Set alarm indicators
MULTEXIT	XCH	ITEMP1		# Get return address
		RELINT			# Re-enable interrupts
		INDEX	A
		TC	1		# Return to caller

# Handle multiple failures
MULTFAIL	CA	L		# Get failure code
		AD	BIT15		# Add multiple failure indicator
		TS	FAILREG +2	# Store in tertiary register
		TCF	MULTEXIT	# Exit after storing

# PRIOLARM SUBROUTINE
# Displays V05N09 via PRIODSPR with multiple returns to the user.
# Used for priority-based alarm handling.
PRIOLARM	INHINT			# Disable interrupts
		TS	L		# Save alarm code
		CA	BUF2		# Get 2 CADR of PRIOLARM user
		TS	ALMCADR		# Store alarm code
		CA	BUF2 +1		# Get additional data
		TC	PRIOENT +1	# Process priority entry
-2SEC		DEC	-200		# 2-second delay
		CAF	V05N09		# Get display code
		TCF	PRIODSPR	# Display priority alarm

# BAILOUT SUBROUTINE
# Handles critical failure scenarios requiring immediate action.
# Implements emergency procedures and recovery mechanisms.
BAILOUT		INHINT			# Disable interrupts
		CA	Q		# Get bailout code
		TS	ALMCADR		# Store bailout code
		TC	BANKCALL	# Call bank routine
		CADR	VAC5STOR	# Store critical data
		INDEX	ALMCADR		# Get stored code
		CAF	0		# Clear accumulator
		TC	BORTENT		# Process bailout

# POODOO SUBROUTINE
# Handles debugging and error storage.
# Provides detailed error information for analysis.
POODOO		INHINT			# Disable interrupts
		CA	Q		# Get debug code
		TS	ALMCADR		# Store debug code
		TC	BANKCALL	# Call bank routine
		CADR	VAC5STOR	# Store erasables for debugging
		INDEX	ALMCADR		# Get stored code
		CAF	0		# Clear accumulator
ABORT2		TC	BORTENT		# Process abort
		CA	V37FLBIT	# Check if average G is on
		MASK	FLAGWRD7	# Check flag word
		CCS	A
		TC	WHIMPER -1	# Skip POODOO if set
		TC	DOWNFLAG	# Clear state flag
		ADRES	STATEFLG
		TC	DOWNFLAG	# Clear reinitialize flag
		ADRES	REINTFLG
		TC	DOWNFLAG	# Clear no-do flag
		ADRES	NODOFLAG
		TC	BANKCALL	# Call cleanup routine
		CADR	MR.KLEAN
		TC	WHIMPER		# Exit to whimper

# VARALARM SUBROUTINE
# Turns on program alarm light without display.
# Used for non-critical warnings that don't require user interaction.
VARALARM	INHINT			# Disable interrupts
		TS	L		# Save user's alarm code
		CA	Q		# Save user's Q
		TS	ALMCADR		# Store alarm code
		TC	PRIOENT		# Process priority entry
		TC	ALMCADR		# Return to user

# ABORT ALIAS
# Temporary alias for BAILOUT.
# Maintained for backward compatibility.
ABORT		EQUALS	BAILOUT
