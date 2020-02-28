module clockcalulator (SetsecondEXP, Setminute, Sethour, Digit, ShowtimeDIV, TimerstartsADD, PausetimerSUB, ContinuetimerMUL,
              Reset, Clockinp, HertzADD, S0SUB, S1MUL, S2DIV, EXPONENT, SV0, SV1, TSV2, CSV3,
              SBUS6, SBUS5, SBUS4, SBUS3, SBUS2, SBUS1, SBUS0,
              DCDEN7, DCDEN6, DCDEN5, DCDEN4, DCDEN3, DCDEN2, DCDEN1, DCDEN0,
              KEYINPOUT);
              
///////////////////////////////////////////////////////////////// 
//              Module Declarations Start Below
/////////////////////////////////////////////////////////////////         

// Inputs and Outputs
input SetsecondEXP, Setminute, Sethour, ShowtimeDIV, TimerstartsADD, PausetimerSUB, ContinuetimerMUL, Reset, Clockinp;
input [1:0] Digit;
inout [7:0] KEYINPOUT;
output HertzADD, S0SUB, S1MUL, S2DIV, EXPONENT, SV0, SV1, TSV2, CSV3;
output SBUS6, SBUS5, SBUS4, SBUS3, SBUS2, SBUS1, SBUS0, DCDEN7, DCDEN6, DCDEN5, DCDEN4, DCDEN3, DCDEN2, DCDEN1, DCDEN0;

// States and Flags
reg [4:0] STREG;
reg [3:0] CalState;
reg [2:0] ClockState;
reg ERROR;
reg clock, timer;
reg clockFlag, timerFlag, calculatorFlag;
reg S5_flag, one, S4_flag;
reg led0_flag, led1_flag, led2_flag, led3_flag, led14_flag, led15_flag;
wire RST = 0;

// Clock
wire CLK1HZ, CLK800HZ, CLK100HZ, CLK4HZ;
reg [7:0] countCSec, countSec, countMin, countHour;
reg [7:0] timerCSec, timerSec, timerMin, timerHour;

// Calculator
wire signed [15:0] D;
wire R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0;
wire [3:0] KEYVAL;
wire OPRENTERED;
reg signed [15:0] C;
reg ADDOP, SUBOP, MULOP, DIVOP, EXPOP;
reg signed [7:0] A,B;
wire OVF;

// 60-Second Timer Switch
reg timeout, timeoutFlag;
reg [11:0] timeoutCounter;

// Display
reg [31:0] display;
reg [3:0] displayCSec1, displaySec1, displayMin1, displayHour1, displayCSec2, displaySec2, displayMin2, displayHour2;
reg AE7, AE6, AE5, AE4, AE3, AE2, AE1, AE0;

///////////////////////////////////////////////////////////////// 
//             Module Description Starts Below
/////////////////////////////////////////////////////////////////


// Constants are names below

   parameter [4:0] RESET = 5'b00000,
                      S1 = 5'b00001,
                      S2 = 5'b00010,
                      S3 = 5'b00011,
                      S4 = 5'b00100,
                      S5 = 5'b00101,
                      S6 = 5'b00110,
                      S7 = 5'b00111,
                      S8 = 5'b01000,
                      S9 = 5'b01001,
                     S10 = 5'b01010,
                     S11 = 5'b01011,
                     S12 = 5'b01100,
                     S13 = 5'b01101,
                     S14 = 5'b01110,
                     S15 = 5'b01111,
                     S16 = 5'b10000,
                     S17 = 5'b10001,
                     S18 = 5'b10010,
                     S19 = 5'b10011,
                     S20 = 5'b10100,
                     S21 = 5'b10101;
                                
// Data Unit and Control descriptions start below

// Instantiate the Frequency Divider in the Data Unit
   FREQDIV freq_divider (.ONEHUNDREDMEGAHERTZ(Clockinp), .RESET(RST), 
                         .ONEHERTZ(CLK1HZ), .EIGHTHUNDREDHERTZ(CLK800HZ), .ONEHUNDREDHERTZ(CLK100HZ), .FOURHERTZ(CLK4HZ)) ;
 
