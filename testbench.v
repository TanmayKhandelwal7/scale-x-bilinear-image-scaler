`timescale 1ns / 1ps

module testbench;

    reg clk = 0;
    reg rst = 1;
    wire [15:0] xout, yout;
    wire done;

    // Scaling 2x2 -> 8x8 makes the bilinear smoothing very obvious
    scale #(
        .Win(275),
        .Hin(183),
        .Wout(2160),
        .Hout(1800),
        .CHANNELS(1)
    ) uut(
        .clk(clk),
        .rst(rst),
        .xout(xout),
        .yout(yout),
        .done(done)
    );

    always #5 clk = ~clk;

     //always @(posedge clk) begin
        // Fixed the argument mapping so the console prints align correctly!
       // $display("t=%0t scalex=%d scaley=%d  xin=%d  yin=%d  x0=%d y0=%d a=%d b=%d //state=%d xout=%d yout=%d addr=%d wa=%d wb=%d wc=%d wd=%d",
  //                $time, uut.scalex, uut.scaley, uut.xin, uut.yin, uut.x0, uut.y0, //uut.a, uut.b, uut.state, xout, yout, uut.addr,
  //                uut.wa, uut.wb, uut.wc, uut.wd);
    //end

    initial begin
        #10 rst = 0;

        wait(done);

        $display("DONE");
        
        // Give the module time to trigger $writememh
        #20;
$display("Done");
        $finish;
    end

endmodule