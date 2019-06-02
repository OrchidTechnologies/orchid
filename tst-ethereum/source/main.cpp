/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2019  The Orchid Authors
*/

/* GNU Affero General Public License, Version 3 {{{ */
/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */



#include <string>
#include <cstdio>
#include <iostream>
#include <fstream>
#include <sstream>
#include "tests.h"



// ============================ ===================================



	std::string file_to_string(std::string fn)
	{
		std::ifstream myfile;
		myfile.open(fn.c_str());
		if (myfile.is_open()) {
			std::stringstream buffer;
			buffer << myfile.rdbuf();
			return buffer.str();
		} else {
			printf("failed to open infile %s \n", fn.c_str());
			return "";
		}
		myfile.close();
		return "";
	}

	bool string_to_file(std::string x, std::string fn) {
		bool bresult;
		std::ofstream myfile;
		myfile.open(fn);
		if (myfile.is_open()) {
			myfile << x;
			bresult = true;
		} else {
			printf("failed to open outfile %s \n", fn.c_str());
			bresult = false;
		}
		myfile.close();
		return bresult;
	}


// ============================ ===================================

int main(int argc, char* argv[]) 
{
    if (argc > 1) {
        if      (argv[1] == std::string("test_lot")) { return orc::test_lot(); }
        else if (argv[1] == std::string("test_dir")) { return orc::test_dir(); }
    }
}
