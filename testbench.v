`timescale 1ns / 1ps

module testbench;

    reg clk = 0;
    reg rst = 1;
    wire [15:0] xout, yout;
    wire done;

  
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

    initial begin
        #10 rst = 0;

        wait(done);

        $display("DONE");
    
        #20;
$display("Done");
        $finish;
    end

endmodule
