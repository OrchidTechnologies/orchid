/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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


#include <iomanip>
#include <sstream>
#include <vector>

#include "chart.hpp"

namespace orc {

void Chart(std::ostream &out, unsigned width, unsigned height, const std::function<float (float)> &axis, const std::function<float (float)> &value, const std::function<void (std::ostream &, float)> &label) {
    std::vector<float> values(width);
    const auto stride(1.0f / float(width - 1));
    for (unsigned i(0); i != width; ++i)
        values[i] = value(axis(float(i) * stride));

    const auto step(1.0f / float(height - 1));
    for (unsigned i(0); i != height; ++i) {
        const auto y(1.0f - float(i) * step);
        for (unsigned i(0); i != width; ++i) {
            const auto x(values[i]);
            out << (
                x < y + step * 1 / 3 ? ' ' :
                x < y + step * 2 / 3 ? '.' :
                x < y + step * 3 / 3 ? 'x' :
            '#');
        }

        label(out, y);
        out << '\n';
    }

    for (unsigned i(0); i < width;) {
        std::ostringstream tmp;
        const auto x(axis(float(i) * stride));
        if (x == 0)
            tmp << '0';
        else
            tmp << std::fixed << std::setprecision(1) << x;
        const auto name(tmp.str());
        out << '\\' << name;
        i += 1 + name.size();
    }
    out << '\n';
}

}
