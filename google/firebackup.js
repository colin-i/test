const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path'); // Make sure path is required

// Replace with the actual path to your service account key file for 'flashixy'
// For example: './flashixy-credentials.json'
const serviceAccountPath = path.resolve(__dirname, './flashixy-credentials.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath))
});

const db = admin.firestore();

// --- Configuration ---
// Construct the output path using process.env.HOME
const outputDirectory = path.join(process.env.HOME, 'Desktop', 'experimental');
const outputFileName = path.join(outputDirectory, 'firestore_backup.json'); // Full path to the backup file

const collectionsToBackup = [
  'Chambers',
  'names',
  'orphanScores',
  'plays',
  'usernames'
  // Add other top-level collections you want to back up
];
// If you want to backup ALL top-level collections, leave collectionsToBackup empty or uncomment below:
// const collectionsToBackup = null;

// --- Backup Function ---
async function backupFirestore() {
  console.log('Starting Firestore backup...');
  const allData = {};

  try {
    // Ensure the output directory exists
    if (!fs.existsSync(outputDirectory)) {
      console.log(`Creating output directory: ${outputDirectory}`);
      fs.mkdirSync(outputDirectory, { recursive: true });
    }

    let collectionsToProcess = collectionsToBackup;
    if (!collectionsToProcess || collectionsToProcess.length === 0) {
      console.log('Fetching all top-level collection names...');
      const collections = await db.listCollections();
      collectionsToProcess = collections.map(col => col.id);
    }

    for (const collectionName of collectionsToProcess) {
      console.log(`Retrieving documents from collection: ${collectionName}`);
      const collectionRef = db.collection(collectionName);
      const snapshot = await collectionRef.get();

      if (snapshot.empty) {
        console.log(`  Collection '${collectionName}' is empty.`);
        continue;
      }

      allData[collectionName] = {};
      snapshot.forEach(doc => {
        allData[collectionName][doc.id] = doc.data();
      });
      console.log(`  Backed up ${snapshot.size} documents from '${collectionName}'.`);
    }

    // Save data to a JSON file
    fs.writeFileSync(outputFileName, JSON.stringify(allData, null, 2), 'utf8');
    console.log(`Backup completed! Data saved to ${outputFileName}`);

  } catch (error) {
    console.error('Error during backup:', error);
  }
}

// Run the backup
backupFirestore();
