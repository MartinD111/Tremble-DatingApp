import {readFileSync} from "node:fs";
import {resolve} from "node:path";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {doc, getDoc, setDoc, updateDoc} from "firebase/firestore";

const projectId = "tremble-rules-test";
const rulesPath = resolve(process.cwd(), "../firestore.rules");
const rulesSource = readFileSync(rulesPath, "utf8");

describe("Firestore finder rules source contract", () => {
  it("explicitly denies all client access to finder documents", () => {
    expect(rulesSource).toMatch(
      /match\s+\/matches\/\{matchId\}\/finder\/\{uid\}\s*\{\s*allow\s+read,\s*write:\s*if\s+false;\s*\}/s,
    );
  });
});

const describeWithEmulator = process.env.FIRESTORE_EMULATOR_HOST ?
  describe :
  describe.skip;

describeWithEmulator("Firestore finder rules", () => {
  let testEnv: RulesTestEnvironment;

  beforeAll(async () => {
    const [host, port] = process.env.FIRESTORE_EMULATOR_HOST!.split(":");
    testEnv = await initializeTestEnvironment({
      projectId,
      firestore: {
        host,
        port: Number(port),
        rules: rulesSource,
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const database = context.firestore();
      await setDoc(doc(database, "matches", "synthetic-match"), {
        userIds: ["participant-a", "participant-b"],
        finderOptIn: {
          "participant-a": true,
          "participant-b": false,
        },
        seenBy: [],
      });
      await setDoc(
        doc(
          database,
          "matches",
          "synthetic-match",
          "finder",
          "participant-a",
        ),
        {
          lat: 0.01,
          lng: 0.02,
          accuracy: 5,
        },
      );
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  it("denies participant reads of finder documents", async () => {
    const database = testEnv.authenticatedContext("participant-a").firestore();
    await assertFails(
      getDoc(
        doc(
          database,
          "matches",
          "synthetic-match",
          "finder",
          "participant-a",
        ),
      ),
    );
  });

  it("denies nonparticipant reads of finder documents", async () => {
    const database = testEnv.authenticatedContext("outsider").firestore();
    await assertFails(
      getDoc(
        doc(
          database,
          "matches",
          "synthetic-match",
          "finder",
          "participant-a",
        ),
      ),
    );
  });

  it.each([
    ["participant", "participant-a"],
    ["nonparticipant", "outsider"],
  ])("denies %s writes to finder documents", async (_label, uid) => {
    const database = testEnv.authenticatedContext(uid).firestore();
    await assertFails(
      setDoc(
        doc(database, "matches", "synthetic-match", "finder", uid),
        {lat: 0.03, lng: 0.04, accuracy: 4},
      ),
    );
  });

  it("denies unauthenticated writes to finder documents", async () => {
    const database = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      setDoc(
        doc(
          database,
          "matches",
          "synthetic-match",
          "finder",
          "anonymous",
        ),
        {lat: 0.03, lng: 0.04, accuracy: 4},
      ),
    );
  });

  it("allows participants to read finderOptIn on the match", async () => {
    const database = testEnv.authenticatedContext("participant-a").firestore();
    const snapshot = await assertSucceeds(
      getDoc(doc(database, "matches", "synthetic-match")),
    );
    expect(snapshot.data()?.finderOptIn).toEqual({
      "participant-a": true,
      "participant-b": false,
    });
  });

  it("denies nonparticipants from reading the match", async () => {
    const database = testEnv.authenticatedContext("outsider").firestore();
    await assertFails(getDoc(doc(database, "matches", "synthetic-match")));
  });

  it("denies participant updates to finderOptIn", async () => {
    const database = testEnv.authenticatedContext("participant-a").firestore();
    await assertFails(
      updateDoc(doc(database, "matches", "synthetic-match"), {
        "finderOptIn.participant-a": false,
      }),
    );
  });

  it("keeps the existing participant seenBy-only update allowed", async () => {
    const database = testEnv.authenticatedContext("participant-a").firestore();
    await assertSucceeds(
      updateDoc(doc(database, "matches", "synthetic-match"), {
        seenBy: ["participant-a"],
      }),
    );
  });
});
