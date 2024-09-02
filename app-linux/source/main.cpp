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


#include <gtk/gtk.h>
#include <flutter_linux/flutter_linux.h>
#include <gdk/gdkx.h>
#include "flutter/generated_plugin_registrant.h"

G_DECLARE_FINAL_TYPE(MyApplication, my_application, MY, APPLICATION, GtkApplication)

struct _MyApplication {
    GtkApplication parent_instance;
    char **dart_entrypoint_arguments;
};

// NOLINTNEXTLINE(clang-analyzer-optin.core.EnumCastOutOfRange,cppcoreguidelines-avoid-non-const-global-variables,performance-no-int-to-ptr)
G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void my_application_activate(GApplication *application) {
    const auto self(MY_APPLICATION(application));
    const auto window(GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application))));

    bool use_header_bar(true);
    if (const auto screen(gtk_window_get_screen(window)); GDK_IS_X11_SCREEN(screen)) {
        const auto wm_name(gdk_x11_screen_get_window_manager_name(screen));
        if (g_strcmp0(wm_name, "GNOME Shell") != 0)
            use_header_bar = false;
    }

    if (use_header_bar) {
        const auto header(GTK_HEADER_BAR(gtk_header_bar_new()));
        gtk_widget_show(GTK_WIDGET(header));
        gtk_header_bar_set_title(header, "Orchid");
        gtk_header_bar_set_show_close_button(header, TRUE);
        gtk_window_set_titlebar(window, GTK_WIDGET(header));
    } else {
        gtk_window_set_title(window, "Orchid");
    }

    gtk_window_set_default_size(window, 360, 640);
    gtk_widget_show(GTK_WIDGET(window));

    const auto project(fl_dart_project_new());
    fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

    const auto view(fl_view_new(project));
    gtk_widget_show(GTK_WIDGET(view));
    gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

    fl_register_plugins(FL_PLUGIN_REGISTRY(view));
    gtk_widget_grab_focus(GTK_WIDGET(view));
}

static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
    const auto self(MY_APPLICATION(application));
    self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

    g_autoptr(GError) error = nullptr;
    if (g_application_register(application, nullptr, &error) == 0) {
        g_warning("Failed to register: %s", error->message);
        *exit_status = 1;
        return TRUE;
    }

    g_application_activate(application);
    *exit_status = 0;
    return TRUE;
}

static void my_application_dispose(GObject *object) {
    const auto self(MY_APPLICATION(object));
    g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
    G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass *klass) {
    G_APPLICATION_CLASS(klass)->activate = my_application_activate;
    G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication *self) {
}

MyApplication *my_application_new() {
    return MY_APPLICATION(g_object_new(my_application_get_type(), "application-id", "net.orchid.Orchid", nullptr));
}

int main(int argc, char **argv) {
    // XXX: https://github.com/flutter/flutter/issues/57932
    gdk_set_allowed_backends("x11");
    const auto app(my_application_new());
    return g_application_run(G_APPLICATION(app), argc, argv);
}
