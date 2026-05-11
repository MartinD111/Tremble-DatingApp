/**
 * Tremble — Auth Guard Middleware
 *
 * Verifies Firebase Auth tokens on all callable functions.
 * Extracts and validates the caller's UID before allowing access.
 */

import { HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { DocumentData } from "firebase-admin/firestore";
import { ENFORCE_APP_CHECK } from "../config/env";

/**
 * Ensures the request has a valid authenticated user.
 * Throws UNAUTHENTICATED if no valid auth context.
 *
 * @returns The authenticated user's UID
 */
export function requireAuth(request: CallableRequest): string {
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "Authentication required. Please sign in."
        );
    }
    return request.auth.uid;
}

/**
 * Ensures the authenticated user's email is verified.
 * Throws PERMISSION_DENIED if email not verified.
 *
 * @returns The authenticated user's UID
 */
export function requireVerifiedEmail(request: CallableRequest): string {
    const uid = requireAuth(request);

    if (!request.auth?.token.email_verified) {
        throw new HttpsError(
            "permission-denied",
            "Email verification required."
        );
    }

    return uid;
}

/**
 * Ensures the request has a valid App Check token.
 * Defense-in-depth check alongside enforceAppCheck: true at the function level.
 * Throws FAILED_PRECONDITION if App Check token is absent.
 */
export function requireAppCheck(request: CallableRequest): void {
    if (!ENFORCE_APP_CHECK) return;
    if (!request.app) {
        throw new HttpsError(
            "failed-precondition",
            "The function must be called from an App Check verified client."
        );
    }
}

/**
 * Throws PERMISSION_DENIED if the user is banned.
 *
 * Accepts already-fetched Firestore user data to avoid an extra read
 * in functions that have already loaded the user document.
 *
 * Ban is active when:
 *   - isBanned === true AND
 *   - bannedUntil is null (permanent) OR bannedUntil > now (temporary)
 */
export function assertNotBanned(userData: DocumentData | undefined): void {
    if (userData?.isBanned !== true) return;
    const bannedUntil = userData?.bannedUntil;
    if (!bannedUntil || bannedUntil.toDate() > new Date()) {
        throw new HttpsError(
            "permission-denied",
            "Your account has been suspended."
        );
    }
}

/**
 * Ensures the caller has admin role.
 * Admin role is determined by custom claims set server-side.
 *
 * @returns The authenticated user's UID
 */
export function requireAdmin(request: CallableRequest): string {
    const uid = requireAuth(request);

    if (!request.auth?.token.admin) {
        throw new HttpsError(
            "permission-denied",
            "Admin access required."
        );
    }

    return uid;
}
