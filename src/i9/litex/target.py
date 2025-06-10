#!/usr/bin/env python3
from migen import *

from litex_boards.platforms import colorlight_i5
from litex.soc.integration.soc_core import SoCMini
from litex.soc.integration.builder import Builder

from litex.soc.cores.uart import UARTWishboneBridge

class BaseSoC(SoCMini):
    def __init__(self, platform, **kwargs):
        sys_clk_freq=25e6
        SoCMini.__init__(self,platform, sys_clk_freq,csr_data_width=32,ident="Yo3")

        # No CPU, use Serial to control Wishbone bus
        self.submodules.serial_bridge = UARTWishboneBridge(platform.request("serial"), sys_clk_freq)
        self.add_wb_master(self.serial_bridge.wishbone)

        # The real work
        led_out = self.platform.request("user_led_n")
        self.specials += Instance("led", i_clk_i = ClockSignal(), i_rst_i = ResetSignal(), o_out_o = led_out )
        self.platform.add_source("led.v")

if __name__ == "__main__":
    platform = colorlight_i5.Platform(board="i9",revision="7.2")
    soc = BaseSoC(platform)
    # Build --------------------------------------------------------------------------------------------
    builder = Builder(soc, output_dir="build", csr_csv="csr.csv")
    builder.build(build_name="top")

    prog = soc.platform.create_programmer();
    prog.load_bitstream(builder.get_bitstream_filename(mode="sram"))
