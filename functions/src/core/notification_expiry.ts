/**
 * Tremble — expiry window for time-sensitive push notifications.
 *
 * A proximity alert ("User Beta is nearby") or a wave is only worth delivering
 * while it is still true. Without an expiry, a handset that is offline or in
 * Doze receives the backlog on reconnect, so the user is told someone is 100 m
 * away an hour after they left.
 *
 * SCOPE — this bounds the DELIVERY window only. It does NOT remove a
 * notification that already reached the device: once delivered, it stays until
 * the user dismisses it. Neither FCM nor APNs exposes a server-side display
 * timeout (FCM v1's AndroidNotification has no `timeoutAfter` field), so do not
 * reach for these helpers expecting a lock-screen auto-dismiss.
 *
 * The two platforms disagree on units, which is the easy thing to get wrong:
 *   - Android wants a RELATIVE duration in MILLISECONDS.
 *   - APNs wants an ABSOLUTE UNIX epoch in SECONDS, as a string header.
 */

/** How long a time-sensitive notification stays worth delivering. */
export const NOTIFICATION_TTL_SECONDS = 300;

/** Android `AndroidConfig.ttl` — relative, milliseconds. */
export const NOTIFICATION_TTL_MILLIS = NOTIFICATION_TTL_SECONDS * 1000;

/**
 * APNs `apns-expiration` — absolute epoch seconds, computed at send time.
 *
 * Returning a fresh object per call keeps the deadline honest: a message built
 * now expires 300 s from now, not 300 s from module load. Retries that reuse an
 * already-built message keep their original deadline, which is what we want —
 * the alert does not get a fresh lease just because delivery was retried.
 */
export function apnsExpirationHeaders(): { "apns-expiration": string } {
    return {
        "apns-expiration": String(
            Math.floor(Date.now() / 1000) + NOTIFICATION_TTL_SECONDS,
        ),
    };
}
