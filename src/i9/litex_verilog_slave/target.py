#!/usr/bin/env python3

from migen import *
from litex.build.generic_platform import Subsignal


from litex_boards.platforms import colorlight_i5
from litex.soc.integration.soc_core import SoCMini
from litex.soc.integration.builder import Builder

from migen.genlib.io import CRG
from litex.soc.integration.soc import SoCRegion
from litex.soc.cores.uart import UARTWishboneBridge

from wb_slave import WishboneSlave

from litex.build.sim import SimPlatform
from litex.build.generic_platform import Pins
# Design -------------------------------------------------------------------------------------------


# Create our platform (fpga interface)
#platform = SimPlatform([ ("user_led_n",0),("clk25",0) ] , [] )
class Platform(SimPlatform):
    def __init__(self):
        _io=  [
            # Clk / Rst.
            ("clk25", 0, Pins(1)),
            ("cpu_reset_n", 0, Pins(2)),
            ("user_led_n", 0, Pins(3)),
            ("serial", 0,
                Subsignal("tx", Pins("J17")),
                Subsignal("rx", Pins("H18"))
            ),
        ]
        SimPlatform.__init__(self, "SIM", _io)

#platform = Platform()
platform = colorlight_i5.Platform(board="i9",revision="7.2")
# Create our soc (fpga description)
class BaseSoC(SoCMini):
    def __init__(self, platform, **kwargs):
        sys_clk_freq = int(25e6)

        # SoCMini (No CPU, we are controlling the SoC over UART)
        SoCMini.__init__(self, platform, sys_clk_freq, csr_data_width=32,
            ident="Little LiteX System On Chip", ident_version=True)

        # Clock Reset Generation
        self.submodules.crg = CRG(platform.request("clk25"), ~platform.request("cpu_reset_n"))

        # No CPU, use Serial to control Wishbone bus
        self.submodules.serial_bridge = UARTWishboneBridge(platform.request("serial"), sys_clk_freq)
        self.add_wb_master(self.serial_bridge.wishbone)

        # Custom wishbone slave
        self.submodules.myslave = wb_slave = WishboneSlave("dut",0x2000_0000,32*4)
        wb_slave.glue(self.platform,platform.request("user_led_n",0))
        self.bus.add_slave(wb_slave.name, wb_slave.bus , region=SoCRegion(origin=wb_slave.address, size=wb_slave.size , cached=False))

soc = BaseSoC(platform)

# Build --------------------------------------------------------------------------------------------

builder = Builder(soc, output_dir="build", csr_csv="control/csr.csv")
builder.build(build_name="top")

prog = platform.create_programmer()
prog.load_bitstream(builder.get_bitstream_filename(mode="sram"))
