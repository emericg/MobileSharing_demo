#include "DemoBackend.h"

#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDateTime>
#include <QDebug>

/* ************************************************************************** */

DemoBackend::DemoBackend(QObject *parent) : QObject(parent)
{
    //
}

/* ************************************************************************** */

QString DemoBackend::createSampleFile(const QString &dirPath)
{
    QDir().mkpath(dirPath);

    const QString path = dirPath + "/sample_" + QString::number(QDateTime::currentMSecsSinceEpoch()) + ".txt";

    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        qWarning() << "createSampleFile: cannot write" << path;
        return QString();
    }

    f.write(QStringLiteral("MobileSharing demo sample file\nGenerated at %1\n")
                .arg(QDateTime::currentDateTime().toString(Qt::ISODate)).toUtf8());
    f.close();

    qDebug() << "createSampleFile:" << path;
    return path;
}

bool DemoBackend::exportViaQFile(const QString &sourcePath, const QUrl &destUrl)
{
    // The "Qt way": hand QFile whatever URL the picker returned. Works for a local
    // file:// path, but fails for an Android SAF content:// URL - which is the point.
    const QString destPath = destUrl.isLocalFile() ? destUrl.toLocalFile() : destUrl.toString();
    qDebug() << "exportViaQFile:" << sourcePath << "->" << destPath;

    QFile::remove(destPath); // QFile::copy() refuses to overwrite an existing file
    const bool ok = QFile::copy(sourcePath, destPath);
    if (!ok)
    {
        qWarning() << "exportViaQFile: QFile::copy failed (expected on Android SAF content URIs)";
    }
    return ok;
}

QString DemoBackend::copyToDirectory(const QString &sourcePath, const QString &destDir)
{
    const QFileInfo src(sourcePath);
    if (!src.exists() || !src.isFile())
    {
        qWarning() << "copyToDirectory: not a file:" << sourcePath;
        return QString();
    }

    QDir().mkpath(destDir);

    QString dest = destDir + '/' + src.fileName();
    if (QFileInfo::exists(dest))
    {
        // Don't clobber a file of the same name: insert a timestamp before the extension.
        const QString suffix = src.suffix().isEmpty() ? QString() : '.' + src.suffix();
        dest = destDir + '/' + src.completeBaseName() + '_'
             + QString::number(QDateTime::currentMSecsSinceEpoch()) + suffix;
    }

    if (!QFile::copy(sourcePath, dest))
    {
        qWarning() << "copyToDirectory: failed to copy" << sourcePath << "->" << dest;
        return QString();
    }

    qDebug() << "copyToDirectory:" << sourcePath << "->" << dest;
    return dest;
}

/* ************************************************************************** */
