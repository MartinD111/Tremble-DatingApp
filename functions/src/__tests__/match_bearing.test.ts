import { describe, it, expect } from "@jest/globals";
import {
    computeBearing,
    distanceBucket,
    haversineMeters,
} from "../../src/modules/proximity/bearing";

describe("computeBearing (forward azimuth, 0-359 from north)", () => {
    const origin = { lat: 0, lng: 0 };

    it("due north → 0", () => {
        expect(computeBearing(origin, { lat: 1, lng: 0 })).toBeCloseTo(0, 1);
    });

    it("due east → 90", () => {
        expect(computeBearing(origin, { lat: 0, lng: 1 })).toBeCloseTo(90, 1);
    });

    it("due south → 180", () => {
        expect(computeBearing(origin, { lat: -1, lng: 0 })).toBeCloseTo(180, 1);
    });

    it("due west → 270", () => {
        expect(computeBearing(origin, { lat: 0, lng: -1 })).toBeCloseTo(270, 1);
    });

    it("normalizes into [0, 360)", () => {
        const b = computeBearing(origin, { lat: -0.0001, lng: -1 });
        expect(b).toBeGreaterThanOrEqual(0);
        expect(b).toBeLessThan(360);
    });

    it("reciprocal bearings differ by ~180°", () => {
        const a = { lat: 46.05, lng: 14.5 }; // Ljubljana-ish
        const b = { lat: 46.06, lng: 14.51 };
        const ab = computeBearing(a, b);
        const ba = computeBearing(b, a);
        const diff = (((ab - ba) % 360) + 360) % 360; // → ~180
        expect(diff).toBeCloseTo(180, 0);
    });
});

describe("distanceBucket", () => {
    it("very close → 'close'", () => {
        expect(distanceBucket(10)).toBe("close");
    });
    it("~50m band", () => {
        expect(distanceBucket(50)).toBe("~50m");
    });
    it("~150m band", () => {
        expect(distanceBucket(150)).toBe("~150m");
    });
    it("beyond the radar → 'far'", () => {
        expect(distanceBucket(300)).toBe("far");
    });
    it("monotonic across boundaries", () => {
        const order = ["close", "~50m", "~150m", "far"];
        const seq = [5, 40, 120, 400].map(distanceBucket);
        expect(seq).toEqual(order);
    });
});

describe("haversineMeters", () => {
    it("returns approximately 100m for a known pair", () => {
        const meters = haversineMeters(0, 0, 0, 0.00089932);

        expect(meters).toBeGreaterThanOrEqual(99);
        expect(meters).toBeLessThanOrEqual(101);
    });

    it("returns zero for identical points", () => {
        expect(haversineMeters(46.05, 14.5, 46.05, 14.5)).toBe(0);
    });
});
