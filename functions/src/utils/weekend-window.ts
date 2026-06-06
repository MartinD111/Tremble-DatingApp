import { DateTime } from "luxon";

export interface WeekendWindow {
    activatesAt: Date;
    expiresAt: Date;
}

function zonedNow(timezone: string): DateTime {
    const now = DateTime.now().setZone(timezone);
    return now.isValid ? now : DateTime.now().setZone("Europe/Ljubljana");
}

function currentWeekendBounds(now: DateTime): { startsAt: DateTime; endsAt: DateTime } {
    const startsAt = now
        .startOf("day")
        .plus({ days: 5 - now.weekday })
        .set({ hour: 19 });

    return {
        startsAt,
        endsAt: startsAt.plus({ days: 2 }),
    };
}

export function isInWeekendWindow(timezone: string): boolean {
    const now = zonedNow(timezone);
    const { startsAt, endsAt } = currentWeekendBounds(now);
    return now.toMillis() >= startsAt.toMillis() && now.toMillis() < endsAt.toMillis();
}

export function getNextWeekendWindow(timezone: string): WeekendWindow {
    const now = zonedNow(timezone);
    const { startsAt, endsAt } = currentWeekendBounds(now);

    if (now.toMillis() >= startsAt.toMillis() && now.toMillis() < endsAt.toMillis()) {
        return {
            activatesAt: now.toJSDate(),
            expiresAt: endsAt.toJSDate(),
        };
    }

    const activatesAt = now.toMillis() < startsAt.toMillis()
        ? startsAt
        : startsAt.plus({ weeks: 1 });

    return {
        activatesAt: activatesAt.toJSDate(),
        expiresAt: activatesAt.plus({ days: 2 }).toJSDate(),
    };
}
