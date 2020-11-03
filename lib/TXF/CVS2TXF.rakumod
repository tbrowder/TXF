# Copyright 2012 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

unit module TXF::CVS2TXF;

class Transaction {
    # TODO why no num shares?
    #   because the num shares are part of the description on IRS Form 8949
    has      $.a-desc          is rw = ''; # Form 8949 this includes number of shares
    has Date $.b-date-acquired is rw;      # output fmt: mm/dd/yyyy
    has Date $.c-date-sold     is rw;      # output fmt: mm/dd/yyyy
    has      $.d-proceeds      is rw = 0;  # dollars (use IRS rounding rules)
    has      $.e-basis         is rw = 0;  # dollars (use IRS rounding rules)
    has      $.f-adjust-code   is rw = ''; # if any
    has      $.g-adjust-amount is rw = 0;  # dollars, if any (use IRS rounding rules)

    # boxes for Form 8949
    # Part I - Short-term:
    #   A -
    #   B -
    #   C -
    # Part II - Long-term:
    #   D -
    #   E -
    #   F -

    method txf($fh, :$debug) {
        # writes the transaction to the open txf file handle
    }

    method b-date-acquired-str() {
        # fmt: mm/dd/yyyy
    }

    method c-date-sold-str() {
        # fmt: mm/dd/yyyy
    }

} # class Transaction
