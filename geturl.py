#!/usr/bin/env python
#
# Simple URL downloader (for testing islandhack)
#
# Copyright (c) 2019 Benjamin Moody
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import sys
import os
try:
    from urllib.request import urlopen
except ImportError:
    from urllib2 import urlopen

os.write(1, urlopen(sys.argv[1]).read())
