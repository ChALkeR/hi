#ifndef NATIVE_H
#define NATIVE_H

#include <QObject>

#ifdef Q_OS_ANDROID
#include <jni.h>
extern "C"
{
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativePing(JNIEnv *env, jobject obj, jint value);
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativeApplicationStatus(JNIEnv *env, jobject obj, jint status);
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativeNearbyStatus(JNIEnv *env, jobject obj, jint status, jint mode);
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativeNearbySubscription(JNIEnv *env, jobject obj, jint status, jint mode);
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativeNearbyMessage(JNIEnv *env, jobject obj, jint status, jstring message, jstring type);
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativeNearbyOwnMessage(JNIEnv *env, jobject obj, jint status, jint id, jstring message, jstring type);
}
#endif
#ifdef Q_OS_IOS
#include "ios/iosnative.h"
#endif

class Native : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int applicationStatus READ applicationStatus WRITE setApplicationStatus NOTIFY applicationStatusChanged)
    Q_PROPERTY(int nearbyStatus READ nearbyStatus NOTIFY nearbyStatusChanged)
    Q_PROPERTY(int nearbyMode READ nearbyMode NOTIFY nearbyModeChanged)
    Q_PROPERTY(int nearbySubscriptionStatus READ nearbySubscriptionStatus NOTIFY nearbySubscriptionStatusChanged)
    Q_PROPERTY(int nearbySubscriptionMode READ nearbySubscriptionMode NOTIFY nearbySubscriptionModeChanged)

public:
    explicit Native(QObject *parent = nullptr);
    ~Native();

    static Native *instance();

    int applicationStatus() const;
    void setApplicationStatus(int applicationStatus);
    void setNearbyStatusMode(int status, int mode);
    void setNearbySubscriptionStatusMode(int status, int mode);
    int nearbyStatus() const;
    int nearbyMode() const;
    int nearbySubscriptionStatus() const;
    int nearbySubscriptionMode() const;

signals:
    void applicationStatusChanged();
    void nearbyStatusChanged();
    void nearbyModeChanged();
    void nearbySubscriptionStatusChanged();
    void nearbySubscriptionModeChanged();
    void ping(int value);
    void nearbyMessage(int status, QString message, QString type);
    void nearbyOwnMessage(int status, int id, QString message, QString type);

public slots:
    void nearbyConnect(int mode, bool bleOnly = true);
    void nearbyDisconnect();
    void nearbySubscribe(int mode = 0);
    int publishMessage(const QString &message, const QString &type = "");
    void unpublishMessage(int id);
    void notify(QString title, QString text);

private:
    static Native *m_instance;
public:
    static int s_applicationStatus;
    static int s_nearbyStatus;
    static int s_nearbyMode;
    static int s_nearbySubscriptionStatus;
    static int s_nearbySubscriptionMode;
};

#endif // NATIVE_H
