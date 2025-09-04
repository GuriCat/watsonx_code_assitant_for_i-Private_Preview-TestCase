      *****************************************************************
      * SMTP client for AS/400
      *****************************************************************
      * Printer file for debug output
     FQPRINT    O    F  132        PRINTER USROPN OFLIND(*INOV)
      *****************************************************************
      * Program version
     D*version          C                   '1-31 2000-08-29'
     D*version          C                   '1-32 2000-11-09'
     D*version          C                   '1-33 2001-04-07'
     D*version          C                   '1-34 2001-12-16'
     D*version          C                   '1-35 2002-05-06'
     Dversion          C                   '1-36 2003-05-05'
      *****************************************************************
      * Procedures definition
      *****************************************************************
      * UNIX-type functions include
      /COPY H,UNIX
      * Prototype for user procedures
      /COPY H,USER
      * Prototype for local procedures
      * Convert numeric to char ................................................
     Dn2c              PR            12
     D numeric                       10I 0 VALUE
      * Debug print out ........................................................
     Ddp               PR
     D instr                        132    VALUE
      *
      * send / print error message .............................................
     Dem               PR
     D em                            80    VALUE
     D info                         128    VALUE
     D c_error                        1P 0 VALUE OPTIONS(*NOPASS)
      *
      * Encode mail address and description ....................................
     Dencodemailaddr   PR            10I 0
     D mtype                          9    VALUE
     D mail_addr                     64    VALUE
     D mail_desc                     64    VALUE
     D outstr                       512
      * Generate SMTP mail header ..............................................
     Dsmtphead         PR            10I 0
     D instr                         64    VALUE
     D outstr                       256
      *
      * 'Q' encode for SBCS mail header ........................................
     DQencode          PR             3P 0
     D ebcdic                        64    VALUE
     D ascii                         64    VALUE
     D buflen                         3P 0 VALUE
     D newbuf                       256
      *
      * 'B' encode for DBCS mail header ........................................
     DBencode          PR             3P 0
     D ascii                        256    VALUE
     D buflen                         3P 0 VALUE
     D newbuf                       256
      *
      * quoted-printable encode (for SBCS mail body) ...........................
     Dquotedprintable  PR            10I 0
     D ebcdic                        80    VALUE
     D newbuf                       256
      *
      * Check and convert JIS to ISO-2022-JP (for DBCS mail body and header) ...
     Dto2022           PR            10I 0
     D ebcdic                        80    VALUE
     D newbuf                       256
     D iconv_index                    1P 0 VALUE
      *
      * Base64 encode (for attachment) .........................................
     Dbase64e          PR             4
     D inchr                          3    VALUE
      *
      * iconvw - User defined iconv() wrapper ..................................
     Diconvw           PR            10I 0
     D instr                        512    VALUE
     D ostr                         256
      *
      /EJECT
      *****************************************************************
      * Global valiables
      *****************************************************************
      * Program status data structure
     Dpsds            SDS
     D pgm_proc                1     10
     D pgm_error         *STATUS
     D pgm_line               21     28S 0
      ********************************************************************
      * data structures for paramesters ........................................
     Dto_num           C                   30
     Dattachment_num   C                   5
      *
     DfromDS           DS
     D from_list                      5U 0
     D from_mailaddr                 64
     D from_desc                     64
      *
      * parameter structure of 'to' list
      *    2[list] + (2[disp] * to_num) + ((2[elemlist] + 64 + 64 + 4) * to_num)
     DtoDS             DS
     D to                      1   4082
     D  to_list                       5U 0 OVERLAY(to : 1)
     D  to_replacem                   5U 0 OVERLAY(to : 3) DIM(to_num)
      *
     DattachmentDS     DS
     D at_list                        5U 0
     D at_elem                       64    DIM(attachment_num)
      *
     DreptoDS          DS
     D repto_list                     5U 0
     D repto_mailaddr                64
     D repto_desc                    64
      *
      * error message array ....................................................
      *   general error (usually unrecoverble)
     Dem1              S             80A   DIM(35) CTDATA
      *   socket, communication, SMTP error
     Dem2              S             80A   DIM(22) CTDATA
      *   normal end
     Dem3              S             80A   DIM(4) CTDATA
      * functions parameter ....................................................
      * general return code
     Drc               S             10I 0
      * Exception ID (from QUSEC data structure)
     Dexcp             S              7
      * prepareus()
     Dspc_name         S             20    INZ('SMTP      QTEMP')
      * getjobinfo()
     Djob_name         S             10
     Duser_name        S             10
     Djob_number       S              5
     Dact_time         S             13
     Djobccsid         S              9B 0
     Ddftjobccsid      S              9B 0
      * getpfinfo()
     D actual_name     S             20
     D pflf            S              3
     D file_type       S              5
     D pgmd            S              4
     D max_fields      S              5P 0
     D record_len      S              5P 0
     D file_ccsid      S              5P 0
      * getenv()
     Denvname          S             32
     Denvccsid         S             10I 0 INZ(65535)
     Denvvalue         S           1024    BASED(env_p)
      * iconv()
     Diconv_t_a        DS                  OCCURS(5)
     D iconv_a_ret                   10I 0
     D iconv_a_cd                    10I 0 DIM(12)
     Diconv_index      S              1P 0
      * base64 encode (attachment file) ........................................
     Db64chrDS         DS
     D b64i                    1      3
     D b64i1                   1      1
     D b64i2                   2      2
     D b64i3                   3      3
     Db64apDS          DS
     D b64ap                   1      8
     D b64ap1                  1      2U 0
     D b64ap1L                 2      2
     D b64ap2                  3      4U 0
     D b64ap2L                 4      4
     D b64ap3                  5      6U 0
     D b64ap3L                 6      6
     D b64ap4                  7      8U 0
     D b64ap4L                 8      8
      *
     Db64a             C                   X'4142434445464748494A4B4C4D4E4F-
      *                                      A B C D E F G H I J K L M N O
     D                                     505152535455565758595A-
      *                                    P Q R S T U V W X Y Z
     D                                     6162636465666768696A6B6C6D6E6F-
      *                                    a b c d e f g h i j k l m n o
     D                                     707172737475767778797A-
      *                                    p q r s t u v w x y z
     D                                     303132333435363738392B2F'
      *                                    0 1 2 3 4 5 6 7 8 9 + /
      * Other valiables ........................................................
      * Debug printout string
     Dpm               S            132
      * variant characters for debug print out/message
     Dlk               S              1
     Drk               S              1
     Dhat              S              1
     Dvb               S              1    INZ(X'4F')
     Dfl               S              4
      * Error message text for procedure em()
     Dmsg              S            256
      * Loop control
     DI                S              9P 0
     DJ                S              9P 0
     DK                S              9P 0
      * recipient type and number
     Drecp_type        S              4
     Drecp_type_a      S              4    DIM(3) PERRCD(3) CTDATA
     Drecp_text_a      S              5    DIM(3) PERRCD(3) CTDATA
     Drecp_num         S              3P 0 DIM(3)
      * path name
     Dtmpf             S            128
     Dbdyf             S             33
      * path name (null terminated)
     Datcfn            S             65
     Dtmpdirn          S             65
     Dtmpfn            S            129
     Dbdyfn            S             34
      * file descriptor
     Dtmpfd            S              9B 0
     Dbdyfp            S               *
     Datcfd            S              9B 0
      * current time for temp file name (store mail message)
     Dcurtime          S               Z
      * activity flag
     Dsocketopened     S              1P 0
     Dtmpfexists       S              1P 0
      * write buffer for tmpf
     Dtmpfwb           S            512
     Dtmpfwbb64        S           3900
     Dtmpfwblen        S             10I 0
      * total size of tmpf
     Dtmpf_size        S             10I 0
      * read buffer for bdyf
     Dbdyfrb           S             92
     Dbdyfrblen        S             10I 0
      * read buffer for attachment file
     Datcfrb           S           2850
     Datcfrblen        S             10I 0
      * open mode for body file
     Dbdyf_mode        S             30    INZ('rb, type=record')
      * string character set
     Dcharset          S             16
      * last folding position in encoded string
     Dfold             S              3P 0
      * structured mail header flag
     Dstructured       S              1P 0
      * MIME boundary for multipart message
     Dboundary         S             34
      * for error report in header encoding
     Dheader_info      S             12
     Dheader_value     S             64
      * non-JIS character counter (modified by procedure 'to2022')
     DinvalidDBCSn     S              5P 0
     DinvalidDBCSt     S              9P 0
      * attachment size array
     Datc_st_size      S                   LIKE(st_size) DIM(attachment_num)
      * attachment file name array
     Datc_fname        S             64    DIM(attachment_num)
      * local host name
     Dlocalhost        S             64
      * local domain name
     Dlocaldomain      S             64
      * SMTP host name (null terminated)
     Dsmtphostn        S             65
      * read/write mask for select()
     Drwmask           S             10U 0 DIM(7)
     Drwmask_w         S             10U 0 DIM(7)
      * socket receive buffer (ASCII)
     Drbuf             S           1000
      * socket receive buffer (EBCDIC, for debug/error print out)
     Drbufx            S             80
      * line send buffer (EBCDIC)
     Dwline            S             80
      * line send buffer (ASCII)
     Dwlinex           S                   LIKE(wline)
      * socket send buffer (ASCII)
     Dwbuf             S           4000
      * length of socket send buffer
     Dwbuflen          S              5P 0
      *****************************************************************
      * Input Parameters
     C     *ENTRY        PLIST
     C                   PARM                    fromDS
     C                   PARM                    toDS
     C                   PARM                    body_file        20
     C                   PARM                    body_member      10
     C                   PARM                    subject          64
     C                   PARM                    attachmentDS
     C                   PARM                    reptoDS
     C                   PARM                    smtphost         64
     C                   PARM                    invalidDBCS       8
     C                   PARM                    hdrccsid          5 0
     C                   PARM                    dbfccsid          5 0
     C                   PARM                    tmpdir           64
     C                   PARM                    debug             4
      *****************************************************************
      *
      * Main
      *
      * Initialize .............................................................
     C                   EXSR      #INIT
      * Generate mail ..........................................................
     C                   EXSR      #GEN
      * Send mail ..............................................................
     C                   EXSR      #SEND
      * End program ............................................................
     C                   IF        invalidDBCSt = 0
     C                   EVAL      rc = sndpm(em3(1) : 4 : excp)
     C                   ELSE
     C                   EVAL      rc = sndpm(em3(2) : 2 : excp)
     C                   ENDIF
      *
     C                   EVAL      *INLR = '1'
     C                   RETURN
      *****************************************************************
      * Subroutines
      *****************************************************************
      /EJECT
      /COPY QRPGLESRC,#INIT
      /EJECT
      /COPY QRPGLESRC,#GEN
      /EJECT
      /COPY QRPGLESRC,#SEND
      /EJECT
      *****************************************************************
      * program detected error handling routine
     C     #ABORT        BEGSR
      *
     C   90              CALLP     dp(' ')
     C   90              CALLP     dp('Program detected fatal error.')
      *
      * end communication
     C                   IF        socketopened = 1
     C                   EVAL      socketopened = 0
     C                   EVAL      rc = close(sd)
     C   90              CALLP     dp('  tried to close socket. rc=' +
     C                                   %TRIMR(n2c(rc)) + '.')
     C                   ENDIF
      * delete temp file
     C                   IF        tmpfexists = 1
     C                   EVAL      tmpfexists = 0
     C                   IF        debug = '*NO '
     C                   EVAL      rc = close(tmpfd)
     C                   EVAL      rc = unlink(%ADDR(tmpfn))
     C   90              CALLP     dp('  tried to delete temporary file. rc=' +
     C                                   %TRIMR(n2c(rc)) + '.')
     C                   ENDIF
     C                   ENDIF
      *
     C   90              CALLP     dp(' ')
     C   90              CALLP     dp('Program aborted.')
      *
     C                   EVAL      rc = sndpm(%TRIMR(em3(4)) + msg : 1 : excp)
     C                   EVAL      *INLR = '1'
     C                   RETURN
      *
     C                   ENDSR
      *****************************************************************
     C     *PSSR         BEGSR
      * program error subroutine
     C                   IF        ReturnPt = '*DETC'
      *   if this is the second call for this routine, doesn't send message
      *   to avoid loop
     C                   MOVEL     em2(21)       fatal            52
     C     fatal         DSPLY
     C                   EVAL      *INLR = '1'
     C                   RETURN
      *
     C                   ELSE
     C                   MOVE      '*DETC '      ReturnPt          6
     C                   CALLP     em(em2(22) :
     C                              ' PROC-''' + %TRIM(pgm_proc) +
     C                             ''', LINE-' + %TRIMR(n2c(pgm_line)) +
     C                             ', ERR-'  + %TRIMR(n2c(pgm_error)) +
     C                                    '.')
     C                   EXSR      #ABORT
     C                   ENDIF
      *
     C                   ENDSR     ReturnPt
      *****************************************************************
     OQPRINT    E                           1
     O                       pm                 132
      *****************************************************************
      * local procedures
      *****************************************************************
      /EJECT
      /COPY QRPGLESRC,#PROC
      /EJECT
      /COPY QRPGLESRC,#CTDATA