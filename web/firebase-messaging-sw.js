// Import Firebase scripts for FCM
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Firebase configuration - from your firebase_options.dart
firebase.initializeApp({
  apiKey: "AIzaSyCVeYEr6B7XRmZD04h5YHhcHYn3aPxQ61A",
  authDomain: "pharmacy-employee-system-new.firebaseapp.com",
  projectId: "pharmacy-employee-system-new",
  storageBucket: "pharmacy-employee-system-new.firebasestorage.app",
  messagingSenderId: "697326974813",
  appId: "1:697326974813:web:ea1c24fa7b0a4e99f9ad13",
  measurementId: "G-2HHSM3MTGZ"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  const notificationTitle = payload.notification?.title || 'إشعار جديد';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    tag: 'pharmacy-notification',
    requireInteraction: true,
    vibrate: [200, 100, 200],
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event);

  event.notification.close();

  // Open the app when notification is clicked
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // If app is already open, focus it
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      // Otherwise open new window
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

console.log('[firebase-messaging-sw.js] Service worker loaded');
