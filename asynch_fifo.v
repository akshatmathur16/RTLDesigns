// this fifo has asynchronous reset and asynchronous read, write
// i.e reset can be asserted irrespective of clock edge and read and write ops
// will be performed on different clocks, write on clk1 and read on clk2
// this is a circular FIFO

`include "defines.sv"

module proj_1_fifo_asynch(dout,full,empty,clk1,clk2,rst,write_en,read_en,din);
  output reg [`WIDTH -1:0]dout;
  output full, empty; //flags
  input clk1, clk2, rst;
  input write_en, read_en;
  input [`WIDTH -1:0]din; //input data
  reg [2:0]rp,wp;         // Read and write pointer
  reg [2:0] current_state;
  reg [2:0]count;

  parameter IDLE= 'd0;
  parameter WRITE= 'd1;
  parameter READ= 'd2;
  parameter DEPTH= 'd8;
  parameter WIDTH= 'd8;

  reg [DEPTH -1:0]mem[WIDTH -1:0];
  integer i =0;

  initial 
  begin
      current_state=IDLE;
      wp=0;
      rp=0;
      count=0;
      //dout=0;
  end

  assign full = (wp==rp && count==(WIDTH-1))?1:0;
  assign empty = (wp==rp && count=='d0)?1:0;

  always@ (posedge clk1 or posedge rst)
  begin
      if(rst)
      begin
          dout<=8'b0;
          rp<=0;
          wp<=0;
          count<=0;
          for(i=0; i<WIDTH; i=i+1)
              mem[i]<=0;

          current_state<=IDLE;
          $display("%t : Reset asserted\n",$time);
          $display("%t : current_state = %d \n",$time, current_state);
      end
      else if(~rst)
      begin
          if(write_en && ~read_en && ~full)
              current_state<=WRITE;
          else if((~write_en && ~read_en) || (full))
              current_state<=IDLE;
          else if(write_en && read_en)
              $display("BOTH WRITE AND READ CANNOT BE ENABLED AT THE SAME TIME\n");
          
          $display("%t : state changed\n",$time);
          $display("%t : current_state = %d \n",$time, current_state);
      end
  end

  always@ (posedge clk2 or posedge rst)
  begin
      if(rst)
      begin
          dout<=8'b0;
          rp<=0;
          wp<=0;
          count<=0;
          for(i=0; i<WIDTH; i=i+1)
              mem[i]<=0;

          current_state<=IDLE;
          $display("%t : Reset asserted\n",$time);
          $display("%t : current_state = %d \n",$time, current_state);
      end
      else if(~rst)
      begin
          if(~write_en && read_en && ~empty)
              current_state<=READ;
          else if((~write_en && ~read_en))
              current_state<=IDLE;
          else if(write_en && read_en)
              $display("BOTH WRITE AND READ CANNOT BE ENABLED AT THE SAME TIME\n");
          else if (empty) // to take care of fast clock scenario
          begin
              if(~write_en || read_en)
                  current_state<=IDLE;
              else if (write_en) 
                  @(posedge clk1) current_state<=WRITE;
          end

          $display("%t : state changed\n",$time);
          $display("%t : current_state = %d \n",$time, current_state);
      end
  end

  always @(posedge clk1)
  begin
      case(current_state)
          IDLE:
              begin
                  for(i=0; i<WIDTH; i=i+1)
                  begin
                      $display("%t : mem[%d]=%h \n",$time,i,mem[i]);
                  end
              end
         WRITE:
              begin
                  if(full)
                  begin
                      $display("FIFO IS FULL \n");
                      current_state<=IDLE;
                  end
                  else if(write_en &&  ~read_en)
                  begin
                      mem[wp]<=din;
                      wp<=wp+1;
                      if(count!='d7)
                          count<=count+1;
                  end
                  $display("%t : Flags : full =%b, empty = %b wp =%d, rp =%d count=%d\n",$time, full, empty,wp,rp,count);

                  for(i=0; i<WIDTH; i=i+1)
                  begin
                      $display("%t : mem[%d]=%h \n",$time,i,mem[i]);
                  end
              end
      endcase
  end
  always @(posedge clk2)
  begin
      case(current_state)
          READ:
              begin
                  if(empty)
                  begin
                      $display("FIFO IS EMPTY \n");
                      current_state<=IDLE;
                  end
                  else if(~write_en &&  read_en)
                  begin
                      dout<=mem[rp];
                      mem[rp]<='d0; // data has been popped out
                      rp<=rp+1;
                      if(count!='d0)
                          count<=count-1;
                  end
                  $display("%t : Flags : full =%b, empty = %b wp =%d, rp =%d count=%d\n",$time, full, empty,wp,rp,count);

                  for(i=0; i<WIDTH; i=i+1)
                  begin
                      $display("%t : mem[%d]=%h \n",$time,i,mem[i]);
                  end
              end
      endcase
  end

endmodule
