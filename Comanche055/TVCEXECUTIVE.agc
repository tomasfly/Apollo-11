# Refactored TVCEXECUTIVE.agc
# Purpose: Part of the source code for Colossus 2A, AKA Comanche 055.
#          This is the Command Module's Apollo Guidance Computer (AGC) code for Apollo 11.

# Page 946
	BANK    16
	SETLOC  DAPROLL
	BANK
	EBANK=  BZERO
	COUNT*  $$/TVCX

TVCEXEC CS      FLAGWRD6        # Check for termination (bits 15,14 read 10 from TVCDAPON to RCSDAPON)
	MASK    OCT60000
	EXTEND
	BZMF    TVCEXFIN        # Terminate if condition met

	CAF     .5SEC           # Waitlist call to perpetuate TVCEXEC
	TC      WAITLIST
	EBANK=  BZERO
	2CADR   TVCEXEC

ROLLPREP CAE    CDUX            # Update roll ladders (no need to restart-protect)
	XCH     OGANOW
	XCH     OGAPAST

	CAE     OGAD            # Prepare roll FDAI needle with fly-to error (command - measured)
	EXTEND
	MSU     OGANOW
	TS      AK              # Fly-to OGA error

	EXTEND                  # Prepare roll DAP phase plane OGAERR
	MP      -BIT14
	TS      OGAERR          # Phase-plane (fly-from) OGA error

	CAF     THREE           # Set up roll DAP task (allow some time)
	TC      WAITLIST
	EBANK=  BZERO
	2CADR   ROLLDAP

NEEDLEUP TC     IBNKCALL        # Perform needles update (returns after CADR)
	CADR    NEEDLER

VARGAINS CAF    BIT13           # Check engine-on bit to inhibit variable gains and mass if engine off
	EXTEND
	RAND    DSALMOUT        # Channel 11
	CCS     A
	TCF     +4              # Engine on, proceed
+5      CAF     TWO             # Engine off, bypass mass/gain updates
	TS      TVCEXPHS
	TCF     1SHOTCHK
	CCS     VCNTR           # Test for gain update time
	TCF     +4              # Not yet
	TCF     GAINCHNG        # Now
	TCF     +0              # Not used
	TCF     VARGAINS +5     # No, low thrust

+4      TS      VCNTRTMP        # Protect VCNTR
	CAE     CSMMASS         # Protect CSMMASS during impulsive burn
	TS      MASSTMP
	TCF     EXECCOPY

GAINCHNG TC     IBNKCALL        # Update IXX, IAVG, IAVG/TLX
	CADR    FIXCW           # MASSPROP entry
	TC      IBNKCALL        # Update 1/CONACC, VARK
	CADR    S40.15
	CS      TENMDOT         # Update mass for next 10 sec of burn
	AD      CSMMASS
	TS      MASSTMP

	CAF     NINETEEN        # Reset variable-gain update counter
	TS      VCNTRTMP

EXECCOPY INCR    TVCEXPHS       # Restart-protect the copy cycle
	CAE     MASSTMP         # Update CSMMASS
	TS      CSMMASS
	CAE     VCNTRTMP        # Update VCNTR
	TS      VCNTR
	TS      V97VCNTR        # For ENGFAIL mass updates at SPSOFF
	INCR    TVCEXPHS        # Copy cycle over

1SHOTCHK CCS    CNTR            # Check time for one-shot or repetitive correction
	TCF     +4              # Not yet
	TCF     1SHOTOK         # Now
	TCF     REPCHEK         # One-shot over, proceed to repetitive correction
	TCF     1SHOTOK         # Now (one-shot only, no repetitive correction)

+4      TS      CNTRTMP         # Count down
	CAF     SIX             # Set up TVCEXPHS for entry at CNTRCOPY
	TS      TVCEXPHS
	TCF     CNTRCOPY

REPCHEK CAE     REPFRAC         # Check for repetitive updates
	EXTEND
	BZMF    TVCEXFIN        # No, terminate
	TS      TEMPDAP +1      # Yes, set up correction fraction
	CAF     FOUR            # Set up TVCEXPHS for entry at CORSETUP
	TS      TVCEXPHS
	TCF     CORSETUP

# Page 947
1SHOTOK CAF     BIT13           # Check engine-on bit, not permitting one-shot during engine shutdown
	EXTEND
	RAND    DSALMOUT
	CCS     A
	TCF     +2              # One-shot OK
	TCF     TVCEXFIN        # No, terminate

	INCR    TVCEXPHS        # Increment TVCEXPHS

TEMPSET CAF     FCORFRAC        # Set up correction fraction
	TS      TEMPDAP +1

	INCR    TVCEXPHS        # Entry from REPCHECK at next location

CORSETUP CAE    DAPDATR1        # Check for LEM-off/on
	MASK    BIT13           # (Note: Shows LEM-off)
	EXTEND
	BZF     +2              # LEM is on, pick up TEMPDAP+1
	CAE     TEMPDAP +1      # LEM is off, pick up 2(TEMPDAP+1)
	AD      TEMPDAP +1
	TS      TEMPDAP         # CG.CORR uses TEMPDAP

	CAF     NEGONE          # Set up for CNTR = -1 (one-shot done)
	TS      CNTRTMP

CG.CORR EXTEND                  # Pitch TMC loop
	DCA     PDELOFF
	DXCH    PACTTMP
	EXTEND
	DCS     PDELOFF
	DDOUBL
	DDOUBL
	DXCH    TTMP1
	EXTEND
	DCA     DELPBAR
	DDOUBL
	DDOUBL
	DAS     TTMP1
	EXTEND
	DCA     TTMP1
	EXTEND
	MP      TEMPDAP
	DAS     PACTTMP

	EXTEND                  # Yaw TMC loop
	DCA     YDELOFF
	DXCH    YACTTMP
	EXTEND
	DCS     YDELOFF
	DDOUBL
	DDOUBL
	DXCH    TTMP1
	EXTEND
	DCA     DELYBAR
	DDOUBL
	DDOUBL
	DAS     TTMP1
	EXTEND
	DCA     TTMP1
	EXTEND
	MP      TEMPDAP
	DAS     YACTTMP

CORCOPY INCR    TVCEXPHS        # Restart-protect the copy cycle
	EXTEND                  # Trim estimates
	DCA     PACTTMP
	TS      PACTOFF         # Trims
	DXCH    PDELOFF

	EXTEND
	DCA     YACTTMP
	TS      YACTOFF
	DXCH    YDELOFF

	INCR    TVCEXPHS        # Entry from 1SHOTCHK at next location

CNTRCOPY CAE    CNTRTMP         # Update CNTR (restarts OK, follows copy cycle)
	TS      CNTR

TVCEXFIN CAF    ZERO            # Reset TVCEXPHS
	TS      TVCEXPHS
	TCF     TASKOVER        # TVCEXECUTIVE finished

FCORFRAC OCT    10000           # One-shot correction fraction
