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


#include <gtk/gtk.h>
#include <flutter_linux/flutter_linux.h>
#include "flutter/generated_plugin_registrant.h"

G_DECLARE_FINAL_TYPE(MyApplication, my_application, MY, APPLICATION, GtkApplication)

struct _MyApplication {
    GtkApplication parent_instance;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void my_application_activate(GApplication *application) {
    const auto window(GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application))));
    const auto header(GTK_HEADER_BAR(gtk_header_bar_new()));
    gtk_widget_show(GTK_WIDGET(header));
    gtk_header_bar_set_title(header, "Orchid");
    gtk_header_bar_set_show_close_button(header, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header));
    gtk_window_set_default_size(window, 360, 640);
    gtk_widget_show(GTK_WIDGET(window));

    const auto project = fl_dart_project_new();
    const auto view(fl_view_new(project));
    gtk_widget_show(GTK_WIDGET(view));
    gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

    fl_register_plugins(FL_PLUGIN_REGISTRY(view));
    gtk_widget_grab_focus(GTK_WIDGET(view));
}

static void my_application_class_init(MyApplicationClass *klass) {
    G_APPLICATION_CLASS(klass)->activate = my_application_activate;
}

static void my_application_init(MyApplication *self) {
}

MyApplication *my_application_new() {
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-vararg)
    return MY_APPLICATION(g_object_new(my_application_get_type(), "application-id", "net.orchid.Orchid", nullptr));
}

int main(int argc, char **argv) {
    // XXX: https://github.com/flutter/flutter/issues/57932
    gdk_set_allowed_backends("x11");
    const auto app(my_application_new());
    return g_application_run(G_APPLICATION(app), argc, argv);
}
