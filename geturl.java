// Simple URL downloader (for testing islandhack)
//
// Copyright (c) 2019 Benjamin Moody
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
// License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import java.net.URL;
import java.net.URLConnection;
import java.io.InputStream;

class geturl
{
    public static void main(String[] args)
    {
        try {
            URL url = new URL(args[0]);
            URLConnection conn = url.openConnection();
            InputStream is = conn.getInputStream();
            byte[] b = new byte[4096];
            int n;
            while ((n = is.read(b)) > 0)
                System.out.write(b, 0, n);
        }
        catch (Exception e) {
            System.err.println(e.toString());
            System.exit(1);
        }
    }
}
