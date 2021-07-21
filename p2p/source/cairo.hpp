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


#ifndef ORCHID_CAIRO_HPP
#define ORCHID_CAIRO_HPP

#include <cairo.h>

#include "fit.hpp"

namespace orc {

class Surface {
  private:
    cairo_surface_t *const handle_;

  public:
    // XXX: reconsider these types
    Surface(unsigned width, unsigned height) :
        handle_(cairo_image_surface_create(CAIRO_FORMAT_ARGB32, Fit(width), Fit(height)))
    {
        orc_assert(handle_ != nullptr);
    }

    ~Surface() {
        cairo_surface_destroy(handle_);
    }

    operator cairo_surface_t *() {
        return handle_;
    }

    std::string png() {
        std::ostringstream data;
        cairo_surface_write_to_png_stream(handle_, [](void *baton, const unsigned char *data, unsigned int size) -> cairo_status_t {
            static_cast<std::ostringstream *>(baton)->write(reinterpret_cast<const char *>(data), size);
            return CAIRO_STATUS_SUCCESS;
        }, &data);
        return data.str();
    }
};

class Cairo {
  private:
    cairo_t *const handle_;

  public:
    Cairo(cairo_surface_t *surface) :
        handle_(cairo_create(surface))
    {
    }

    ~Cairo() {
        cairo_destroy(handle_);
    }

    operator cairo_t *() {
        return handle_;
    }
};

class Scope {
  private:
    cairo_t *const handle_;

 public:
    Scope(cairo_t *handle) :
        handle_(handle)
    {
        cairo_save(handle_);
    }

    ~Scope() {
        cairo_restore(handle_);
    }
};

}

#endif//ORCHID_CAIRO_HPP
