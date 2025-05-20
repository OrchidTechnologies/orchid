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


#ifndef ORCHID_TRIE_HPP
#define ORCHID_TRIE_HPP

#include <deque>

#include "nested.hpp"

namespace orc {

class EthDB {
  private:
    std::map<Brick<32>, Nested> cache_;

  public:
    EthDB() {
        cache_.emplace(EmptyVector, Implode(""));
    }

    const Nested &get(const Brick<32> &key) const {
        return cache_.at(key);
    }

    void put(const Brick<32> &key, Nested value) {
        cache_.emplace(key, std::move(value));
    }
};

class TrieDB {
  private:
    S<EthDB> data_;
    Brick<32> root_;

  public:
    TrieDB(S<EthDB> data) :
        data_(std::move(data)),
        root_(EmptyVector)
    {
    }
};

// XXX: this is ridiculously inefficient :/
// XXX: this almost certainly isn't correct
// XXX: I didn't even finish implementation
// (this happens to not be important code!)

class Trie {
  private:
    static size_t Prefix(std::string_view lhs, std::string_view rhs) {
        const size_t size(std::min(lhs.size(), rhs.size()));
        for (size_t i(0); i != size; ++i)
            if (lhs[i] != rhs[i])
                return i;
        return size;
    }

    class TrieNode {
      public:
        virtual ~TrieNode() = default;

        virtual void insert(U<TrieNode> &self, std::string_view key, Nested value) = 0;
        virtual std::string prove(std::deque<std::string> &proofs, std::string_view key) = 0;
    };

    class TrieHash :
        public TrieNode
    {
      private:
        Brick<32> hash_;

      public:
        void insert(U<TrieNode> &self, std::string_view key, Nested value) override {
            orc_assert(false);
        }

        std::string prove(std::deque<std::string> &proofs, std::string_view key) override {
            return hash_.str();
        }
    };

    class TrieBranch : public TrieNode {
      private:
        std::array<U<TrieNode>, 16> children_;
        Nested value_;

      public:
        TrieBranch() :
            value_(nullptr)
        {
            for (auto &child : children_)
                child = std::make_unique<TrieEmpty>();
        }

        void insert(U<TrieNode> &self, std::string_view key, Nested value) override { 
            if (key.empty())
                value_ = std::move(value);
            else {
                // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
                auto &child(children_[Bless(key[0])]);
                child->insert(child, key.substr(1), std::move(value));
            }
        }

        std::string prove(std::deque<std::string> &proofs, std::string_view key) override {
            const size_t index(key.empty() || key[0] == 'g' ? -1 : Bless(key[0]));
            std::vector<Nested> datas;
            datas.resize(17);
            for (size_t i(0); i != 16; ++i)
                // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
                datas[i] = children_[i]->prove(proofs, i == index ? key.substr(1) : "");
            datas[16] = std::move(value_);
            auto data(Implode(datas));
            const auto hash(HashK(data).str());
            if (!key.empty()) proofs.emplace_front(std::move(data));
            return hash;
        }
    };

    class TrieLeaf : public TrieNode {
      private:
        std::string key_;
        Nested value_;

      public:
        TrieLeaf(std::string key, Nested value) :
            key_(std::move(key)),
            value_(std::move(value))
        {
        }

        void insert(U<TrieNode> &self, std::string_view key, Nested value) override {
            if (key == key_)
                value_ = std::move(value);
            else {
                const auto prefix(Prefix(key_, key));

                U<TrieNode> branch(std::make_unique<TrieBranch>());
                branch->insert(branch, key_.substr(prefix), std::move(value_));
                branch->insert(branch, key.substr(prefix), std::move(value));

                if (prefix == 0)
                    self = std::move(branch);
                else
                    self = std::make_unique<TrieExtension>(std::string(key.substr(0, prefix)), std::move(branch));
            }
        }

        std::string prove(std::deque<std::string> &proofs, std::string_view key) override {
            auto data(Implode({Bless((key_.size() % 2 == 0 ? "20" : "3") + key_).str(), value_}));
            const auto hash(HashK(data).str());
            if (!key.empty()) proofs.emplace_front(std::move(data));
            return hash;
        }
    };

    class TrieEmpty : public TrieNode {
      public:
        void insert(U<TrieNode> &self, std::string_view key, Nested value) override {
            self = std::make_unique<TrieLeaf>(std::string(key), value);
        }

        std::string prove(std::deque<std::string> &proofs, std::string_view key) override {
            return {};
        }
    };

    class TrieExtension : public TrieNode {
      private:
        std::string key_;
        U<TrieNode> child_;

      public:
        TrieExtension(std::string key, U<TrieNode> child) :
            key_(std::move(key)),
            child_(std::move(child))
        {
        }

        void insert(U<TrieNode> &self, std::string_view key, Nested value) override {
            orc_assert(false);
        }

        std::string prove(std::deque<std::string> &proofs, std::string_view key) override {
            orc_assert(false);
        }
    };

    U<TrieNode> root_;

  public:
    Trie() :
        root_(std::make_unique<TrieEmpty>())
    {
    }

    void insert(std::string_view key, Nested value) {
        root_->insert(root_, key, std::move(value));
    }

    std::deque<std::string> prove(const std::string &key) {
        std::deque<std::string> proofs;
        root_->prove(proofs, key + 'g');;
        return proofs;
    }
};

}

#endif//ORCHID_TRIE_HPP