// Instantiate the Key Pad Pmod Controller in the Data Unit
   PmodKEYPAD KeyPad_ctrl (.clk(Clockinp), .JA(KEYINPOUT), .Keypadout(KEYVAL)) ;
   
// Instantiate the ALU Block in the Data Unit
   alu alu_1 (.R15(D[15]), .R14(D[14]), .R13(D[13]), .R12(D[12]), .R11(D[11]), .R10(D[10]), .R9(D[9]), .R8(D[8]),
                         .R7(D[7]), .R6(D[6]), .R5(D[5]), .R4(D[4]), .R3(D[3]), .R2(D[2]), .R1(D[1]), .R0(D[0]), .OVF(OVF), 
                         .K7(A[7]), .K6(A[6]), .K5(A[5]), .K4(A[4]), .K3(A[3]), .K2(A[2]), .K1(A[1]), .K0(A[0]),
                         .M7(B[7]), .M6(B[6]), .M5(B[5]), .M4(B[4]), .M3(B[3]), .M2(B[2]), .M1(B[1]), .M0(B[0]),
                         .ADD(ADDOP), .SUB(SUBOP), .MUL(MULOP), .DIV(DIVOP), .EXP(EXPOP)); 
   
// Instantiate the 7-Segment Controller in the Data Unit
   ssdCtrl seven_segment_ctrl(.AN7(DCDEN7), .AN6(DCDEN6), .AN5(DCDEN5), .AN4(DCDEN4), .AN3(DCDEN3), .AN2(DCDEN2), .AN1(DCDEN1), .AN0(DCDEN0),
                              .SEGA(SBUS0), .SEGB(SBUS1), .SEGC(SBUS2), .SEGD(SBUS3), .SEGE(SBUS4), .SEGF(SBUS5), .SEGG(SBUS6),
                              .CLK100MHZ(Clockinp), .RST(RST), .Err (ERROR),
                              .DIN31(display[31]), .DIN30(display[30]), .DIN29(display[29]), .DIN28(display[28]), .DIN27(display[27]), .DIN26(display[26]), .DIN25(display[25]), .DIN24(display[24]), 
                              .DIN23(display[23]), .DIN22(display[22]), .DIN21(display[21]), .DIN20(display[20]), .DIN19(display[19]), .DIN18(display[18]), .DIN17(display[17]), .DIN16(display[16]), 
                              .DIN15(display[15]), .DIN14(display[14]), .DIN13(display[13]), .DIN12(display[12]), .DIN11(display[11]), .DIN10(display[10]), .DIN9(display[9]), .DIN8(display[8]), 
                              .DIN7(display[7]), .DIN6(display[6]), .DIN5(display[5]), .DIN4(display[4]), .DIN3(display[3]), .DIN2(display[2]), .DIN1(display[1]), .DIN0(display[0]),
                              .AE7(AE7), .AE6(AE6), .AE5(AE5), .AE4(AE4), .AE3(AE3), .AE2(AE2), .AE1(AE1), .AE0(AE0)) ;
         
// Data Unit circuits
        
    assign OPRENTERED = (TimerstartsADD | PausetimerSUB | ContinuetimerMUL | ShowtimeDIV | SetsecondEXP) ;   
    
