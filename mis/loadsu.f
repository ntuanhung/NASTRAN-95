      SUBROUTINE LOADSU
C
C     LOADSU SETS UP LOAD INFOTMATION FOR PROLAT FROM NSLT.
C     Z(IST)IS THE STARTING POINT FOR OPEN CORE,Z(MCORE) IS THE LAST
C     AVAILABLE WORD, NTOT IS THE NUMBER OF WORDS PUT INTO OPEN CORE
C     BY THIS ROUTINE. LOAD IS THE LOAD ID.
C
      LOGICAL         REMFL
      INTEGER         SUBCAS,BUF2,SCR1,FILE,HEST,BGPDT
      DIMENSION       NWORDS(19),MCB(7),IZ(1),L(2),ZL(2),NAM(2)
      CHARACTER       UFM*23,UWM*25
      COMMON /XMSSG / UFM,UWM
      COMMON /ZZZZZZ/ Z(1)
      COMMON /SYSTEM/ SYSBUF,IOUT
      COMMON /BIOT  / NG1,NG2,IST,SUBCAS,X1,Y1,Z1,X2,Y2,Z2,BUF2,REMFL,
     1                MCORE,LOAD,NSLT,SCR1,HEST,NTOT
      EQUIVALENCE     (Z(1),IZ(1)),(L(1),ZL(1))
      DATA    NAM   / 4HLOAD,4HSU  /
      DATA    NWORDS/ 6,6,4,4,6,6,2,5,5,6,6,7,12,10,10,19,38,7,5/
C
      BGPDT  = 103
      MCB(1) = BGPDT
      CALL RDTRL (MCB)
      NROWSP = MCB(2)
      MCB(1) = HEST
      CALL RDTRL (MCB)
      NEL    = MCB(2)
      NSIMP  = 0
      FILE   = NSLT
      CALL OPEN (*1001,NSLT,Z(BUF2),0)
      CALL READ (*1002,*10,NSLT,Z(IST+1),MCORE,0,IWORDS)
      GO TO 1008
   10 NLOADS = IWORDS-2
C
C     CHECK LOAD SELECTION AGAINST SIMPLE LOAD ID-S
C
      IF (NLOADS .EQ. 0) GO TO 35
      DO 20 I = 1,NLOADS
      IF (IZ(IST+2+I) .EQ. LOAD) GO TO 80
   20 CONTINUE
C
C     NOT A SIMPLE LOAD-MUST BEA LOAD COMBINATION. SKIP NLOADS RECORDS
C     AND SEARCH FOR PROPER LOAD ID
C
      DO 30 I = 1,NLOADS
      CALL FWDREC (*1002,NSLT)
   30 CONTINUE
C
C     READ 2 WORDS AT A TIME -1,-1 SIGNIFIES END OF LOAD CARD
C
   35 ILOAD = IST + IWORDS
   40 CALL READ (*1002,*500,NSLT,L,2,0,IFLAG)
      IF (L(1) .EQ. LOAD) GO TO 60
C
C     NO MATCH-SKIP TO -1-S
C
   50 CALL FREAD (NSLT,L,2,0)
      IF (L(1).EQ.-1 .AND. L(2).EQ.-1) GO TO 40
      GO TO 50
C
C     MATCH
C
   60 ALLS  = ZL(2)
   70 CALL FREAD (NSLT,L,2,0)
      IF (L(1).EQ.-1 .AND. L(2).EQ.-1) GO TO 90
      NSIMP = NSIMP + 1
      IF (ILOAD+2*NSIMP .GT. MCORE) GO TO 1008
      ISUB  = 2*NSIMP - 1
      Z(ILOAD+ISUB) = ZL(1)
      IZ(ILOAD+ISUB+1) = L(2)
      GO TO 70
C
C     WE HAVE NSIMP SIMPLE LOADS. FOR ONE LOAD,SET PROPER PARAMETERS
C
   80 NSIMP = 1
      ALLS  = 1.
      ILOAD = IST + IWORDS
      Z(ILOAD+1) = 1.
      IZ(ILOAD+2) = LOAD
C
C     FOR EACH SIMPLE LOAD, FIND PROPER LOAD ID AND THEN POSITION TO
C     PROPER LOAD RECORD IN NSLT
C
   90 NTOT  = 0
      ISIMP = ILOAD + 2*NSIMP
      DO 270 NS = 1,NSIMP
C
      ISUB   = ILOAD + 2*NS - 1
      FACTOR = Z(ISUB)
      ID     = IZ(ISUB+1)
      NCARDS = 0
      CALL REWIND (NSLT)
      I = 1
      IF (NLOADS .EQ. 0) GO TO 110
      DO 100 I = 1,NLOADS
      IF (ID .EQ. IZ(IST+2+I)) GO TO 110
  100 CONTINUE
      GO TO 499
