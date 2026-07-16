const {afterEach, test} = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  deleteField,
  doc,
  setDoc,
  updateDoc,
} = require('firebase/firestore');

const ROOT = path.resolve(__dirname, '..');
const RULESETS = {
  baseline: {
    projectId: 'demo-tremble-rules-baseline',
    path: path.join(__dirname, 'fixtures', 'production-baseline.rules'),
    sha256: 'eb1f74586535a228fd0596720242a79c3b56d1450c2f99ee30381b79e62df4a7',
  },
  candidate: {
    projectId: 'demo-tremble-rules-candidate',
    path: path.join(__dirname, 'fixtures', 'fcm-token-only-candidate.rules'),
    sha256: '7fe2102123500f2522d2eceeeb3af3557528b4ec3520f351a3faac89d29f69d0',
  },
  local: {
    projectId: 'demo-tremble-rules-local',
    path: path.join(ROOT, 'firestore.rules'),
  },
};

const TOKEN_RULESETS = ['candidate', 'local'];
const PROTECTED_FIELDS = {
  isPremium: true,
  isAdmin: true,
  activeGymId: 'gym-1',
  gymModeUntil: '2099-01-01',
  activeEventId: 'event-1',
  ageConfirmed: true,
  ageConfirmedAt: '2099-01-01',
  blockedBy: ['uid-2'],
  blockedUserIds: ['uid-2'],
  flaggedForReview: false,
};

let activeEnvironment;

afterEach(async () => {
  await activeEnvironment?.cleanup();
  activeEnvironment = undefined;
});

function sha256(filePath) {
  return crypto
    .createHash('sha256')
    .update(fs.readFileSync(filePath))
    .digest('hex');
}

async function environmentFor(rulesetName) {
  assert.ok(
    process.env.FIRESTORE_EMULATOR_HOST,
    'Tests must run against the Firestore emulator.',
  );

  const ruleset = RULESETS[rulesetName];
  assert.match(ruleset.projectId, /^demo-/);
  activeEnvironment = await initializeTestEnvironment({
    projectId: ruleset.projectId,
    firestore: {rules: fs.readFileSync(ruleset.path, 'utf8')},
  });
  return activeEnvironment;
}

function listProfile(displayName = 'Owner') {
  return {
    displayName,
    lookingFor: ['woman'],
  };
}

function stringProfile(displayName = 'Owner', lookingFor = 'woman') {
  return {displayName, lookingFor};
}

async function seedProfile(testEnv, userId, profile) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users', userId), profile);
  });
}

function userDoc(testEnv, authUserId, documentUserId = authUserId) {
  const db = authUserId === null
    ? testEnv.unauthenticatedContext().firestore()
    : testEnv.authenticatedContext(authUserId).firestore();
  return doc(db, 'users', documentUserId);
}

test('pins the immutable production baseline and candidate fixture hashes', () => {
  assert.equal(sha256(RULESETS.baseline.path), RULESETS.baseline.sha256);
  assert.equal(sha256(RULESETS.candidate.path), RULESETS.candidate.sha256);
});

test('production baseline denies a token update on a list-shaped profile', async () => {
  const testEnv = await environmentFor('baseline');
  await seedProfile(testEnv, 'baseline-list-owner', listProfile());

  await assertFails(updateDoc(
    userDoc(testEnv, 'baseline-list-owner'),
    {fcmToken: 'token'},
  ));
});

test('production baseline A/B permits owner tokens on string-shaped profiles', async () => {
  const testEnv = await environmentFor('baseline');
  await seedProfile(
    testEnv,
    'baseline-string-a',
    stringProfile('Owner A', 'woman'),
  );
  await seedProfile(
    testEnv,
    'baseline-string-b',
    stringProfile('Owner B', 'man'),
  );

  await assertSucceeds(updateDoc(
    userDoc(testEnv, 'baseline-string-a'),
    {fcmToken: 'token-a'},
  ));
  await assertSucceeds(updateDoc(
    userDoc(testEnv, 'baseline-string-b'),
    {fcmToken: 'token-b'},
  ));
});

