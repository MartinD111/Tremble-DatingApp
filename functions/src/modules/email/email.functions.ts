/**
 * Tremble — Email Functions (Resend)
 *
 * Transactional emails: new match notifications, welcome email,
 * account deletion confirmation.
 *
 * All emails are triggered server-side — never from the Flutter client.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { Resend } from "resend";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { getConfig } from "../../config/env";

const db = getFirestore();



function getResend(): Resend {
  const config = getConfig();
  if (!config.resend.apiKey) {
    throw new HttpsError("internal", "Email service not configured.");
  }
  return new Resend(config.resend.apiKey);
}

// ── Internal send helpers ─────────────────────────────────

/**
 * Send a welcome email after onboarding completes.
 * Called internally by completeOnboarding.
 */
export async function sendWelcomeEmail(
  toEmail: string,
  name: string
): Promise<void> {
  const { fromEmail } = getConfig().resend;
  const resend = getResend();

  await resend.emails.send({
    from: `Tremble <${fromEmail}>`,
    to: [toEmail],
    subject: "Dobrodošel v Tremble! 👋",
    html: `
        <div style="font-family: sans-serif; max-width: 480px; margin: auto; padding: 32px;">
          <h1 style="color: #e91e8c; font-size: 28px;">Dobrodošel, ${name}! 🎉</h1>
          <p style="font-size: 16px; line-height: 1.6; color: #333;">
            Tvoj profil je aktiven. Ko boš v bližini sorodne duše,
            te Tremble diskretno obvestí.
          </p>
          <p style="font-size: 14px; color: #666; margin-top: 32px;">
            Ekipa Tremble 🖤
          </p>
        </div>`,
  });

  console.log(`[EMAIL] Welcome email sent to ${toEmail}`);
}

/**
 * Send a match notification email.
 * Called internally when two users match.
 */
export async function sendMatchNotificationEmail(
  toEmail: string,
  matchName: string
): Promise<void> {
  const { fromEmail } = getConfig().resend;
  const resend = getResend();

  await resend.emails.send({
    from: `Tremble <${fromEmail}>`,
    to: [toEmail],
    subject: `💌 Match z ${matchName}!`,
    html: `
        <div style="font-family: sans-serif; max-width: 480px; margin: auto; padding: 32px;">
          <h1 style="color: #e91e8c; font-size: 24px;">Imata Match! 🎉</h1>
          <p style="font-size: 16px; line-height: 1.6; color: #333;">
            Ti in <strong>${matchName}</strong> sta si vzajemno poslala pozdrav.
            Odpri Tremble in začni pogovor!
          </p>
          <a href="https://trembledating.com"
             style="display:inline-block; margin-top:20px; padding:14px 28px;
                    background:#e91e8c; color:#fff; border-radius:8px;
                    text-decoration:none; font-weight:bold; font-size:16px;">
            Odpri Tremble
          </a>
          <p style="font-size: 14px; color: #666; margin-top: 32px;">
            Ekipa Tremble 🖤
          </p>
        </div>`,
  });

  console.log(`[EMAIL] Match notification sent to ${toEmail} — matched with ${matchName}`);
}

/**
 * Send account deletion confirmation email.
 * Called internally before deleting the account.
 */
export async function sendDeletionConfirmationEmail(
  toEmail: string,
  name: string
): Promise<void> {
  const { fromEmail } = getConfig().resend;
  const resend = getResend();

  await resend.emails.send({
    from: `Tremble <${fromEmail}>`,
    to: [toEmail],
    subject: "Tvoj račun je bil izbrisan — Tremble",
    html: `
        <div style="font-family: sans-serif; max-width: 480px; margin: auto; padding: 32px;">
          <h1 style="color: #333; font-size: 22px;">Račun izbrisan</h1>
          <p style="font-size: 16px; line-height: 1.6; color: #555;">
            Pozdravljeni ${name},<br><br>
            Vaš račun in vsi osebni podatki so bili trajno izbrisani v skladu z GDPR.
            Žal nam bo, da vas ni več med nami. 💔
          </p>
          <p style="font-size: 14px; color: #666; margin-top: 32px;">
            Ekipa Tremble
          </p>
        </div>`,
  });

  console.log(`[EMAIL] Deletion confirmation sent to ${toEmail}`);
}

// ── Public callable: resend verification email ────────────

export const resendVerificationEmail = onCall(
  { maxInstances: 10 },
  async (request) => {
    const uid = requireAuth(request);

    await checkRateLimit(uid, "resendVerificationEmail", {
      maxRequests: 3,
      windowMs: 300_000, // 3 per 5 minutes
    });

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User not found.");
    }

    const data = userDoc.data()!;
    if (data.isEmailVerified) {
      throw new HttpsError(
        "failed-precondition",
        "Email is already verified."
      );
    }

    // Verification is handled by Firebase Auth; this just reminds them
    return { message: "Please check your inbox for the verification email." };
  }
);
