const admin = require("firebase-admin");

admin.initializeApp({
  projectId: "flashixy"
});

const db = admin.firestore();

// your JSON backup
const backup = require("/home/bc/Desktop/experimental/firestore_backup.json");

async function restore() {
  for (const [collection, docs] of Object.entries(backup)) {
    for (const [docId, data] of Object.entries(docs)) {
      await db.collection(collection).doc(docId).set(data);
    }
  }

  console.log("Import done");
}

restore();
