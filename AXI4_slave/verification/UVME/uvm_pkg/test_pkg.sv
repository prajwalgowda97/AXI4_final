package test_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "./../UVME/sequence/axi_seq_item.sv"
    `include "./../UVME/agent/axi_seqr.sv"
    `include "./../UVME/sequence/axi_base_seq.sv"    
    `include "./../UVME/sequence/axi_reset_seq.sv"
    `include "./../UVME/sequence/axi_handshake_seq.sv"   
    `include "./../UVME/sequence/axi_write_seq.sv"
    `include "./../UVME/sequence/axi_read_seq.sv"
    `include "./../UVME/sequence/axi_concurrent_wr_rd_seq.sv"
    `include "./../UVME/sequence/axi_random_wr_rd_seq.sv"    
    `include "./../UVME/sequence/axi_random_wr_rd_16wstrb_seq.sv"    
    `include "./../UVME/sequence/axi_fixed_burst_seq.sv"     
    `include "./../UVME/sequence/axi_increment_burst_seq.sv" 
    `include "./../UVME/sequence/axi_wrapped_burst_seq.sv" 
    `include "./../UVME/sequence/axi_reserved_burst_seq.sv" 
    `include "./../UVME/sequence/axi_multiple_outstanding_address_seq.sv" 

    `include "./../UVME/agent/axi_driver.sv"
    `include "./../UVME/agent/axi_monitor.sv"
    `include "./../UVME/agent/axi_agent.sv"

    `include "./../UVME/env/axi_cov_model.sv"
    `include "./../UVME/env/axi_scoreboard.sv"
    `include "./../UVME/env/axi_env.sv"

    `include "./../UVME/test/axi_base_test.sv"
    `include "./../UVME/test/axi_reset_test.sv"
    `include "./../UVME/test/axi_handshake_test.sv"
    `include "./../UVME/test/axi_write_test.sv"
    `include "./../UVME/test/axi_read_test.sv"
    `include "./../UVME/test/axi_concurrent_wr_rd_test.sv"
    `include "./../UVME/test/axi_random_wr_rd_test.sv"
    `include "./../UVME/test/axi_random_wr_rd_16wstrb_test.sv"
    `include "./../UVME/test/axi_fixed_burst_test.sv"
    `include "./../UVME/test/axi_increment_burst_test.sv" 
    `include "./../UVME/test/axi_wrapped_burst_test.sv" 
    `include "./../UVME/test/axi_reserved_burst_test.sv" 
    `include "./../UVME/test/axi_multiple_outstanding_address_test.sv" 
    endpackage
