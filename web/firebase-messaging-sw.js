// Firebase Cloud Messaging Service Worker for Sanad App
// This file must be at the root of the web directory for FCM web push to work

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDp8R7ZqqLgSopD29L6bj7KSwWzZQedagY',
  appId: '1:152690535180:web:5d34213b46a7f6b04a3729',
  messagingSenderId: '152690535180',
  projectId: 'sanad-app-beldify',
  authDomain: 'sanad-app-beldify.firebaseapp.com',
  storageBucket: 'sanad-app-beldify.firebasestorage.app',
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);

  const notificationTitle = payload.notification?.title || payload.data?.titleAr || 'Sanad';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.bodyAr || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    tag: payload.data?.type || 'general',
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', function(event) {
  console.log('[firebase-messaging-sw.js] Notification click:', event.notification.data);
  event.notification.close();

  // Open the app when notification is clicked
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // If a window is already open, focus it
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      // Otherwise open a new window
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
