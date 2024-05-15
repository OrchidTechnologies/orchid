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


#include "base58.hpp"
#include "crypto.hpp"

namespace orc {

// https://bitcoin.stackexchange.com/questions/76480/encode-decode-base-58-c

inline static constexpr const uint8_t Base58Map[] = {
    '1', '2', '3', '4', '5', '6', '7', '8',
    '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
    'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q',
    'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y',
    'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g',
    'h', 'i', 'j', 'k', 'm', 'n', 'o', 'p',
    'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
    'y', 'z', // I hate Base58 quite a lot,
};

inline static constexpr const uint8_t AlphaMap[] = {
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0xff, 0x11, 0x12, 0x13, 0x14, 0x15, 0xff,
    0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0xff, 0x2c, 0x2d, 0x2e,
    0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0xff, 0xff, 0xff, 0xff, 0xff,
};

using CodecMapping = struct _codecmapping
{
  _codecmapping(const uint8_t* amap, const uint8_t* bmap) : AlphaMapping(amap), BaseMapping(bmap) {}
  const uint8_t* AlphaMapping;
  const uint8_t* BaseMapping;
};

std::string Base58Encode(const std::vector<uint8_t>& data, CodecMapping mapping)
{
  std::vector<uint8_t> digits((data.size() * 138 / 100) + 1);
  size_t digitslen = 1;
  for (size_t i = 0; i < data.size(); i++)
  {
    uint32_t carry = static_cast<uint32_t>(data[i]);
    for (size_t j = 0; j < digitslen; j++)
    {
      carry = carry + static_cast<uint32_t>(digits[j] << 8);
      digits[j] = static_cast<uint8_t>(carry % 58);
      carry /= 58;
    }
    for (; carry != 0; carry /= 58)
      digits[digitslen++] = static_cast<uint8_t>(carry % 58);
  }
  std::string result;
  for (size_t i = 0; i < (data.size() - 1) && data[i] == 0; i++)
    result.push_back(char(mapping.BaseMapping[0]));
  for (size_t i = 0; i < digitslen; i++)
    result.push_back(char(mapping.BaseMapping[digits[digitslen - 1 - i]]));
  return result;
}

std::vector<uint8_t> Base58Decode(const std::string& data, CodecMapping mapping)
{
  std::vector<uint8_t> result((data.size() * 138 / 100) + 1);
  size_t resultlen = 1;
  for (size_t i = 0; i < data.size(); i++)
  {
    uint32_t carry = static_cast<uint32_t>(mapping.AlphaMapping[data[i] & 0x7f]);
    for (size_t j = 0; j < resultlen; j++, carry >>= 8)
    {
      carry += static_cast<uint32_t>(result[j] * 58);
      result[j] = static_cast<uint8_t>(carry);
    }
    for (; carry != 0; carry >>=8)
      result[resultlen++] = static_cast<uint8_t>(carry);
  }
  result.resize(resultlen);
  for (size_t i = 0; i < (data.size() - 1) && data[i] == mapping.BaseMapping[0]; i++)
    result.push_back(0);
  std::reverse(result.begin(), result.end());
  return result;
}

std::string ToBase58(const Buffer &data) {
    // XXX: reimplement with scatter/gather
    return Base58Encode(data.vec(), {AlphaMap, Base58Map});
}

std::string ToBase58Check(const Buffer &data) {
    return ToBase58(Tie(data, Hash2(Hash2(Tie(data))).Clip<0, 4>()));
}

}