// Data and Control Unit circuits described together below  

    // set everything to zero at the beginning
    initial begin
        // Flags
        clockFlag <= 0; timerFlag <= 0;
        timer <= 0; clock <= 0;
        S4_flag <= 0; S5_flag <= 0;
        CalState <= 0; ClockState <= 0;
        led0_flag <= 1; led1_flag <= 1; led2_flag <= 1; led3_flag <= 1; led14_flag <= 1; led15_flag <= 1;
        
        // Others
        STREG <= 0; 
        one <= 1;
        ERROR = 0;
        
        // Timer
        timeout <= 0; timeoutFlag <= 0; timeoutCounter <= 0;
        
        // Counters
        countCSec <= 0; countSec <= 0; countMin <= 0; countHour <= 0;
        timerCSec <= 0; timerSec <= 0; timerMin <= 0; timerHour <= 0;
        
        // Displays
        {AE7, AE6, AE5, AE4, AE3, AE2, AE1, AE0} <= 0;
        {displayCSec1, displaySec1, displayMin1, displayHour1, displayCSec2, displaySec2, displayMin2, displayHour2} <= 0;
    end
    
    always @ (posedge CLK100HZ) begin
        
        // Clock Counters
        if (clockFlag == 1) begin
            countCSec = countCSec + 1;
            if(countCSec==100) begin
                countCSec = 0;
                countSec = countSec + 1;
                if(countSec==60) begin
                    countSec = 0;
                    countMin = countMin + 1;
                    if (countMin==60) begin
                        countMin = 0;
                        countHour = countHour + 1;
                        if (countHour==24) begin
                            countHour = 0;
                        end
                    end
                end
            end
        end 
        else countCSec <= 0;

        // Timer Counters
        if (timerFlag == 1) begin
            timerCSec = timerCSec + 1;
            if(timerCSec==100) begin
                timerCSec = 0;
                timerSec = timerSec + 1;
                if(timerSec==60) begin
                    timerSec = 0;
                    timerMin = timerMin + 1;
                    if (timerMin==60) begin
                        timerMin = 0;
                        timerHour = timerHour + 1;
                        if (timerHour==24) begin
                            timerHour = 0;
                        end
                    end
                end
            end
        end
        
        // 60 Second Timer 
        if (timeoutFlag == 1) begin
            if (~SetsecondEXP && ~Setminute && ~Sethour && ~ShowtimeDIV && ~TimerstartsADD && ~PausetimerSUB && ~ContinuetimerMUL && 
                ~Reset && ~Digit[1] && ~Digit[0]) begin
                timeoutCounter = timeoutCounter + 1;
                if (timeoutCounter == 1000) begin
                    timeout <= 1;
                    timeoutCounter <= 0;
                end
            end
            else timeoutCounter <= 0;
        end
        
        case (STREG)
            // Reset - S7 (Clock Mode)
            RESET: begin
                       ClockState = STREG;
                       
                       // Flags and Counters
                       clockFlag <= 0; timerFlag <= 0; calculatorFlag <= 0;
                       {countCSec, countSec, countMin, countHour} <= 0;
                       {timerCSec, timerSec, timerMin, timerHour} <= 0;
                       CalState <= 0; ClockState <= 0;
                       clock <= 0; timer <= 0;
                       ADDOP <= 0; SUBOP <= 0; MULOP <= 0; DIVOP <= 0; EXPOP <= 0; ERROR <= 0;
                       led0_flag <= 1; led1_flag <= 1; led2_flag <= 1; led3_flag <= 1; led14_flag <= 1; led15_flag <= 1;
                       timeout <= 0; timeoutFlag <= 0;
                       
                       // Displays
                       {AE7, AE6, AE5, AE4, AE3, AE2, AE1, AE0} <= 0;
                       {displayCSec1, displaySec1, displayMin1, displayHour1, displayCSec2, displaySec2, displayMin2, displayHour2} <= 0;
                       display[31:0] = {displayHour1[3:0], displayHour2[3:0], displayMin1[3:0], displayMin2[3:0], displaySec1[3:0], 
                                            displaySec2[3:0], displayCSec1[3:0], displayCSec2[3:0]};
                                            
                       if (Reset) STREG <= RESET;
                       else if (SetsecondEXP) begin S4_flag = 0; STREG <= S1; end
                       else if (TimerstartsADD) begin S5_flag = 1; S4_flag = 1; STREG <= S5; end
                   end
                   
            // Set Seconds    
            S1: begin
                    ClockState = STREG;
                    clock <= 1; timer <= 0;
                    clockFlag <= 0; timerFlag <= 0;
                    countCSec <= 0;
                    displayCSec1 <= 0; displayCSec2 <= 0;
                    if (Digit[1]) displaySec2 <= KEYVAL;
                    if (Digit[0]) displaySec1 <= KEYVAL;
                    countSec = displaySec1*10 + displaySec2;
                    display[31:0] = {displayHour1[3:0], displayHour2[3:0], displayMin1[3:0], displayMin2[3:0], displaySec1[3:0], 
                                            displaySec2[3:0], displayCSec1[3:0], displayCSec2[3:0]};
                    if (Reset) STREG <= RESET;
                    else if (~SetsecondEXP) begin
                        if (S4_flag) begin
                            if (ShowtimeDIV) STREG <= S4;
                            if (Setminute) STREG <= S2;
                        end
                        else if (Setminute) STREG <= S2;
                    end
                end
            
            // Set Minutes    
            S2: begin
                    ClockState = STREG;
                    clockFlag <= 0; timerFlag <= 0;
                    timer <= 0; clock <= 1;
                    countCSec <= 0;
                    displayCSec1 <= 0;
                    displayCSec2 <= 0;
                    if (Digit[1]) displayMin2 <= KEYVAL;
                    if (Digit[0]) displayMin1 <= KEYVAL;
                    countMin = displayMin1*10 + displayMin2;
                    display[31:0] = {displayHour1[3:0], displayHour2[3:0], displayMin1[3:0], displayMin2[3:0], displaySec1[3:0], 
                                            displaySec2[3:0], displayCSec1[3:0], displayCSec2[3:0]};
                    if (Reset) STREG <= RESET;
                    else if (~Setminute) begin
                        if (S4_flag) begin
                            if (ShowtimeDIV) STREG <= S4;
                            if (Sethour) STREG <= S3;
                        end
                        else if (Sethour) STREG <= S3;
                    end
                end
            
            // Set Hours
            S3: begin
                    ClockState = STREG;
                    clockFlag <= 0; timerFlag <= 0;
                    timer <= 0;  clock <= 1;
                    countCSec <= 0;
                    displayCSec1 <= 0;
                    displayCSec2 <= 0;
                    if (Digit[1]) displayHour2 <= KEYVAL;
                    if (Digit[0]) displayHour1 <= KEYVAL;
                    countHour = displayHour1*10 + displayHour2;
                    display[31:0] = {displayHour1[3:0], displayHour2[3:0], displayMin1[3:0], displayMin2[3:0], displaySec1[3:0], 
                                            displaySec2[3:0], displayCSec1[3:0], displayCSec2[3:0]};
                    if (Reset) STREG <= RESET;
                    else if (~Sethour) begin
                        if (ShowtimeDIV) STREG <= S4;
                    end
                end      
            
            // Display Clock Mode
            S4: begin
                    ClockState = STREG;
                    clockFlag <= 1; timerFlag <= 0;
                    timer <= 0; clock <= 1;
                    displayCSec2 <= countCSec % 10;
                    displayCSec1 <= countCSec / 10;
                    displaySec2 <= countSec % 10;
                    displaySec1 <= countSec / 10;
                    displayMin2 <= countMin % 10;
                    displayMin1 <= countMin / 10;
                    displayHour2 <= countHour % 10;
                    displayHour1 <= countHour / 10;
                    S4_flag <= 1;
                    display[31:0] = {displayHour1[3:0], displayHour2[3:0], displayMin1[3:0], displayMin2[3:0], displaySec1[3:0], 
                                            displaySec2[3:0], displayCSec1[3:0], displayCSec2[3:0]};
                    if (Reset) STREG <= RESET;
                    else if (SetsecondEXP) STREG <= S1;
                    else if (Setminute) STREG <= S2;
                    else if (Sethour) STREG <= S3;
                    else if (TimerstartsADD) begin S5_flag = 1; STREG <= S5; end
                    else if (PausetimerSUB) STREG <= S6;
                    else if (ContinuetimerMUL) STREG <= S7;
                    else if (Digit[0]) calculatorFlag <= 1;
                    else if (~Digit[0]) begin
                        if (calculatorFlag) STREG <= S8;
                    end			          				  
                end
            
            // Start Timer    
            S5: begin
                    ClockState = STREG;
                    timer <= 1;
                    clock <= 0;
                    timerFlag <= 1;
                    clockFlag <= 1;
                    if (S5_flag == 1) begin
                        timerCSec <= 0;
                        timerSec <= 0;
                        timerMin <= 0;
                        timerHour <= 0;
                        S5_flag = 0;
                    end
                    
                    displayCSec2 <= timerCSec % 10;
                    displayCSec1 <= timerCSec / 10;
                    displaySec2 <= timerSec % 10;
                    displaySec1 <= timerSec / 10;
                    displayMin2 <= timerMin % 10;
                    displayMin1 <= timerMin / 10;
                    displayHour2 <= timerHour % 10;
                    displayHour1 <= timerHour / 10;
                    display[31:0] = {displayHour1[3:0], displayHour2[3:0], displayMin1[3:0], displayMin2[3:0], displaySec1[3:0], 
                                            displaySec2[3:0], displayCSec1[3:0], displayCSec2[3:0]};
                    if (Reset) STREG <= RESET;
                    else if (TimerstartsADD) begin STREG <= S5; S5_flag <= 1; end
                    else if (PausetimerSUB) STREG <= S6;
                    else if (ShowtimeDIV) STREG <= S4;
                end
            
            // Pause Timer
            S6: begin
                    ClockState = STREG; 
                    timerFlag <= 0;
                    clockFlag <= 1;
                    timer <= 1;
                    clock <= 0;
                    displayCSec2 <= timerCSec % 10;
                    displayCSec1 <= timerCSec / 10;
                    displaySec2 <= timerSec % 10;
                    displaySec1 <= timerSec / 10;
                    displayMin2 <= timerMin % 10;
                    displayMin1 <= timerMin / 10;
                    displayHour2 <= timerHour % 10;
                    displayHour1 <= timerHour / 10;
                    display[31:0] = {displayHour1[3:0], displayHour2[3:0], displayMin1[3:0], displayMin2[3:0], displaySec1[3:0], 
                                            displaySec2[3:0], displayCSec1[3:0], displayCSec2[3:0]};
                    if (Reset) STREG <= RESET;
                    else if (TimerstartsADD) begin S5_flag = 1; STREG <= S5; end
                    else if (ContinuetimerMUL) STREG <= S7;
                    else if (ShowtimeDIV) STREG <= S4;
                end
            
            // Resume Timer    
            S7: begin
                    ClockState = STREG;
                    timerFlag <= 1;
                    clockFlag <= 1;
                    timer <= 1;
                    clock <= 0;
                    displayCSec2 <= timerCSec % 10;
                    displayCSec1 <= timerCSec / 10;
                    displaySec2 <= timerSec % 10;
                    displaySec1 <= timerSec / 10;
                    displayMin2 <= timerMin % 10;
                    displayMin1 <= timerMin / 10;
                    displayHour2 <= timerHour % 10;
                    displayHour1 <= timerHour / 10;
                    display[31:0] = {displayHour1[3:0], displayHour2[3:0], displayMin1[3:0], displayMin2[3:0], displaySec1[3:0], 
                                            displaySec2[3:0], displayCSec1[3:0], displayCSec2[3:0]};
                    if (Reset) STREG <= RESET;
                    else if (TimerstartsADD) begin S5_flag = 1; STREG <= S5; end
                    else if (ShowtimeDIV) STREG <= S4;
                    else if (PausetimerSUB) STREG <= S6;
                    else if (Digit[0]) calculatorFlag <= 1;
                    else if (~Digit[0]) begin
                        if (calculatorFlag) STREG <= S8;
                    end	
                end 
            
            // Reset State 
            S8 : begin
                     CalState = STREG - 8; 
                     C <= 16'd0; A <= 8'd0; B <= 8'd0; 
                     ADDOP <= 0; SUBOP <= 0; MULOP <= 0; DIVOP <= 0; EXPOP <= 0; ERROR <= 0;
                     led0_flag <= 0; led1_flag <= 0; led2_flag <= 0; led3_flag <= 0; led14_flag <= 0; led15_flag <= 0;
                     timeoutFlag <= 1;            
                     AE7 <= 1; AE6 <= 1; AE5 <= 1; AE4 <= 1; AE3 <= 1; AE2 <= 1; AE1 <= 1; AE0 <= 1; 
                     display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                     if (Reset) STREG <= S8 ;
                     else if (Digit[0]) STREG <= S9;
                     else if (timeout) STREG <= RESET;  
                 end
  
            S9 : begin
                     CalState = STREG - 8; 
                     A[3:0] <= KEYVAL; AE0 <= 0; 
                     display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                     if (Reset) STREG <= S8;
                     else if (~Digit[0]) STREG <= S10;
                     else if (timeout) STREG <= RESET;
                 end
                
            S10 : begin 
                      CalState = STREG - 8;
                      if (Reset) STREG <= S8 ;
                      else if (Digit[0]) STREG <= S11;
                      else if (OPRENTERED) begin       
                         STREG <= S13; 
                         if (TimerstartsADD) begin  ADDOP <= 1 ; SUBOP <= 0 ; MULOP <= 0 ; DIVOP <= 0 ; EXPOP <= 0 ; end
                         else if (PausetimerSUB) begin ADDOP <= 0 ; SUBOP <= 1 ; MULOP <= 0 ; DIVOP <= 0 ; EXPOP <= 0 ; end
                         else if (ContinuetimerMUL) begin ADDOP <= 0 ; SUBOP <= 0 ; MULOP <= 1 ; DIVOP <= 0 ; EXPOP <= 0 ; end
                         else if (ShowtimeDIV) begin ADDOP <= 0 ; SUBOP <= 0 ; MULOP <= 0 ; DIVOP <= 1 ; EXPOP <= 0 ; end
                         else if (SetsecondEXP) begin ADDOP <= 0 ; SUBOP <= 0 ; MULOP <= 0 ; DIVOP <= 0 ; EXPOP <= 1 ; end 
                         display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                      end
                      else if (timeout) STREG <= RESET;
                  end 
          
            S11 : begin 
                     CalState = STREG - 8;
                     if (A[3:0] != 0) begin A[7:4] <= A[3:0] ; AE1 <= 0 ; end
                     display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                     if (Reset) STREG <= S8 ;
                     else if (~Digit[0]) STREG <= S12; 
                     else if (timeout) STREG <= RESET;
                  end      
          
            S12 : begin
                      CalState = STREG - 8; 
                      A[3:0] <= KEYVAL ; 
                      display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]}; 
                      if (Reset) STREG <= S16;
                      else if (OPRENTERED) begin
                          STREG <= S13; 
                          if (TimerstartsADD) begin  ADDOP <= 1 ; SUBOP <= 0 ; MULOP <= 0 ; DIVOP <= 0 ; EXPOP <= 0 ; end
                          else if (PausetimerSUB) begin ADDOP <= 0 ; SUBOP <= 1 ; MULOP <= 0 ; DIVOP <= 0 ; EXPOP <= 0 ; end
                          else if (ContinuetimerMUL) begin ADDOP <= 0 ; SUBOP <= 0 ; MULOP <= 1 ; DIVOP <= 0 ; EXPOP <= 0 ; end
                          else if (ShowtimeDIV) begin ADDOP <= 0 ; SUBOP <= 0 ; MULOP <= 0 ; DIVOP <= 1 ; EXPOP <= 0 ; end
                          else if (SetsecondEXP) begin ADDOP <= 0 ; SUBOP <= 0 ; MULOP <= 0 ; DIVOP <= 0 ; EXPOP <= 1 ; end
                      end
                      else if (timeout) STREG <= RESET; 
                  end
                
            S13 : begin
                      CalState = STREG - 8;
                      if (TimerstartsADD) begin  ADDOP <= 1 ; SUBOP <= 0 ; MULOP <= 0 ; DIVOP <= 0 ; EXPOP <= 0 ; end
                      else if (PausetimerSUB) begin ADDOP <= 0 ; SUBOP <= 1 ; MULOP <= 0 ; DIVOP <= 0 ; EXPOP <= 0 ; end
                      else if (ContinuetimerMUL) begin ADDOP <= 0 ; SUBOP <= 0 ; MULOP <= 1 ; DIVOP <= 0 ; EXPOP <= 0 ; end
                      else if (ShowtimeDIV) begin ADDOP <= 0 ; SUBOP <= 0 ; MULOP <= 0 ; DIVOP <= 1 ; EXPOP <= 0 ; end 
                      else if (SetsecondEXP) begin ADDOP <= 0 ; SUBOP <= 0 ; MULOP <= 0 ; DIVOP <= 0 ; EXPOP <= 1 ; end
                      display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                      if (Reset) STREG <= S8 ;
                      else if (Digit[0]) STREG <= S14;
                      else if (timeout) STREG <= RESET; 
                  end
          
            S14 : begin 
                      CalState = STREG - 8;
                      B[3:0] <= KEYVAL ; AE2 <= 0 ;
                      display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]}; 
                      if (Reset) STREG <= S8 ;
                      else if (~Digit[0]) STREG <= S15;
                      else if (timeout) STREG <= RESET;
                  end
               
            S15 : begin 
                      CalState = STREG - 8;
                      display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                      if (Reset) STREG <= S8 ;
                      else if (Digit[0]) STREG <= S16;
                      else if (Digit[1])STREG <= S18;
                      else if (timeout) STREG <= RESET; 
                  end      
          
            S16 : begin 
                      CalState = STREG - 8;
                      if (B[3:0] != 0) begin B[7:4] <= B[3:0] ; AE3 <= 0 ; end 
                      display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                      if (Reset) STREG <= S8 ;
                      if (~Digit[0]) STREG <= S17;
                      else if (timeout) STREG <= RESET;
                  end
          
            S17 : begin 
                       CalState = STREG - 8;
                       B[3:0] <= KEYVAL ; 
                       display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                       if (Reset) STREG <= S8 ;
                       else if (Digit[1]) STREG <= S18;
                       else if (timeout) STREG <= RESET;
                  end
          
            S18 : begin 
                      CalState = STREG - 8;
                      if (((B == 8'd0) & DIVOP) | ((B[7] == 1) & EXPOP) | (OVF)) ERROR <= 1 ;
                      else C <= D ;
                      display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                      if (Reset) STREG <= S8;
                      else if (timeout) STREG <= RESET;
                      else STREG <= S19; 
                  end
                
            S19 : begin 
                      CalState = STREG - 8;
                      if ((C[3:0] != 0) | (C[7:4] != 0) | (C[11:8] != 0)| (C[15:12] != 0))  AE4<= 0;
                      if ((C[7:4] != 0) | (C[11:8] != 0)| (C[15:12] != 0)) AE5 <=0;
                      if ((C[11:8] != 0) | (C[15:12] != 0)) AE6 <=0;
                      if (C[15:12] != 0) AE7<= 0;
                      display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                      if (Reset) STREG <= S8 ;
                      else if (Digit[0]) STREG <= S20; 
                      else if (timeout) STREG <= RESET;
                  end           
          
            S20 : begin 
                      CalState = STREG - 8;
                      C <= 16'd0 ; A <= 8'd0 ; B <= 8'd0 ; 
                      ADDOP <= 0 ; SUBOP <= 0 ; MULOP <= 0 ; DIVOP <= 0 ; EXPOP <= 0 ;ERROR <= 0 ;
                      AE7<= 1 ; AE6<= 1 ; AE5<= 1 ; AE4<=1 ; AE3<= 1 ; AE2<= 1 ; AE1<= 1 ; AE0<= 1 ;
                      display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                      if (Reset == 1) STREG <= S8;
                      else if (timeout) STREG <= RESET;
                      else STREG <= S21;
                  end                               
          
            S21 : begin 
                      CalState = STREG - 8;
                      if (KEYVAL != 0) begin A[3:0] <= KEYVAL ; AE0 <= 0 ; end
                      display[31:0] = {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, B[7:0], A[7:0]};
                      if (Reset) STREG <= S8 ;
                      else if (~Digit[0]) STREG <= S10;
                      else if (timeout) STREG <= RESET;
                  end
          
            default STREG <= RESET ;
        endcase
     end                       
     
     always @(posedge CLK1HZ) begin
        one = ~one;
     end
       
// Data Unit circuits below
   
   // Left LEDs  
   assign SV0 = CalState[0];
   assign SV1 = CalState[1];
   assign TSV2 = (led14_flag==1) ? timer : CalState[2];
   assign CSV3 = (led15_flag==1) ? clock : CalState[3];
   
   // Right LEDs
   assign HertzADD = (led0_flag==1) ? one : ADDOP;
   assign S0SUB = (led1_flag==1) ? ClockState[0] : SUBOP;
   assign S1MUL = (led2_flag==1) ? ClockState[1] : MULOP;
   assign S2DIV = (led3_flag==1) ? ClockState[2] : DIVOP;
   assign EXPONENT = EXPOP;
   
   assign {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0} = C ;

/////////////////////////////////////////////////////////////////

endmodule