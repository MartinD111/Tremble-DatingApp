import {existsSync, readFileSync} from "node:fs";
import {resolve} from "node:path";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {deleteDoc, doc, getDoc, setDoc, updateDoc} from "firebase/firestore";

const projectId = "demo-tremble-rules-test";
const rulesPath = resolve(process.cwd(), "../firestore.rules");
const rulesSource = readFileSync(rulesPath, "utf8");
const packageJson = JSON.parse(
  readFileSync(resolve(process.cwd(), "package.json"), "utf8"),
) as {
  scripts: Record<string, string>;
  devDependencies: Record<string, string>;
};
const rulesTestConfigPath = resolve(
  process.cwd(),
  "../firebase.rules-test.json",
);

describe("Firestore finder rules source contract", () => {
  it("explicitly denies all client access to finder documents", () => {
    expect(rulesSource).toMatch(
      /match\s+\/matches\/\{matchId\}\/finder\/\{uid\}\s*\{\s*allow\s+read,\s*write:\s*if\s+false;\s*\}/s,
    );
  });

  it("uses the fail-closed Firebase demo project namespace", () => {
    expect(projectId).toBe("demo-tremble-rules-test");
    expect(packageJson.scripts["test:rules"]).toContain(
      "--project demo-tremble-rules-test",
    );
  });

  it("pins the rules CLI and uses the dedicated emulator config", () => {
    expect(packageJson.devDependencies["firebase-tools"]).toBe("15.24.0");
    expect(packageJson.scripts["test:rules"]).toContain(
      "--config ../firebase.rules-test.json",
    );
  });

  it("keeps the rules emulator config minimal and project-agnostic", () => {
    expect(existsSync(rulesTestConfigPath)).toBe(true);
    if (!existsSync(rulesTestConfigPath)) return;

    const config = JSON.parse(readFileSync(rulesTestConfigPath, "utf8"));
    expect(config).toEqual({
      firestore: {rules: "firestore.rules"},
      emulators: {
        firestore: {port: 8080},
        singleProjectMode: true,
      },
    });
    expect(JSON.stringify(config)).not.toMatch(
      /tremble-dev|am---dating-app/,
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

  it("denies participant creates of finder documents", async () => {
    const database = testEnv.authenticatedContext("participant-a").firestore();
    await assertFails(
      setDoc(
        doc(
          database,
          "matches",
          "synthetic-match",
          "finder",
          "participant-b",
        ),
        {lat: 0.03, lng: 0.04, accuracy: 4},
      ),
    );
  });

  it("denies participant deletes of finder documents", async () => {
    const database = testEnv.authenticatedContext("participant-a").firestore();
    await assertFails(
      deleteDoc(
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

  it("denies combined seenBy and finderOptIn updates", async () => {
    const database = testEnv.authenticatedContext("participant-a").firestore();
    await assertFails(
      updateDoc(doc(database, "matches", "synthetic-match"), {
        seenBy: ["participant-a"],
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
