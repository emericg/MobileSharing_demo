#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <MobileSharing>
#include <MobileUI>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Application name
    app.setApplicationName("MobileSharing demo");
    app.setApplicationDisplayName("MobileSharing demo");
    app.setOrganizationName("emeric");
    app.setOrganizationDomain("emeric");

    // Start the UI
    QQmlApplicationEngine engine;

    engine.loadFromModule("MobileSharing_demo", "MobileApplication");

    if (engine.rootObjects().isEmpty())
    {
        qWarning() << "Cannot init QmlApplicationEngine!";
        return EXIT_FAILURE;
    }

    return app.exec();
}
