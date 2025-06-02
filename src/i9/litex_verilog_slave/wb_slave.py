from migen import *

from litex.soc.interconnect import csr, csr_bus, wishbone

class WishboneSlave(Module):
    def __init__(self, name, address, size):
        self.name = name
        self.address = address
        self.size = size
        self.bus = wishbone.Interface(data_width=32, adr_width=2)

    # Glue with verilog
    def glue(self,platform,led):
        # Add the source code for the slave
        platform.add_source("wb_slave.v")

        # Glue the signals from bus.wishone to the ip
        self.specials += Instance(
            "wb_slave",
            i_clk_i = ClockSignal(), i_rst_i = ResetSignal(),
            # WISHBONE M2S
            i_wb_cyc_i = self.bus.cyc,
            i_wb_stb_i = self.bus.stb,
            i_wb_we_i = self.bus.we,
            i_wb_addr_i = self.bus.adr,
            i_wb_data_i = self.bus.dat_w,
            i_wb_sel_i = self.bus.sel,

            # Wishbone S2M
            o_wb_ack_o = self.bus.ack,
            o_wb_data_o = self.bus.dat_r,

            # Debug
            o_led = led
        )
