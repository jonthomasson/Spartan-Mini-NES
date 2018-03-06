'
' program to mediate commands from NES core to sd card
'
CON _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000
    
    SD_PINS  = 0
    RX_PIN   = 15'31
    TX_PIN   = 14'30
    RX_PIN_FILE = 13 'dedicated serial rx for file transfer
    TX_PIN_FILE = 12 'dedicated serial tx for file transfer
    BAUD     = 115_200
    BAUD_FILE_TX     = 38_400'115_200
    NUM_COLUMNS = 80 'number of columns in tile map
    NUM_ROWS = 30 'number of rows in tile map
    RESULTS_PER_PAGE = 29
    ROWS_PER_FILE = 4 'number of longs it takes to store 1 file name
    MAX_FILES = 300 'limiting to 300 games for now due to memory limits
    FILE_BUF_SIZE = $400 'size of file buffer (1KB)
    'commands sent from fpga to prop...
    CMD_PREV_PAGE = $80
    CMD_NEXT_PAGE = $81
    CMD_FIRST_PAGE = $82
    CMD_LAST_PAGE = $83
    CMD_READY = $84 'used to tell prop that it's ready for bitstream/new packet
    CMD_ERROR = $85 'error receiving packet
    'commands sent from prop to fpga
    CMD_CURSOR_1 = $80 'set cursor at position 1 (ie top of screen)
    CMD_CURSOR_2 = $81 'set cursor at position 2 (ie 2nd to top of screen)
    CMD_SHOW_CURSOR = $82
    CMD_HIDE_CURSOR = $83
    CMD_LOAD_GAME = $84 'prepare for bitstream
    'commands used by file transfer and nes
    CMD_DEBUG_BREAK = $03
    CMD_PPU_DISABLE = $0B
    CMD_DEBUG_RUN = $04
    CMD_CONFIG_INES = $0C
    CMD_WRITE_CPU = $02
    CMD_WRITE_PPU = $0A
    CMD_CPU_PC = $06
    CMD_PC_L = $00
    CMD_PC_H = $01
                       
VAR
  byte tbuf[14]   
  byte file_buffer[FILE_BUF_SIZE]
  byte iNes_buffer[16]
  long file_count
  long current_page
  long last_page
  long file_sizes[MAX_FILES] 'byte array to hold index and file sizes in bits
  long files[MAX_FILES * ROWS_PER_FILE] 'byte array to hold index and filename
  

OBJ
  sd[2]: "fsrw" 
  serial : "FullDuplexSerial" 'main serial line for ascii communication
  serial_filetx : "FullDuplexSerial" 'serial line for file transfer
PUB main 

  serial.Start(RX_PIN, TX_PIN, %0000, BAUD) 'start the FullDuplexSerial object
  serial_filetx.Start(RX_PIN_FILE, TX_PIN_FILE, %0000, BAUD_FILE_TX) 'start serial connection for file transfers
  
  ' set initial values
  file_count := 0
  current_page := 0
  last_page := 1
  
  send_splash_screen 'splash screen to display while files are loaded
  
  get_stats 'get file stats 
          
  send_page(current_page) 'display first page
  
  
  'send_file_byname2(string("excite~1.nes"))
  
  ' start inifinite loop
  repeat
    get_command 
                     
  
             '
PRI get_stats | index
  sd.mount(SD_PINS) ' Mount SD card
  sd.opendir    'open root directory for reading
  
  'loading file names from sd card into ram for faster paging              
  repeat while 0 == sd.nextfile(@tbuf) 
    
      ' so I need a second file to open and query filesize
      sd[1].popen( @tbuf, "r" )
      
      'save file size in file_sizes array
      file_sizes[file_count] := sd[1].get_filesize
      sd[1].pclose      
      
      'move tbuf to files. each file takes up 4 rows of files
      'each row can hold 4 bytes (32 bit long / 8bit bytes = 4)
      'since the short file name needs 13 bytes (8(name)+1(dot)+3(extension)+1(zero terminate))
      bytemove(@files[ROWS_PER_FILE*file_count],@tbuf,strsize(@tbuf))
      
      file_count++
  
  last_page := file_count / RESULTS_PER_PAGE
  
  sd.unmount 'unmount the sd card
  

PRI get_command | char_in
        char_in := serial.Rx
        
        case char_in
            CMD_PREV_PAGE:  
                if current_page > 0
                    current_page--
                else
                    current_page := last_page 'we're at first page, so go to last page.
                send_page(current_page) 
            CMD_NEXT_PAGE: 
                if current_page < last_page
                    current_page++ 
                else
                    current_page := 0 'we're at last page, so loop back to first page.
                send_page(current_page)  
            CMD_FIRST_PAGE:  
                current_page := 0 
                send_page(current_page) 
            CMD_LAST_PAGE:  
                current_page := last_page
                send_page(current_page)
            OTHER:
                'serial.Dec (char_in)
                'send_newline
                'if char_in <= NUM_ROWS 
                send_file_byindex(char_in)
                send_page(current_page)
                'if char_in >= 0 and char_in <= RESULTS_PER_PAGE
                '    send_file_byindex(char_in)
                '    send_page(current_page)
                
            
