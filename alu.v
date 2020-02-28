module alu (K7, K6, K5, K4, K3, K2, K1, K0, 
           M7, M6, M5, M4, M3, M2, M1, M0, 
           ADD, SUB, MUL, DIV, EXP,
           R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, OVF);
input K7, K6, K5, K4, K3, K2, K1, K0, M7, M6, M5, M4, M3, M2, M1, M0, ADD, SUB, MUL, DIV, EXP;
output R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0, OVF ;
wire signed [7:0] A ;
wire signed [7:0] B ;
reg signed [15:0] C ;
reg Overflow;
integer signed count, expValue;

///////////////////////////////////////////////////////////////// 

   assign A = {K7, K6, K5, K4, K3, K2, K1, K0} ;
   assign B = {M7, M6, M5, M4, M3, M2, M1, M0} ;

// Perform the operation requested
    always @(ADD, SUB, MUL, DIV, EXP, A, B) begin
        Overflow <= 0;
        expValue <= 1;
        if (ADD)
            C <= A + B ; 
        else if (SUB)
            C <= A - B ; 
        else if (MUL)
            C <= A * B;
        else if (DIV) begin
            if (B != 0) begin
                C[7:0] <= A % B;
                C[15:8] <= A / B;
            end
            else
                Overflow <= 1;  
        end
        else if (EXP) begin
            if (B < 0) begin
                Overflow <= 1;
                C <= 0;
            end
            else if (B == 0)
                C <= 1;
            else begin
                for (count = 0; count < B; count = count + 1) begin
                    expValue = expValue * A;
                    if (count == (B - 1)) begin
                        if (expValue > 32767 | expValue < -32767) begin
                            Overflow <= 1;
                            C <= 0;
                        end
                        else
                            C <= expValue;
                    end
                end 
            end
        end
    end
       
// Connect the result from "C" to the "R" output lines        
   assign {R15, R14, R13, R12, R11, R10, R9, R8, R7, R6, R5, R4, R3, R2, R1, R0} = C ;
   assign OVF = Overflow ;
   
/////////////////////////////////////////////////////////////////
endmodule