C
  110 DO 120 J = 1,I
      CALL FWDREC (*1002,NSLT)
  120 CONTINUE
C
  125 CALL READ  (*1002,*260,NSLT,NOBLD,1,0,IFLAG)
      CALL FREAD (NSLT,IDO,1,0)
      IF (ISIMP+2 .GT. MCORE) GO TO 1008
      IZ(ISIMP+1) = NOBLD
      IZ(ISIMP+2) = IDO
      ISIMP = ISIMP + 2
      NTOT  = NTOT + 2
C
C     SKIP NOBLD=-20. IF NOBLD=24(REMFLUX), STORE ONLY NOBLD AND IDO,
C     BUT SKIP REMFLUX INFO ON NSLT
C
      IF (NOBLD .EQ. -20) GO TO 250
      IF (NOBLD .LE.  19) GO TO 245
      KTYPE = NOBLD - 19
      GO TO (126,127,128,129,130), KTYPE
  126 MWORDS = 3*NROWSP
      GO TO 140
  127 MWORDS = 12
      GO TO 140
  128 MWORDS = 48
      GO TO 140
  129 MWORDS = 9
      GO TO 140
  130 MWORDS = 3*NEL
      MWORDS = -MWORDS
      GO TO 141
C
  140 IF(ISIMP+MWORDS*IDO .GT. MCORE) GO TO 1008
      NTOT = NTOT + MWORDS*IDO
  141 DO 240 J = 1,IDO
C
C     NCARDS TELLS HOW MANY SIMPLE LOAD CARDS HAVE THE PRESENT FACTOR
C     APPLIED TO IT
C
      NCARDS = NCARDS + 1
      CALL FREAD (NSLT,Z(ISIMP+1),MWORDS,0)
      IF (NOBLD .NE. 24) ISIMP = ISIMP + MWORDS
  240 CONTINUE
C
C     DONE WITH CARDS OF PRESENT TYPE-GET ANOTHER TYPE
C
      GO TO 125
C
C     TYPE=-20    SKIP IT
C
  250 CALL FREAD (NSLT,Z,-(3*NROWSP),0)
      GO TO 125
C
C     NOT A MAGNETICS TYPE OF LOAD. - SKIP IT
C
  245 WRITE  (IOUT,246) UWM,LOAD
  246 FORMAT (A25,', IN FUNCTIONAL MODULE PROLATE, LOAD SET',I8, /5X,
     1       'CONTAINS A NONMAGNETIC LOAD TYPE. IT WILL BE IGNORED.')
      DO 247 I = 1,IDO
      CALL FREAD (NSLT,Z,-NWORDS(NOBLD),0)
  247 CONTINUE
C
C     EOR ON NSLT-DONE WITH THIS SIMPLE LOAD-GET ANOTHER SIMPLE LOAD
C
C     SUBSTITUTE IN OPEN CORE NCARDS FOR THE SIMPLE LOAD ID. WE NO
C     LONGER NEED THE ID, BUT WE MUST SAVE NCARDS
C
  260 CONTINUE
      IZ(ISUB+1) = NCARDS
C
  270 CONTINUE
C
C     DONE
C
C     STORE ALL THIS INFO BACK AT Z(IST) AS FOLLOWS
C
C     ALLS,NSIMP,(LOAD FACTOR,NCARDS) FOR EACH SIMPLE LOAD ID,
C     ALL LOAD INFO FOR EACH SIMPLE LOAD STARTING WITH NOBLD AND IDO
C
      Z(IST+1)  = ALLS
      IZ(IST+2) = NSIMP
      NS2   = 2*NSIMP
      DO 280 I = 1,NS2
  280 Z(IST+2+I) = Z(ILOAD+I)
      ISUB1 = IST + NS2 + 2
      ISUB2 = ILOAD + 2*NSIMP
      DO 290 I = 1,NTOT
  290 Z(ISUB1+I) = Z(ISUB2+I)
      NTOT = NTOT + 2*NSIMP + 2
      CALL CLOSE (NSLT,1)
      RETURN
C
  499 LOAD = ID
  500 WRITE  (IOUT,501) UFM,LOAD
  501 FORMAT (A23,', CANNOT FIND LOAD',I8,' ON NSLT IN BIOTSV')
      CALL MESAGE (-61,0,0)
C
 1001 N =-1
      GO TO 1010
 1002 N =-2
      GO TO 1010
 1008 N =-8
      FILE = 0
 1010 CALL MESAGE (N,FILE,NAM)
      RETURN
      END
