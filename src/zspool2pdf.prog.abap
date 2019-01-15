*&---------------------------------------------------------------------*
*& Report  ZSPOOL2PDF
*&
*&---------------------------------------------------------------------*
*& Mustafa Kerim Yılmaz
*&---------------------------------------------------------------------*

report ZSPOOL2PDF.

data: LV_LENGTH  type I,
      LV_PDF     type XSTRING,
      LT_PDF     type TLINE occurs 0,
      LT_CONTENT type standard table of TDLINE,
      LV_FILE    type STRING,
      LV_PATH    type STRING,
      LV_FULLPTH type STRING.

selection-screen begin of block BL1.
parameters: P_SPLID type TSP01-RQIDENT.
selection-screen end   of block BL1.

at selection-screen output.
  select max( RQIDENT )
    from TSP01
    into P_SPLID.

start-of-selection.

  call function 'CONVERT_ABAPSPOOLJOB_2_PDF'
    exporting
      SRC_SPOOLID              = P_SPLID
      PDF_DESTINATION          = 'X'
      NO_DIALOG                = 'X'
    importing
      PDF_BYTECOUNT            = LV_LENGTH
      BIN_FILE                 = LV_PDF
    tables
      PDF                      = LT_PDF
    exceptions
      ERR_NO_ABAP_SPOOLJOB     = 1
      ERR_NO_SPOOLJOB          = 2
      ERR_NO_PERMISSION        = 3
      ERR_CONV_NOT_POSSIBLE    = 4
      ERR_BAD_DESTDEVICE       = 5
      USER_CANCELLED           = 6
      ERR_SPOOLERROR           = 7
      ERR_TEMSEERROR           = 8
      ERR_BTCJOB_OPEN_FAILED   = 9
      ERR_BTCJOB_SUBMIT_FAILED = 10
      ERR_BTCJOB_CLOSE_FAILED  = 11.

  check SY-SUBRC is initial.

  call function 'SCMS_XSTRING_TO_BINARY'
    exporting
      BUFFER        = LV_PDF
    importing
      OUTPUT_LENGTH = LV_LENGTH
    tables
      BINARY_TAB    = LT_CONTENT.

  check SY-SUBRC is initial.

  move P_SPLID to LV_FILE.
  condense LV_FILE.
  concatenate LV_FILE '.pdf'
         into LV_FILE.

  call method CL_GUI_FRONTEND_SERVICES=>FILE_SAVE_DIALOG
    exporting
      DEFAULT_EXTENSION = 'pdf'
      DEFAULT_FILE_NAME = LV_FILE
      FILE_FILTER       = 'PDF files (*.pdf)|*.pdf'
    changing
      FILENAME          = LV_FILE
      PATH              = LV_PATH
      FULLPATH          = LV_FULLPTH
    exceptions
      others            = 1.

  check SY-SUBRC is initial.
  check LV_FILE is not initial.

  call function 'GUI_DOWNLOAD'
    exporting
      BIN_FILESIZE            = LV_LENGTH
      FILENAME                = LV_FULLPTH
      FILETYPE                = 'BIN'
    tables
      DATA_TAB                = LT_CONTENT
    exceptions
      FILE_WRITE_ERROR        = 1
      NO_BATCH                = 2
      GUI_REFUSE_FILETRANSFER = 3
      INVALID_TYPE            = 4
      NO_AUTHORITY            = 5
      UNKNOWN_ERROR           = 6
      HEADER_NOT_ALLOWED      = 7
      SEPARATOR_NOT_ALLOWED   = 8
      FILESIZE_NOT_ALLOWED    = 9
      HEADER_TOO_LONG         = 10
      DP_ERROR_CREATE         = 11
      DP_ERROR_SEND           = 12
      DP_ERROR_WRITE          = 13
      UNKNOWN_DP_ERROR        = 14
      ACCESS_DENIED           = 15
      DP_OUT_OF_MEMORY        = 16
      DISK_FULL               = 17
      DP_TIMEOUT              = 18
      FILE_NOT_FOUND          = 19
      DATAPROVIDER_EXCEPTION  = 20
      CONTROL_FLUSH_ERROR     = 21
      others                  = 22.
  if SY-SUBRC <> 0.
    message 'Unable to download file from SAP' type 'E'.
  endif.
