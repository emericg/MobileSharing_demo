#ifndef DEMOBACKEND_H
#define DEMOBACKEND_H
/* ************************************************************************** */

#include <QObject>
#include <QString>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

/* ************************************************************************** */

/*!
 * \brief Demo-only helper for the file I/O the QML layer cannot do itself
 *
 * Used by the "save file" mini-test to:
 *  - generate a small throwaway sample file to export, and
 *  - attempt the "Qt way" of writing to a picker-chosen URL, which fails on Android
 *    SAF content:// destinations (the very reason MobileSharing::saveFile() exists).
 */
class DemoBackend : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit DemoBackend(QObject *parent = nullptr);

    //! Write a small throwaway text file into dirPath; returns its path, or "" on failure.
    Q_INVOKABLE QString createSampleFile(const QString &dirPath);

    //! Copy sourcePath to destUrl using Qt's QFile (the "Qt way"); returns true on success.
    Q_INVOKABLE bool exportViaQFile(const QString &sourcePath, const QUrl &destUrl);

    //! Copy sourcePath into destDir (created on demand, collision-safe); returns the new path, or "".
    Q_INVOKABLE QString copyToDirectory(const QString &sourcePath, const QString &destDir);
};

/* ************************************************************************** */
#endif // DEMOBACKEND_H
