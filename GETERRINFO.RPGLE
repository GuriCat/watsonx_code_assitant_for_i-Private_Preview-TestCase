      *****************************************************************
      * Get error information of UNIX-type functions
      *     (No input parameter)
      *     errstr : error string                                         
      *     return : errorno
      *****************************************************************
     HNOMAIN
      * Prototype for itself.
      /COPY H,USER
      * UNIX-type functions (geterrno, strerror)
      /COPY H,UNIX
      *
     Pgeterrinfo       B                   EXPORT
     Dgeterrinfo       PI            10I 0
     D errstr                       128
      *
     Derrnum           S             10I 0 BASED(errnum_p)
      *
     C                   EVAL      errnum_p = geterrno
     C                   EVAL      errstr = %STR(strerror(errnum))
     C                   RETURN    errnum
     Pgeterrinfo       E