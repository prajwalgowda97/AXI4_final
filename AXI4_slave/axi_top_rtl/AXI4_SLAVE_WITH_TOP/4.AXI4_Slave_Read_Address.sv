module axi4_slave_read_address
#(
//=========================PARAMETERS=============================
      parameter ADDR_WIDTH   = 32,
      parameter ID_WIDTH     = 4,
      parameter BURST_LENGTH = 8
) (
//=========================INPUT SIGNALS===========================
      input  logic                            clk,
      input  logic                            rst,
      input  logic                            arvalid,    //master indicating address is valid
      input  logic   [ADDR_WIDTH - 1 : 0]     araddr,     //write address
      input  logic   [ID_WIDTH   - 1 : 0]     arid,       //write address: ID
      input  logic   [BURST_LENGTH - 1 : 0]   arlen,       //burst length
      input  logic   [2:0]                    arsize,     ///burst size
      input  logic   [1:0]                    arburst,     ////burst type
        
//=========================OUTPUT SIGNALS==========================
    output logic                            arready,
    output logic                            ar_transfer_occurred, 
    output logic [ADDR_WIDTH-1:0]           latched_araddr,       
    output logic [ID_WIDTH-1:0]             latched_arid,         
    output logic [7:0]                      latched_arlen,        
    output logic [2:0]                      latched_arsize,       
    output logic [1:0]                      latched_arburst
);
//=========================FSM STATES==============================
    typedef enum logic [1:0] {
                                IDLE       = 2'b00,
                                ADDR_STATE = 2'b01
                             } FMS_STATE;
    FMS_STATE present_state,next_state;

    //===================== Internal Signals ========================
    logic arready_next;             // Combinational next value for arready
    logic ar_transfer_occurred_comb;// Combinational pulse for handshake detection
    logic ar_transfer_occurred_ff;  // Registered pulse for output

    //===================== Combinational Logic =======================

    // FSM State Logic & Readiness Calculation
    always_comb begin
        // Default assignments
        next_state             = present_state;
        arready_next              = 1'b0; // Default not ready
        ar_transfer_occurred_comb = 1'b0; // Default pulse low

        case (present_state)
            IDLE: begin
                // Slave is ready to accept when IDLE
                // Add checks here if dependent on R channel status / buffering
                arready_next = 1'b1;

                // Check for handshake condition
                if (arvalid && arready_next) begin
                    ar_transfer_occurred_comb = 1'b1; // Signal handshake occurred
                    next_state = ADDR_STATE;         // Move to WAIT state
                end else begin
                    next_state = IDLE;         // Stay IDLE if no handshake
                end
            end

            ADDR_STATE: begin
                 // Not ready while in WAIT state
                 arready_next = 1'b0;
                 // Automatically go back to IDLE next cycle
                 next_state = IDLE;
            end

            default: begin // Should not happen
                next_state = IDLE;
            end
        endcase
    end

    //===================== Sequential Logic ==========================

    // State Register
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            present_state <= IDLE;
        end else begin
            present_state <= next_state;
        end
    end

    // Output Registers and Input Latching Logic
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            arready <= 1'b0; // Start not ready during reset
            ar_transfer_occurred_ff <= 1'b0; // Reset registered pulse
            // Reset latched output values (outputs are logic driven by this FF)
            latched_araddr  <= '0;
            latched_arid    <= '0;
            latched_arlen   <= '0;
            latched_arsize  <= '0;
            latched_arburst <= '0;
        end else begin
            arready <= arready_next; // Update arready based on calculation
            ar_transfer_occurred_ff <= ar_transfer_occurred_comb; // Register the handshake pulse

            // Latch AR channel signals only when handshake occurs (use combinational pulse)
            if (ar_transfer_occurred_comb) begin
                latched_araddr  <= araddr;
                latched_arid    <= arid;
                latched_arlen   <= arlen;  // Latches the 8-bit length value
                latched_arsize  <= arsize;
                latched_arburst <= arburst;
            end
            // Else: Latched values retain their state between bursts
        end
    end

    // Assign the registered pulse to the output port
    assign ar_transfer_occurred = ar_transfer_occurred_ff;

endmodule
