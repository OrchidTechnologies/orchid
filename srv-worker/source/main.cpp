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


#include <random>

#include <libplatform/libplatform.h>
#include <v8.h>

#include "src/execution/isolate.h"
#include "src/snapshot/snapshot.h"

#include "scope.hpp"

void Test(const v8::FunctionCallbackInfo<v8::Value> &args) {
    const auto isolate(args.GetIsolate());
    //const auto context(isolate->GetCurrentContext());
    //orc_assert(args.Length() == 1);
    v8::String::Utf8Value arg0(isolate, args[0]);
    const std::string value(*arg0, arg0.length());
    std::cerr << value << std::endl;
    (void) value;
}

int main(int argc, char *argv[], char **envp) {
    v8::V8::SetFlagsFromString("--single-threaded");

    v8::V8::InitializeICUDefaultLocation(argv[0]);
    v8::V8::InitializeExternalStartupData(argv[0]);

    v8::V8::SetEntropySource([](unsigned char *data, size_t size) {
        // XXX: this is not security critical for our daemon, but might have effects on user code
        // there isn't a good source of entropy right now in the worker process; I should add one
        // NOLINTNEXTLINE(cert-msc32-c,cert-msc51-cpp)
        static const std::independent_bits_engine<std::default_random_engine, CHAR_BIT, unsigned char> engine;
        std::generate(data, data + size, engine);
        return true;
    });

    const auto platform(v8::platform::NewSingleThreadedDefaultPlatform());
    v8::V8::InitializePlatform(platform.get());
    _scope({ v8::V8::DisposePlatform(); });

    v8::V8::Initialize();
    _scope({ v8::V8::Dispose(); });

    v8::internal::DisableEmbeddedBlobRefcounting();
    auto snapshot(v8::internal::CreateSnapshotDataBlobInternal(v8::SnapshotCreator::FunctionCodeHandling::kClear, ""));

    const auto isolate(v8::Isolate::New([&]() {
        v8::Isolate::CreateParams params;
        params.snapshot_blob = &snapshot;
        params.array_buffer_allocator_shared.reset(v8::ArrayBuffer::Allocator::NewDefaultAllocator());
        return params;
    }()));
    _scope({ isolate->Dispose(); });

    const v8::Locker locker(isolate);
    const v8::Isolate::Scope isolated(isolate);
    const v8::HandleScope scope(isolate);

    const auto context(v8::Context::New(isolate));
    const v8::Context::Scope contextualized(context);

    const auto global(context->Global());
    (void) global->Set(context, v8::String::NewFromUtf8Literal(isolate, "test"), v8::Function::New(context, &Test).ToLocalChecked());

    const auto source(v8::String::NewFromUtf8Literal(isolate, R"(
        test("test");
    )"));

    (void) v8::Script::Compile(context, source).ToLocalChecked()->Run(context);

    return 0;
}
