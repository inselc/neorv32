#################################################################################################
# << NEORV32 - Xilinx ASCII Memory Initialisation File (MEM) converter tool >>                  #
# ********************************************************************************************* #
# BSD 3-Clause License                                                                          #
#                                                                                               #
# Copyright (c) 2021, Stephan Nolting. All rights reserved.                                     #
# Copyright (c) 2021, islandc_.                                                                 #
#                                                                                               #
# Redistribution and use in source and binary forms, with or without modification, are          #
# permitted provided that the following conditions are met:                                     #
#                                                                                               #
# 1. Redistributions of source code must retain the above copyright notice, this list of        #
#    conditions and the following disclaimer.                                                   #
#                                                                                               #
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
#    conditions and the following disclaimer in the documentation and/or other materials        #
#    provided with the distribution.                                                            #
#                                                                                               #
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
#    endorse or promote products derived from this software without specific prior written      #
#    permission.                                                                                #
#                                                                                               #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
# OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
# ********************************************************************************************* #
# The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
#################################################################################################

import argparse

def process_args():
  parser = argparse.ArgumentParser(description='Binary to ASCII Memory Initialisation File (MEM) converter for use with Xilinx XPM Block Memory')
  parser.add_argument('infile', type=argparse.FileType('rb'), help='Input raw binary file path (e.g. \"main.bin\")')
  parser.add_argument('outfile', type=argparse.FileType('w'), help='Output MEM file path (e.g. \"imem.mem\")')
  parser.add_argument('-v', action='store_true', help='Print verbose output')
  return parser.parse_args()

if __name__ == "__main__":
  args = process_args()
  addr = 0 # word address

  rdata = args.infile.read(4)
  while rdata:
    wdata = (rdata[0] << 0) | (rdata[1] << 8) | (rdata[2] << 16) | (rdata[3] << 24)

    args.outfile.write(f"@{addr:08X} {wdata:08X}\n")
    if args.v:
      print(f"0x{addr:08X} => 0x{wdata:08X}")

    addr = addr + 1
    rdata = args.infile.read(4)

  print(f"Done ({addr} words written).")