#ifndef NATIVE_H
#define NATIVE_H

#include <QObject>

#ifdef Q_OS_ANDROID
#include <jni.h>
extern "C"
{
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativePing(JNIEnv *env, jobject obj, jint value);
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativeApiStatus(JNIEnv *env, jobject obj, jint status);
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativeNearbySubscription(JNIEnv *env, jobject obj, jint status, jint mode);
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativeNearbyMessage(JNIEnv *env, jobject obj, jint status, jstring message, jstring type);
JNIEXPORT void JNICALL Java_org_oserv_qtandroid_MainActivity_nativeNearbyOwnMessage(JNIEnv *env, jobject obj, jint status, jint id, jstring message, jstring type);
}
#endif

class Native : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int apiStatus READ apiStatus WRITE setApiStatus NOTIFY apiStatusChanged)
    Q_PROPERTY(int nearbySubscriptionStatus READ nearbySubscriptionStatus NOTIFY nearbySubscriptionStatusChanged)
    Q_PROPERTY(int nearbySubscriptionMode READ nearbySubscriptionMode NOTIFY nearbySubscriptionModeChanged)

public:
    explicit Native(QObject *parent = nullptr);
    ~Native();

    static Native *instance();

    void setApiStatus(int apiStatus);
    void setNearbySubscriptionStatusMode(int status, int mode);
    int apiStatus() const;
    int nearbySubscriptionStatus() const;
    int nearbySubscriptionMode() const;

signals:
    void apiStatusChanged();
    void nearbySubscriptionStatusChanged();
    void nearbySubscriptionModeChanged();
    void ping(int value);
    void nearbyMessage(int status, QString message, QString type);
    void nearbyOwnMessage(int status, int id, QString message, QString type);

public slots:
    void apiConnect();
    void nearbyDisconnect();
    void nearbySubscribe();
    int publishMessage(const QString &message, const QString &type = "");
    void unpublishMessage(int id);
    void notify(QString title, QString text);

private:
    static Native *m_instance;
public:
    static int s_apiStatus;
    static int s_nearbySubscriptionStatus;
    static int s_nearbySubscriptionMode;
};

#endif // NATIVE_H
