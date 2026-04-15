const admin = require('firebase-admin');

// Use the local ADC or project ID
admin.initializeApp({
          projectId: 'sanad-app-beldify'
});

const db = admin.firestore();

async function listCollections() {
          try {
                    const collections = await db.listCollections();
                    console.log(`Total collections: ${collections.length}`);
                    collections.forEach(collection => {
                              console.log(`- ${collection.id}`);
                    });
          } catch (error) {
                    console.error('Error listing collections:', error);
          }
}

listCollections();