for (const rulesetName of TOKEN_RULESETS) {
  test(`${rulesetName}: owner token-only update succeeds on a list-shaped profile`, async () => {
    const testEnv = await environmentFor(rulesetName);
    const ownerId = `${rulesetName}-list-owner`;
    await seedProfile(testEnv, ownerId, listProfile());

    await assertSucceeds(updateDoc(
      userDoc(testEnv, ownerId),
      {fcmToken: 'token'},
    ));
  });

  test(`${rulesetName}: other authenticated and unauthenticated users cannot update the token`, async () => {
    const testEnv = await environmentFor(rulesetName);
    const ownerId = `${rulesetName}-auth-owner`;
    await seedProfile(testEnv, ownerId, listProfile());

    await assertFails(updateDoc(
      userDoc(testEnv, `${rulesetName}-attacker`, ownerId),
      {fcmToken: 'attacker-token'},
    ));
    await assertFails(updateDoc(
      userDoc(testEnv, null, ownerId),
      {fcmToken: 'anonymous-token'},
    ));
  });

  test(`${rulesetName}: token type, deletion, and upper boundary are enforced`, async () => {
    const testEnv = await environmentFor(rulesetName);
    const invalidTokens = [
      ['numeric', 42],
      ['object', {token: 'nested'}],
      ['null', null],
      ['deleted', deleteField()],
      ['4097 characters', 'x'.repeat(4097)],
    ];

    for (const [caseName, invalidToken] of invalidTokens) {
      const ownerId = `${rulesetName}-${caseName.replaceAll(' ', '-')}`;
      await seedProfile(testEnv, ownerId, {
        ...listProfile(),
        fcmToken: 'existing-token',
      });
      await assertFails(updateDoc(
        userDoc(testEnv, ownerId),
        {fcmToken: invalidToken},
      ));
    }

    const boundaryOwnerId = `${rulesetName}-4096-boundary`;
    await seedProfile(testEnv, boundaryOwnerId, listProfile());
    await assertSucceeds(updateDoc(
      userDoc(testEnv, boundaryOwnerId),
      {fcmToken: 'x'.repeat(4096)},
    ));
  });

  test(`${rulesetName}: every protected user field remains immutable`, async () => {
    const testEnv = await environmentFor(rulesetName);

    for (const [field, value] of Object.entries(PROTECTED_FIELDS)) {
      const ownerId = `${rulesetName}-protected-${field}`;
      await seedProfile(testEnv, ownerId, stringProfile());
      await assertFails(updateDoc(
        userDoc(testEnv, ownerId),
        {[field]: value},
      ));
    }
  });
}

test('candidate denies a token combined with an arbitrary field', async () => {
  const testEnv = await environmentFor('candidate');
  await seedProfile(testEnv, 'candidate-arbitrary', listProfile());

  await assertFails(updateDoc(
    userDoc(testEnv, 'candidate-arbitrary'),
    {fcmToken: 'token', arbitraryField: 'not-allowed'},
  ));
});

test('candidate denies a token combined with sexualOrientationConsent', async () => {
  const testEnv = await environmentFor('candidate');
  await seedProfile(testEnv, 'candidate-consent', listProfile());

  await assertFails(updateDoc(
    userDoc(testEnv, 'candidate-consent'),
    {fcmToken: 'token', sexualOrientationConsent: true},
  ));
});

test('candidate denies a token combined with another ordinary field', async () => {
  const testEnv = await environmentFor('candidate');
  await seedProfile(testEnv, 'candidate-ordinary', listProfile());

  await assertFails(updateDoc(
    userDoc(testEnv, 'candidate-ordinary'),
    {fcmToken: 'token', displayName: 'Changed'},
  ));
});

test('candidate preserves baseline full-document validation for non-token updates', async () => {
  const testEnv = await environmentFor('candidate');
  await seedProfile(
    testEnv,
    'candidate-valid-non-token',
    stringProfile('Valid'),
  );
  await seedProfile(
    testEnv,
    'candidate-legacy-non-token',
    listProfile('Legacy'),
  );

  await assertSucceeds(updateDoc(
    userDoc(testEnv, 'candidate-valid-non-token'),
    {displayName: 'Changed'},
  ));
  await assertFails(updateDoc(
    userDoc(testEnv, 'candidate-legacy-non-token'),
    {displayName: 'Changed'},
  ));
});
