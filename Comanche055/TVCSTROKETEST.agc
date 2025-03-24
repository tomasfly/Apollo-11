# Copyright:	Public domain.
# Filename:	TVCSTROKETEST.agc
# Purpose:	Part of the source code for Colossus 2A, AKA Comanche 055.
# Assembler:	yaYUL
# Contact:	Ron Burkey <info@sandroid.org>.
# Website:	www.ibiblio.org/apollo.
# Pages:	979-983

# STROKE TEST PACKAGE
# FUNCTIONAL DESCRIPTION:
# - Generates a waveform to excite bending.
# - Initialization and execution of the stroke test.
# - Operates in the pitch axis only.

# CALLING SEQUENCE:
# - Extended Verb 68 sets up STRKTSTI job.
# - PITCH and YAW TVCDAPS execute the test.

# NORMAL EXIT MODES:
# - TC BUNKER (..Q.. if entry from DAP, ..TCTSKOVR.. if from WAITLIST).

# ALARM OR ABORT EXIT MODES:
# - None.

# ERASABLE INITIALIZATION REQUIRED:
# - ESTROKER (PAD-LOAD), STROKER, CADDY, REVS, CARD, N.

# OUTPUT:
# - STRKTSTI: Initialization for stroke test.
# - HACK, HACKWLST: Pulse bursts into TVCPITCH.

# DEBRIS:
# - N = CADDY = +0, CARD = -0, REVS = -1.

# Page 981: STROKE TEST INITIALIZATION PACKAGE

		BANK	17
		SETLOC	DAPS2
		BANK

		COUNT*	$$/STRK
		EBANK=	CADDY

STRKTSTI	TCR	TSTINIT		# Stroke Test Initialization Package (called by Verb 68).

STRKCHK		INHINT

		CAE	DAPDATR1	# Check for CSM/LM configuration.
		MASK	BIT14
		EXTEND
		BZF	+3

		CAE	ESTROKER	# Begin on next DAP pass (pitch or yaw).
		TS	STROKER		# Stroking done in pitch only.

		TCF	ENDOFJOB

TSTINIT		CS	FCADDY		# Normal entry from STRKTSTI.
		TS	CADDY
		TS	N		# Note: Sign change FCADDY(+) to CADDY(-).

		CAF	FREVS
		TS	REVS

		CS	FCARD		# Note: Sign change FCARD(+) to CARD(-).
		TS	CARD

		TC	Q		# Return to STRKTSTI+1.

# Page 982: OFFICIAL STROKE TEST WAVEFORM PARAMETERS

FCADDY		DEC	10		# Number of pulse bursts in 1/2 amplitude, Set 1.
FREVS		DEC	3		# Number of reversals minus 1, Set 1.

FCARD		DEC	4		# Number of stroke sets.

FCARD1		DEC	5		# Number of reversals minus 1, Set 2.
FCARD2		DEC	9		# Number of reversals minus 1, Set 3.
FCARD3		DEC	13		# Number of reversals minus 1, Set 4.

FCARD4		DEC	6		# Number of pulse bursts in 1/2 amplitude, Set 2.
FCARD5		DEC	5		# Number of pulse bursts in 1/2 amplitude, Set 3.
FCARD6		DEC	4		# Number of pulse bursts in 1/2 amplitude, Set 4.

20MS		=	BIT2

# STROKE TEST PACKAGE PROPER

		EBANK=	BUNKER

HACK		EXTEND			# Entry (in T5 RUPT) from TVCDAPS.
		QXCH	BUNKER		# Save Q for DAP return.

		CAF	20MS		# Waitlist setup.
		TC	WAITLIST
		EBANK=	BUNKER
		2CADR	HACKWLST

		TCF	+3

HACKWLST	CAF	TCTSKOVR	# Entry from WAITLIST.
		TS	BUNKER		# BUNKER is TC TASKOVER.

		CA	STROKER		# Stroke.
		ADS	TVCPITCH

		CAF	BIT11		# Release the error counters.
		EXTEND
		WOR	CHAN14
		INCR	CADDY		# Count down the number of bursts, this slope.

		CS	CADDY
		EXTEND
		BZMF	+2
		TC	BUNKER		# Exit while on a slope.

		CCS	REVS
		TCF	REVUP		# Positive reversals.
		TCF	REVUP +4	# Final reversal, this set.

		INCR	CARD		# Negative reversals set last pass.
		CS	CARD		# Check if no more sets.
		EXTEND
		BZF	STROKILL	# All sets completed.

		INDEX	CARD
		CAF	FCARD +4	# Pick up number of reversals (-), next set.
		TS	REVS		# Reinitialize.
		INDEX	CARD
		CS	FCARD +7	# Pick up number of bursts in 1/2 amplitude, next set.
		TS	N		# Reinitialize.
		TS	CADDY
		TC	BUNKER		# Exit at end of set.

STROKILL	TS	STROKER		# Reset (to +0) to end test.
		TC	BUNKER		# Exit, stroke test finished.

REVUP		TS	REVS		# All reversals except last of set.
		CA	N
		DOUBLE			# 2 x 1/2 amplitude.
		TCF	+4

	+4	CS	ONE		# Final reversal, this set.
		TS	REVS		# Prepare to branch to new burst.
		CA	N		# Just return to zero, final slope of set.
		TS	CADDY		# CADUP.

		CS	STROKER		# Change sign of slope.
		TS	STROKER
		TC	BUNKER		# Exit at a reversal (slope change).
