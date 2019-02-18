module axi4_slave_read_data 
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter BURST_LENGTH = 8
) (
    input  logic                        clk,
    input  logic                        rst,

    input  logic [ADDR_WIDTH-1:0]       latched_araddr,       
    input  logic [ID_WIDTH-1:0]         latched_arid,         
    input  logic [7:0]                  latched_arlen,        
    input  logic [2:0]                  latched_arsize,      
    input  logic [1:0]                  latched_arburst,

    input  logic [DATA_WIDTH-1:0]       rdata_in,
    input  logic                        arvalid,
    input  logic                        arready,
    output logic                        rvalid,      
    output logic [DATA_WIDTH - 1 : 0]   rdata,       
    output logic [ID_WIDTH  - 1 : 0]    rid,         
    output logic                        rlast,       
    output logic [1:0]                  rresp,

    input  logic [BURST_LENGTH - 1 : 0] burst_length,
    input  logic                        rready,
    output logic                        mem_rd_en,          
    output logic [ADDR_WIDTH-1:0]       mem_addr,          
    input  logic [DATA_WIDTH-1:0]       mem_rd_data 
);

    typedef enum logic [1:0] {
        R_IDLE        = 2'b00,
        R_READ_MEM    = 2'b01,
        R_SEND_DATA   = 2'b10
    } FMS_STATE;

    FMS_STATE present_state, next_state;

    logic [7:0]            beats_remaining;  
    logic [ADDR_WIDTH-1:0] current_addr;     
    logic [ID_WIDTH-1:0]   active_rid;       
    logic [2:0]            active_arsize;    
    logic [1:0]            active_arburst;   
    logic                  rvalid_reg;       
    logic                  rvalid_next;      
    logic [DATA_WIDTH-1:0] rdata_reg;        
    logic                  burst_active;     
    logic [1:0]            rresp_reg;        
    logic [ADDR_WIDTH-1:0] wrap_boundary;
    logic [ADDR_WIDTH-1:0] upper_addr_limit;
    logic [$clog2(DATA_WIDTH/8):0] num_bytes;
    logic                  is_last_beat;

    logic                  mem_rd_en_reg;

    logic [$clog2(DATA_WIDTH/8):0] size_in_bytes;
    logic [ADDR_WIDTH:0]           burst_len_bytes;


    assign num_bytes = 1 << active_arsize;
    assign is_last_beat = (beats_remaining == 1) && burst_active;
    assign rid      = active_rid;      
    assign rdata    = rdata_reg;       
    assign rresp    = rresp_reg;       
    assign mem_addr = current_addr;
    assign rlast    = is_last_beat && rvalid_reg;
    assign mem_rd_en = mem_rd_en_reg;

    // FSM Logic
    always_comb begin
        next_state   = present_state;     
        rvalid_next  = 1'b0;

        case (present_state)
            R_IDLE: begin
                if (arvalid && arready) begin
                    next_state = R_READ_MEM;
                end
            end

            R_READ_MEM: begin 
                rvalid_next = 1'b1;
                next_state = R_SEND_DATA; 
            end

            R_SEND_DATA: begin 
                rvalid_next = 1'b1;
                if (rvalid_reg && rready) begin 
                    if (!is_last_beat) begin
                        next_state = R_READ_MEM;
                    end else begin
                        next_state = R_IDLE;
                    end
                end
            end

            default: begin
                next_state = R_IDLE;
                rvalid_next = 1'b0;
            end
        endcase
    end

    // State register and mem_rd_en one-cycle pulse
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            present_state <= R_IDLE;
            mem_rd_en_reg <= 1'b0;
        end else begin
            present_state <= next_state;

            // One-cycle pulse on entry into R_READ_MEM
            if (next_state == R_READ_MEM && present_state != R_READ_MEM) begin
                mem_rd_en_reg <= 1'b1;
            end else begin
                mem_rd_en_reg <= 1'b0;
            end
        end
    end

    // ID register
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            active_rid <= '0;
        end else if (rvalid) begin
            active_rid <= latched_arid;
        end else begin
            active_rid <= '0;
        end
    end

    // Main datapath logic
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            burst_active      <= 1'b0;
            beats_remaining   <= '0;
            active_arsize     <= '0;
            active_arburst    <= '0;
            current_addr      <= '0;
            rresp_reg         <= 2'b00;
            rdata_reg         <= '0;
            wrap_boundary     <= '0;
            upper_addr_limit  <= '0;
            rvalid_reg        <= 1'b0;
        end else begin
            if (arvalid && arready) begin
                burst_active    <= 1'b1;
                beats_remaining <= latched_arlen + 1; 
                current_addr    <= latched_araddr;   
                active_arsize   <= latched_arsize;
                active_arburst  <= latched_arburst;
                rresp_reg       <= 2'b00;

                if (latched_arburst == 2'b10) begin // WRAP
                    size_in_bytes = 1 << latched_arsize;
                    burst_len_bytes = size_in_bytes * (latched_arlen + 1);
                    if (burst_len_bytes > 0) begin
                        wrap_boundary = (latched_araddr / burst_len_bytes) * burst_len_bytes;
                    end else begin
                        wrap_boundary = latched_araddr;
                    end
                    upper_addr_limit = wrap_boundary + burst_len_bytes - size_in_bytes;
                end
            end

            if (mem_rd_en_reg) begin
                rdata_reg <= mem_rd_data;
            end

            if (present_state == R_SEND_DATA && rvalid_reg && rready) begin
                if (beats_remaining > 0) begin
                    beats_remaining <= beats_remaining - 1;
                end

                if (!is_last_beat) begin
                    case (active_arburst)
                        2'b00: current_addr <= current_addr; // FIXED
                        2'b01: current_addr <= current_addr + num_bytes; // INCR
                        2'b10: begin // WRAP
                            if (current_addr == upper_addr_limit) begin
                                current_addr <= wrap_boundary;
                            end else begin
                                current_addr <= current_addr + num_bytes;
                            end
                        end
                        default: current_addr <= current_addr;
                    endcase
                end 
            end 

            if (burst_active && next_state == R_IDLE && present_state == R_SEND_DATA) begin
                if (rvalid_reg && rready) begin
                    burst_active <= 1'b0;
                end
            end

            rvalid_reg <= rvalid_next;
        end
    end

    assign rvalid = rvalid_reg;

endmodule

