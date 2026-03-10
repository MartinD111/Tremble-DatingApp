/**
 * Tremble — Cloud Functions Entry Point
 *
 * Exports all callable functions for Firebase deployment.
 * Each module is organized by domain (auth, users, matches, etc.).
 */

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
} from "./modules/users/users.functions";

// ── Matches Module ───────────────────────────────────────
export {
    sendGreeting,
    respondToGreeting,
    getMatches,
    getPendingGreetings,
} from "./modules/matches/matches.functions";

// ── Uploads Module (Cloudflare R2) ───────────────────────
export { generateUploadUrl } from "./modules/uploads/uploads.functions";

// ── Proximity Module ─────────────────────────────────────
export {
    updateLocation,
    findNearby,
    setInactive,
    onBleProximity,
} from "./modules/proximity/proximity.functions";

// ── GDPR Module ──────────────────────────────────────────
export {
    exportUserData,
    deleteUserAccount,
} from "./modules/gdpr/gdpr.functions";

// ── Email Module (Resend) ─────────────────────────────────
export { resendVerificationEmail } from "./modules/email/email.functions";
