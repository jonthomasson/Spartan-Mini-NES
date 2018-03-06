'
' program to mediate commands from NES core to sd card
'
CON _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000
    
    SD_PINS  = 0
    RX_PIN   = 31
    TX_PIN   = 30
    BAUD     = 115_200
    RESULTS_PER_PAGE = 29
    ROWS_PER_FILE = 4
    CMD_PREV_PAGE = $31
    CMD_NEXT_PAGE = $32
    CMD_FIRST_PAGE = $34
    CMD_LAST_PAGE = $35
    
                       
VAR
  byte tbuf[14]   
  long file_count
  long current_page
  long last_page
  long page_files[RESULTS_PER_PAGE * ROWS_PER_FILE] 'byte array to hold index and filename
  

OBJ
  sd[2]: "fsrw" 
  serial : "FullDuplexSerial"
  
PUB main 

  serial.Start(RX_PIN, TX_PIN, %0000, BAUD) 'start the FullDuplexSerial object
  sd.mount(SD_PINS) ' Mount SD card
     

  ' set initial values
  file_count := 0
  current_page := 1
  last_page := 1
  
  get_stats 'get file stats 
  
  ' start inifinite loop
  repeat
    get_command 
                     
  sd.unmount 'unmount the sd card
             '
PRI get_stats | index
  sd.opendir
  repeat while 0 == sd.nextfile(@tbuf) 
    ' show the filename
      serial.str( @tbuf )
      repeat 15 - strsize( @tbuf )
        serial.tx( " " )
      ' so I need a second file to open and query filesize
      sd[1].popen( @tbuf, "r" )
      serial.dec( sd[1].get_filesize )
      sd[1].pclose      
      serial.str( string( " bytes", $0D ) )
      
      'move tbuf to page_files. each file takes up 4 rows of page_files
      'each row can hold 4 bytes (32 bit long / 8bit bytes = 4)
      'since the short file name needs 13 bytes (8(name)+1(dot)+3(extension)+1(zero terminate))
      bytemove(@page_files[ROWS_PER_FILE*count],@tbuf,strsize(@tbuf))
      
      file_count++
  
  last_page := file_count / RESULTS_PER_PAGE
  
  'repeat index from 0 to 115 'fill page_files with 0's for zero terminated strings
  '  page_files[index] := 0

PRI get_command | char_in
        char_in := serial.Rx
        
        case char_in
            CMD_PREV_PAGE:  
                if current_page > 1
                    current_page--
                send_page(current_page)
            CMD_NEXT_PAGE: 
                if current_page < last_page
                    current_page++
                send_page(current_page) 
            CMD_FIRST_PAGE:  
                current_page := 1
                send_page(current_page)
            CMD_LAST_PAGE:  
                current_page := last_page
                send_page(current_page)
            OTHER:
                send_file(char_in)
                
            
PRI send_page(page_number) | count
  serial.str(string("Select a Game ", 13))
    ' opening the dir is just like opening a file
    sd.opendir
    count := 0
    'skip to current page
    if page_number > 1
        repeat while count < ((page_number - 1) * RESULTS_PER_PAGE)
            sd.nextfile(@tbuf)
            count++
    
    count := 0    
    repeat while 0 == sd.nextfile(@tbuf) and count < RESULTS_PER_PAGE
      ' show the filename
      serial.str( @tbuf )
      repeat 15 - strsize( @tbuf )
        serial.tx( " " )
      ' so I need a second file to open and query filesize
      sd[1].popen( @tbuf, "r" )
      serial.dec( sd[1].get_filesize )
      sd[1].pclose      
      serial.str( string( " bytes", $0D ) )
      
      'move tbuf to page_files. each file takes up 4 rows of page_files
      'each row can hold 4 bytes (32 bit long / 8bit bytes = 4)
      'since the short file name needs 13 bytes (8(name)+1(dot)+3(extension)+1(zero terminate))
      bytemove(@page_files[ROWS_PER_FILE*count],@tbuf,strsize(@tbuf))
      count++
    

PRI send_file(index) | count
    count := 0
    repeat while count < RESULTS_PER_PAGE
        serial.str (@page_files[ROWS_PER_FILE * count])
        serial.str(string(13))
        count++
    