#################################################################################################
# << NEORV32 - Memory Init File converter script >>                                             #
# ********************************************************************************************* #
# BSD 3-Clause License                                                                          #
#                                                                                               #
# Copyright (c) 2020, Stephan Nolting.                                                          #
# Copyright (c) 2020, islandc_.                                                                 #
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

import io
import argparse
import struct

if __name__ == "__main__":

  parser = argparse.ArgumentParser(description='Generates 32-bit aligned memory initialisation file from a binary image')
  parser.add_argument('infile', metavar='infile', type=str, nargs=1, help='Input file')
  parser.add_argument('outfile', metavar='outfile', type=str, nargs=1, help='Output file (*.mif)')
  args = parser.parse_args()

  with open(args.infile[0], "rb") as infile:
    infile.seek(0, io.SEEK_END)
    inlength = infile.tell()
    infile.seek(0, io.SEEK_SET)

    with open(args.outfile[0], "w") as outfile:
      depth = inlength / 4

      outfile.write("WIDTH = 32;\n")
      outfile.write(f"DEPTH = {int(depth)};\n\n")
      outfile.write("ADDRESS_RADIX = HEX;\n")
      outfile.write("DATA_RADIX = HEX;\n")
      outfile.write("\n")
      outfile.write("CONTENT BEGIN\n")

      adr = 0
      read_bytes = infile.read(4)
      while read_bytes:
        word = struct.unpack("<I", read_bytes)
        outfile.write(f"\t{adr:08X} : {word[0]:08X};\n")
        adr += 1
        read_bytes = infile.read(4)
      
      outfile.write("\nEND;")