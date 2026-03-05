/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
    preset: "ts-jest",
    testEnvironment: "node",
    roots: ["<rootDir>/src"],
    testMatch: ["**/__tests__/**/*.test.ts"],
    transform: {
        "^.+\\.ts$": [
            "ts-jest",
            {
                tsconfig: {
                    // Relax for tests — no strict checking on mocked types
                    strict: false,
                    esModuleInterop: true,
                },
            },
        ],
    },
    // Clear mocks between each test
    clearMocks: true,
    // Don't compile the full project, just what tests need
    moduleFileExtensions: ["ts", "js", "json"],
    // Exclude built output
    testPathIgnorePatterns: ["/node_modules/", "/lib/"],
};
