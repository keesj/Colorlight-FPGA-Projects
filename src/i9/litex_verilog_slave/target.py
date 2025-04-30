#!/usr/bin/env python3

#
# This file is part of LiteX-Boards.
#
# Copyright (c) 2021 Kazumoto Kojima <kkojima@rr.iij4u.or.jp>
# SPDX-License-Identifier: BSD-2-Clause

from migen import *
import sys

from litex_boards.targets import colorlight_i5 as board
from litex_boards.platforms import colorlight_i5

from litex.soc.cores.clock import *
from litex.soc.integration.soc_core import *
from litex.soc.integration.soc import SoCRegion
from litex.soc.integration.builder import *
from litex.soc.cores.video import VideoHDMIPHY
from litex.soc.cores.led import LedChaser

from litex.soc.interconnect.csr import *

from litedram.modules import M12L64322A # Compatible with EM638325-6H.
from litedram.phy import GENSDRPHY, HalfRateGENSDRPHY

from liteeth.phy.ecp5rgmii import LiteEthPHYRGMII

def main():
    from litex.build.parser import LiteXArgumentParser
    parser = LiteXArgumentParser(platform=colorlight_i5.Platform, description="LiteX SoC on Colorlight I5.")
    parser.add_target_argument("--board",            default="i9",             help="Board type (i9).")
    parser.add_target_argument("--revision",         default="7.2",            help="Board revision (7.2).")
    parser.add_target_argument("--sys-clk-freq",     default=60e6, type=float, help="System clock frequency.")
    ethopts = parser.target_group.add_mutually_exclusive_group()
    ethopts.add_argument("--with-ethernet",   action="store_true",      help="Enable Ethernet support.")
    ethopts.add_argument("--with-etherbone",  action="store_true",      help="Enable Etherbone support.")
    parser.add_target_argument("--remote-ip", default="192.168.1.100",  help="Remote IP address of TFTP server.")
    parser.add_target_argument("--local-ip",  default="192.168.1.50",   help="Local IP address.")
    sdopts = parser.target_group.add_mutually_exclusive_group()
    sdopts.add_argument("--with-spi-sdcard",  action="store_true", help="Enable SPI-mode SDCard support.")
    sdopts.add_argument("--with-sdcard",      action="store_true", help="Enable SDCard support.")
    parser.add_target_argument("--eth-phy",          default=0, type=int, help="Ethernet PHY (0 or 1).")
    parser.add_target_argument("--use-internal-osc", action="store_true", help="Use internal oscillator.")
    parser.add_target_argument("--sdram-rate",       default="1:1",       help="SDRAM Rate (1:1 Full Rate or 1:2 Half Rate).")
    viopts = parser.target_group.add_mutually_exclusive_group()
    viopts.add_argument("--with-video-terminal",    action="store_true", help="Enable Video Terminal (HDMI).")
    viopts.add_argument("--with-video-framebuffer", action="store_true", help="Enable Video Framebuffer (HDMI).")
    args = parser.parse_args()

    soc = board.BaseSoC(board=args.board, revision=args.revision,
        toolchain              = args.toolchain,
        sys_clk_freq           = args.sys_clk_freq,
        with_ethernet          = args.with_ethernet,
        with_etherbone         = args.with_etherbone,
        local_ip               = args.local_ip,
        remote_ip              = args.remote_ip,
        eth_phy                = args.eth_phy,
        use_internal_osc       = args.use_internal_osc,
        sdram_rate             = args.sdram_rate,
        with_video_terminal    = args.with_video_terminal,
        with_video_framebuffer = args.with_video_framebuffer,
        with_led_chaser        = False,
        **parser.soc_argdict
    )
    soc.platform.add_extension(colorlight_i5._sdcard_pmod_io)
    if args.with_spi_sdcard:
        soc.add_spi_sdcard()
    if args.with_sdcard:
        soc.add_sdcard()

    # The real work
    led_out = soc.platform.request("user_led_n")
    soc.specials += Instance("led", i_clk_i = ClockSignal(), i_rst_i = ResetSignal(), o_out_o = led_out )
    soc.platform.add_source("led.v")

    # wishbone slave
    myslave =  Instance("myslave",
                        i_clk_i = ClockSignal(),
                        i_rst_i = ResetSignal(),
                        i_cyc = Signal(name="wb_cyc_i")
                        )
#                        i_stb = "wb_stb_i,
#                        i_we = "wb_we_i,
##                        i_adr = "wb_addr_i,
#                        i_dat_w = "wb_data_i,
#                        i_sel = "wb_sel_i,
#                        o_ack = "wb_ack_o,
#                        o_dat_r = "wb_data_o)
    soc.specials += myslave
    soc.platform.add_source("slave.v")
    soc.bus.add_slave(name="myslave", slave=myslave, region=SoCRegion(
           origin = 0x2000_0000,
           size   = 32*4,
     ))
    #soc.bus.add_slave(name="myslave", slave=self.ws2812.bus, region=SoCRegion(

    builder = Builder(soc, **parser.builder_argdict)
    if args.build:
        builder.build(**parser.toolchain_argdict)

    if args.load:
        prog = soc.platform.create_programmer()
        prog.load_bitstream(builder.get_bitstream_filename(mode="sram"))

if __name__ == "__main__":
    main()
