import * as Sentry from '@sentry/node';
import { SENTRY_DSN, TREMBLE_ENV } from '../config/env';

export function initSentry(): void {
    if (!SENTRY_DSN) return;
    Sentry.init({
        dsn: SENTRY_DSN,
        environment: TREMBLE_ENV,
        tracesSampleRate: TREMBLE_ENV === 'prod' ? 0.1 : 0,
    });
}

export { Sentry };