/**
 * Tremble — Cloud Functions Entry Point
 *
 * Exports all callable functions for Firebase deployment.
 * Each module is organized by domain (auth, users, matches, etc.).
 */
import { initSentry } from './core/sentry';
initSentry();

import { initializeApp } from "firebase-admin/app";

// Initialize Firebase Admin SDK
initializeApp();

// ── Auth Module ──────────────────────────────────────────
export {
    onUserDocCreated,
    completeOnboarding,
    verifyGoogleToken,
} from "./modules/auth/auth.functions";

// ── Users Module ─────────────────────────────────────────
export {
    updateProfile,
    getProfile,
    getPublicProfile,
    withdrawArt9Consent,
} from "./modules/users/users.functions";

// ── Matches Module ───────────────────────────────────────
export {
    onWaveCreated,
    getMatches,
    sendWave,
    markMatchFound,
    sendMatchGesture,
} from "./modules/matches/matches.functions";

export {
    requestPulseIntercept,
    getPulseIntercept,
} from "./modules/matches/intercept.functions";

export { updateFinderLocation } from "./modules/matches/finder.functions";

// ── Uploads Module (Cloudflare R2) ───────────────────────
export { generateUploadUrl } from "./modules/uploads/uploads.functions";

// ── Proximity Module ─────────────────────────────────────
export {
    findNearby,
    setInactive,
    scanProximityPairs,            // replaces onBleProximity + onRunEncounter
    getProximityMatchCandidates,
    onRunCrossUpdated,
} from "./modules/proximity/proximity.functions";

// ── GDPR Module ──────────────────────────────────────────
export {
    exportUserData,
    deleteUserAccount,
} from "./modules/gdpr/gdpr.functions";

// ── Email Module (Resend) ─────────────────────────────────
export { resendVerificationEmail } from "./modules/email/email.functions";

// ── Safety / UGC Module ──────────────────────────────────
export {
    blockUser,
    unblockUser,
    getBlockedUsers,
    reportUser,
    onContactAnonymityCheck,
    onReportCreated,
} from "./modules/safety/safety.functions";

// ── Events Module ────────────────────────────────────────
export {
    onEventModeActivate,
    onEventModeDeactivate,
    expireEventModes,
} from "./modules/events/events.functions";

// ── Gym Module ───────────────────────────────────────────
export {
    onGymModeActivate,
    onGymModeDeactivate,
    expireGymSessions,
    onRunModeActivate,
    onRunModeDeactivate,
    expireRunModes,
} from "./modules/gym/gym.functions";

// ── Subscriptions Module ───────────────────────────────────
export {
    activateWeekendPass,
    processWeekendPasses,
} from "./modules/subscriptions/subscriptions.functions";

// ── Ops: Billing kill-switch ─────────────────────────────
export { stopBilling } from "./scripts/stop-billing";
