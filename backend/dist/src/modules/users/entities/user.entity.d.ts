export declare enum UserTier {
    FREE = "FREE",
    BASIC = "BASIC",
    GOLD = "GOLD",
    PLATINUM = "PLATINUM"
}
export declare enum UserRole {
    ADMIN = "ADMIN",
    USER = "USER"
}
export declare enum IdType {
    NATIONAL_ID = "NATIONAL_ID",
    ALIEN_ID = "ALIEN_ID",
    PASSPORT = "PASSPORT"
}
export declare class User {
    id: string;
    email: string;
    passwordHash: string;
    role: UserRole;
    firstName: string;
    lastName: string;
    tier: UserTier;
    stripeCustomerId: string;
    kraPin: string;
    nssfNumber: string;
    nhifNumber: string;
    idType: IdType;
    idNumber: string;
    nationalityId: string;
    address: string;
    city: string;
    countryId: string;
    isResident: boolean;
    countryOfOrigin: string;
    isOnboardingCompleted: boolean;
    createdAt: Date;
    updatedAt: Date;
}
