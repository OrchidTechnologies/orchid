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


#ifndef ORCHID_PILE_HPP
#define ORCHID_PILE_HPP

#include <map>

namespace orc {

template <typename Value_, typename Weight_>
class Pile {
  private:
    Weight_ weight_ = 0;
    std::multimap<Value_, Weight_> weights_;

  public:
    void operator()(const Value_ &value, const Weight_ &weight) {
        weight_ += weight;
        weights_.emplace(value, weight);
    }

    bool any() const {
        return weights_.size() != 0;
    }

    const Weight_ &sum() const {
        orc_assert(any());
        return weight_;
    }

    const Value_ &val(Weight_ offset) const {
        for (const auto &[value, weight] : weights_)
            if (offset <= weight)
                return value;
            else offset -= weight;
        orc_assert(false);
    }

    const Value_ &min() const {
        orc_assert(!weights_.empty());
        return weights_.begin()->first;
    }

    const Value_ &max() const {
        orc_assert(!weights_.empty());
        return (weights_.end() - 1)->first;
    }

    const Value_ &med() const {
        return val(weight_ / 2);
    }
};

}

#endif//ORCHID_PILE_HPP