PRI send_page(page_number) | count, page_count, count2
  send_command(CMD_HIDE_CURSOR)
  send_clear_screen 'clear screen first
  send_command(CMD_CURSOR_1) 'set cursor to position 1
                             '
  serial.str(string("   LOAD GAME      MEM/BYTES      PAGE " ))
  serial.Dec (page_number + 1)
  serial.Str (string("/"))
  serial.Dec (last_page + 1)
  serial.Str (string("      TOTAL GAMES:"))
  serial.Dec (file_count)
  send_newline
  
    count := 0  
    count2 := 0  
    page_count := page_number * RESULTS_PER_PAGE
    
    repeat while count < RESULTS_PER_PAGE and (count2 < file_count - 1)
      count2 := page_count + count
      serial.Dec (count2 + 1)
      serial.Str (string("."))
      if count2 + 1 < 10
        serial.Tx (" ")
        serial.Tx (" ")
      elseif count2 + 1 < 100
        serial.Tx (" ")
      
      ' show the filename
      serial.Str (@files[ROWS_PER_FILE * count2])
      repeat 15 - strsize( @files[ROWS_PER_FILE * count2] )
        serial.tx( " " )
      
      serial.dec (file_sizes[count2])     
      send_newline
      
      count++
      
  send_command(CMD_CURSOR_2) 'set cursor to position 2
  send_command(CMD_SHOW_CURSOR)  

  
        
PRI send_newline
    serial.str(string(13))
    
PRI send_command(command)
    serial.Tx (command)
    
PRI sendfx_command(command)
    serial_filetx.Tx (command)
    'serial_filetx.Hex (command, 2)
    
PRI send_clear_screen
    send_command(CMD_CURSOR_1) 'set cursor to position 1
                               '
    repeat NUM_ROWS + 2 'repeat for 30 rows
        repeat NUM_COLUMNS + 1 'repeat for 80 columns
            serial.Str (string(" ")) 'send space
    send_newline
        
PRI send_splash_screen
    send_command(CMD_HIDE_CURSOR)
    send_clear_screen
    send_command(CMD_CURSOR_1)
    serial.Str (string("LOADING..."))
    

    
PRI send_file_byindex(index) | open_error, file_name
    file_name := @files[ROWS_PER_FILE * ((current_page * RESULTS_PER_PAGE) + (index - 1))]
    
    send_file_byname2(file_name)

PRI send_file_byname2(file_name) | open_error, bytes_read, count, ack, num_packets, prgRomBanks, prgRomDataSize, chrRomBanks, chrRomDataSize, totalBytes, transferBlockSize, transferredBytes, pctDone, romOffset
    sd.mount(SD_PINS)
    send_command(CMD_HIDE_CURSOR)
    send_clear_screen
    send_command(CMD_CURSOR_1)
    serial.Str (string("loading game "))
    
    serial.Str (file_name)
    
    open_error := sd.popen(file_name, "r") ' Open file
    
    if open_error == -1 'error opening file
        serial.Str (string("error opening file "))
        sd.unmount
        return 'exit sub
    
    sendfx_command(CMD_DEBUG_BREAK) 
    sendfx_command(CMD_PPU_DISABLE) 
    
    'send bytes 4-8 of iNES header
    sendfx_command(CMD_CONFIG_INES) 
    bytes_read := 0 
    bytes_read := sd.pread(@iNes_buffer,16) 'read in first 16 bits which corresponds to iNES header
    if bytes_read <> -1
        'serial_filetx.Hex (byte[@iNes_buffer][4], 2) 'print for debug
        'serial_filetx.Hex (byte[@iNes_buffer][5], 2)'print for debug
        'serial_filetx.Hex (byte[@iNes_buffer][6], 2)'print for debug
        'serial_filetx.Hex (byte[@iNes_buffer][7], 2)'print for debug
        'serial_filetx.Hex (byte[@iNes_buffer][8], 2)'print for debug
        serial_filetx.Tx (byte[@iNes_buffer][4])
        serial_filetx.Tx (byte[@iNes_buffer][5])
        serial_filetx.Tx (byte[@iNes_buffer][6])
        serial_filetx.Tx (byte[@iNes_buffer][7])
        serial_filetx.Tx (byte[@iNes_buffer][8])
        
    'transferBlockSize := $400 'transfer only 1KB at a time
    
    prgRomBanks := byte[@iNes_buffer][4]
    prgRomDataSize := prgRomBanks * $4000 'multiply number of rom banks times bytes per bank(16KB) to get total size
    chrRomBanks := byte[@iNes_buffer][5]
    chrRomDataSize := prgRomBanks * $2000 'multiply number of rom banks times bytes per bank(8KB) to get total size
    totalBytes := prgRomDataSize + chrRomDataSize
    
    'serial_filetx.Str (string("total size="))
    'serial_filetx.Hex (totalBytes, 4)
    
    'copy PRG ROM data
    num_packets := prgRomDataSize / FILE_BUF_SIZE
    bytes_read := 0
    transferredBytes := 0
    romOffset := 0
    count := 0
    
    repeat while count < num_packets
        'serial_filetx.Str (string("num_packets="))
        'serial_filetx.Dec (num_packets)
        bytes_read := sd.pread(@file_buffer,FILE_BUF_SIZE)
        romOffset := FILE_BUF_SIZE * count
        romOffset += $8000 'start of PRG rom at 0x8000
        send_packet2(CMD_WRITE_CPU, romOffset, FILE_BUF_SIZE, @file_buffer)
        count++
  
    num_packets := chrRomDataSize / FILE_BUF_SIZE
    bytes_read := 0
    transferredBytes := 0
    romOffset := 0
    count := 0
          
    repeat while count < num_packets
        'serial_filetx.Str (string("num_packets="))
        'serial_filetx.Dec (num_packets)
        bytes_read := sd.pread(@file_buffer,FILE_BUF_SIZE)
        romOffset := FILE_BUF_SIZE * count
        send_packet2(CMD_WRITE_PPU, romOffset, FILE_BUF_SIZE, @file_buffer)
        count++
        
   
    
    'get reset vector
    bytes_read := sd.seek(16 + prgRomDataSize - 4)
    bytes_read := sd.pread(@file_buffer, $02)

    
    'update program counter to point to reset vector
    'serial_filetx.Hex (byte[@file_buffer][0], 2)
    'serial_filetx.Hex (byte[@file_buffer][1], 2)
    sendfx_command(CMD_CPU_PC)
    sendfx_command(CMD_PC_L)
    serial_filetx.Tx (byte[@file_buffer][0])
    
    sendfx_command(CMD_CPU_PC)
    sendfx_command(CMD_PC_H)
    serial_filetx.Tx (byte[@file_buffer][1])   
    
    
    'issue debug run command
    sendfx_command(CMD_DEBUG_RUN)
               
    
    
    serial.Str (string("done sending file "))
    sd.unmount

