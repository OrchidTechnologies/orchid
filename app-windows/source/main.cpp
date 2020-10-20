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


#include <windows.h>
#include <combaseapi.h>

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include "flutter_window.h"
#include "run_loop.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE hPrevInstance, _In_ wchar_t *lpCmdLine, _In_ int nShowCmd) {
    // Attach to console when present (e.g., 'flutter run') or create a
    // new console when running with a debugger.
    if (::AttachConsole(ATTACH_PARENT_PROCESS) == 0 && ::IsDebuggerPresent() != 0)
        CreateAndAttachConsole();

    // Initialize COM, so that it is available for use in the library and/or
    // plugins.
    ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

    RunLoop run_loop;

    flutter::DartProject project(L"data");
    FlutterWindow window(&run_loop, project);
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(360, 640);
    if (!window.CreateAndShow(L"orchid", origin, size))
        return EXIT_FAILURE;
    window.SetQuitOnClose(true);

    run_loop.Run();

    ::CoUninitialize();
    return EXIT_SUCCESS;
}
