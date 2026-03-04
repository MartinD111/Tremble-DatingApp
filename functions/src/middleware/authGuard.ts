/**
 * Tremble — Auth Guard Middleware
 *
 * Verifies Firebase Auth tokens on all callable functions.
 * Extracts and validates the caller's UID before allowing access.
 */

import { HttpsError, CallableRequest } from "firebase-functions/v2/https";

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
