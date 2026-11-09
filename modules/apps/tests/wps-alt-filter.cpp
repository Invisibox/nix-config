// Compile with WPS_ALT_FILTER_PLUGIN against WPS's bundled Qt, then load that
// shared object with the loader below and LD_PRELOAD pointing to the filter.
#include <cassert>
#include <cstdio>

#ifdef WPS_ALT_FILTER_PLUGIN
#include <QtWidgets/QApplication>
#include <QtWidgets/QWidget>
#include <QtGui/QInputMethodEvent>
#include <QtGui/QKeyEvent>

using namespace kso_qt;

// WPS adds an optional platform configuration to the Qt constructor.
extern "C" void bundledConstructor(void *, int &, char **, int, void *)
    asm("_ZN6kso_qt12QApplicationC2ERiPPciPNS_26QPlatformIntegrationConfigE");
extern "C" void headerConstructor(void *, int &, char **, int)
    asm("_ZN6kso_qt12QApplicationC2ERiPPci");
extern "C" void headerConstructor(void *self, int &argc, char **argv, int flags) {
    bundledConstructor(self, argc, argv, flags, nullptr);
}

class Application : public QApplication {
public:
    using QApplication::QApplication;
    bool notify(QObject *receiver, QEvent *event) override {
        return QApplication::notify(receiver, event);
    }
};

class Receiver : public QWidget {
public:
    int keyEvents = 0, keyPresses = 0, inputMethods = 0, otherEvents = 0;
    Qt::KeyboardModifiers lastModifiers;

    bool event(QEvent *event) override {
        switch (event->type()) {
        case QEvent::KeyPress:
            ++keyPresses;
            lastModifiers = static_cast<QKeyEvent *>(event)->modifiers();
            [[fallthrough]];
        case QEvent::KeyRelease:
        case QEvent::ShortcutOverride:
            ++keyEvents;
            return true;
        case QEvent::InputMethod:
            ++inputMethods;
            return true;
        case QEvent::User:
            ++otherEvents;
            return true;
        default:
            return QWidget::event(event);
        }
    }
};

extern "C" void runChecks() {
    int argc = 1;
    char name[] = "wps-alt-filter-test";
    char *argv[] = {name, nullptr};
    Application app(argc, argv);
    Receiver receiver;

    for (auto type : {QEvent::KeyPress, QEvent::KeyRelease, QEvent::ShortcutOverride}) {
        QKeyEvent event(type, Qt::Key_Alt, Qt::NoModifier);
        QCoreApplication::sendEvent(&receiver, &event);
    }
    assert(receiver.keyEvents == 0);

    for (auto modifiers : {Qt::NoModifier, Qt::ControlModifier, Qt::ShiftModifier,
                           Qt::GroupSwitchModifier, Qt::AltModifier}) {
        QKeyEvent event(QEvent::KeyPress, Qt::Key_A, modifiers);
        QCoreApplication::sendEvent(&receiver, &event);
        assert(receiver.lastModifiers == modifiers);
    }
    assert(receiver.keyPresses == 5);

    QInputMethodEvent inputMethod;
    QCoreApplication::sendEvent(&receiver, &inputMethod);
    assert(receiver.inputMethods == 1);
    QEvent other(QEvent::User);
    QCoreApplication::sendEvent(&receiver, &other);
    assert(receiver.otherEvents == 1);
}

#else
#include <dlfcn.h>

int main(int argc, char **argv) {
    assert(argc == 2);
    void *plugin = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (!plugin) std::fputs(dlerror(), stderr);
    assert(plugin);
    auto run = reinterpret_cast<void (*)()>(dlsym(plugin, "runChecks"));
    assert(run);
    run();
    std::puts("PASS: RTLD_LOCAL Qt, Alt filtering, key modifiers, IME and other events.");
}
#endif
