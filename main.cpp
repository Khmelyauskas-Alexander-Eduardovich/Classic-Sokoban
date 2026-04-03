#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQml> // Для работы с QML движком
// Вместо <QtSql>
#include <QtSql/QSqlDatabase>
int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication *app = new QGuiApplication(argc, (char**)argv);

    app->setApplicationName("sokoban-classic.jwb-bravada");

    QQmlApplicationEngine engine;

    // Укажи правильный путь к твоему main.qml

    const QUrl url(QStringLiteral("qrc:/main.qml"));

    // Передаем app напрямую, без символа &
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);



    engine.load(url);



    return app->exec();

}
/*#include <QGuiApplication>
#include <QCoreApplication>
#include <QUrl>
#include <QString>
#include <QQuickView>
#include <QQmlEngine>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>

int main(int argc, char *argv[])
{
    // Используем выделение в куче
    QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
    
    // Имя должно СТРОГО совпадать с манифестом для доступа к песочнице
    app->setApplicationName("sokoban-classic.jwb-bravada");

    qDebug() << "Starting app from main.cpp";

    QQuickView *view = new QQuickView();

    // --- РЕШЕНИЕ ДЛЯ SQL (ХАЛЯЛЬНЫЙ ПУТЬ) ---
    QString storagePath;
    if (qEnvironmentVariableIsSet("APP_ID")) {
        // Путь для Ubuntu Touch
        storagePath = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) 
                      + "/sokoban-classic.jwb-bravada";
    } else {
        // Путь для Windows
        storagePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    }

    // Создаем папку вручную, чтобы LocalStorage не ругался
    QDir dir(storagePath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    // Привязываем путь к движку этого конкретного view
    view->engine()->setOfflineStoragePath(storagePath);
    qDebug() << "SQL Path set to:" << view->engine()->offlineStoragePath();
    // ---------------------------------------

    view->setSource(QUrl("qrc:/main.qml"));
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->show();

    return app->exec();
}*/