PRI send_packet2(cmd, address, count, data) | checksum, i
    'Packet Format: 1 byte command | 1 byte address | 1 byte size | data bytes
    
    'send packet    
    'serial_filetx.Tx (cmd) 'send command  
    serial_filetx.Tx (cmd)              
    'serial_filetx.Tx (address)  'send address
    serial_filetx.Tx (address.Byte[0]) 
    serial_filetx.Tx (address.Byte[1])                               
    'serial_filetx.Tx (count)    'send count
    serial_filetx.Tx (count.Byte[0])    
    serial_filetx.Tx (count.Byte[1])                        
    'serial_filetx.Hex (count, 4)
    'send data   
    i := 0    
    repeat while i < count
      'serial_filetx.Tx (byte[data][i])
      serial_filetx.Tx (byte[data][i])
      i++

PRI send_file_byname(file_name) | open_error, bytes_read, count, ack, num_packets
    sd.mount(SD_PINS)
    send_command(CMD_HIDE_CURSOR)
    send_clear_screen
    send_command(CMD_CURSOR_1)
    serial.Str (string("loading game "))
    
    serial.Str (file_name)
    
    sendfx_command(CMD_LOAD_GAME) 'tell fpga to get ready for bitstream
               '
    open_error := sd.popen(file_name, "r") ' Open file
    
    if open_error == -1 'error opening file
        serial.Str (string("error opening file "))
        sd.unmount
        return 'exit sub
               
    num_packets := sd.get_filesize / FILE_BUF_SIZE 'calculate total number of packets to send
    if (sd.get_filesize // FILE_BUF_SIZE > 0) 'check for remainder
        num_packets++
    serial_filetx.Tx (num_packets.byte[0])
    serial.Hex (num_packets, 4)
    send_newline
    
    serial_filetx.Tx (num_packets.byte[1]) 'send 2 byte number of packets
    
    'send packets to fpga one at a time
    bytes_read := 0
    
    repeat while bytes_read <> -1
        bytes_read := sd.pread(@file_buffer,FILE_BUF_SIZE) 
        if bytes_read <> -1 'not at end of file
            
            send_packet($37, bytes_read, @file_buffer)
    
    serial.Str (string("done sending file "))
    sd.unmount
    
PRI send_packet(address, count, data) | checksum, i
    'Packet Format: 1 byte checksum | 1 byte address | 1 byte count | (count + 1) data bytes
    'Addresses: $35 = resets game loader
    '           $37 = game storage
    '           $40 and $41 = controller registers
    
    checksum := address + count
    i := 0
    'loop through data buffer and compute the checksum
    repeat while i < count
        checksum += byte[data][i]
        'checksum += data[i]
        i++
    
    'send packet    
    serial_filetx.Tx (-checksum) 'send checksum                   
    serial_filetx.Tx (address)  'send address
    serial_filetx.Tx (count)    'send count
    
        
    i := 0    
    repeat while i < count
      serial_filetx.Tx (byte[data][i])
      
      i++

    
    
    