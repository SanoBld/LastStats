#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Remembers whether the window was maximized when last closed, so it can
// reopen the same way next time — otherwise Windows always starts it at the
// default windowed size, ignoring the taskbar.
constexpr wchar_t kRegKey[]       = L"Software\\LastStats";
constexpr wchar_t kRegValueName[] = L"WindowMaximized";

bool WasMaximizedLastTime() {
  HKEY key;
  if (::RegOpenKeyEx(HKEY_CURRENT_USER, kRegKey, 0, KEY_READ, &key) != ERROR_SUCCESS) {
    return false;
  }
  DWORD value = 0;
  DWORD size  = sizeof(value);
  DWORD type  = REG_DWORD;
  bool result = false;
  if (::RegQueryValueEx(key, kRegValueName, nullptr, &type,
                         reinterpret_cast<LPBYTE>(&value), &size) == ERROR_SUCCESS) {
    result = (value != 0);
  }
  ::RegCloseKey(key);
  return result;
}

void SaveMaximizedState(bool maximized) {
  HKEY key;
  if (::RegCreateKeyEx(HKEY_CURRENT_USER, kRegKey, 0, nullptr, 0, KEY_WRITE,
                        nullptr, &key, nullptr) != ERROR_SUCCESS) {
    return;
  }
  DWORD value = maximized ? 1 : 0;
  ::RegSetValueEx(key, kRegValueName, 0, REG_DWORD,
                   reinterpret_cast<const BYTE*>(&value), sizeof(value));
  ::RegCloseKey(key);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"LastStats", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Restore maximized state from the previous session, if any.
  if (WasMaximizedLastTime()) {
    ::ShowWindow(window.GetHandle(), SW_MAXIMIZE);
  }

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    // Remember the maximized state right before the window actually closes,
    // so the next launch can restore it.
    if (msg.message == WM_CLOSE && msg.hwnd == window.GetHandle()) {
      SaveMaximizedState(::IsZoomed(window.GetHandle()) != 0);
    }
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
