"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.User = exports.IdType = exports.UserRole = exports.UserTier = void 0;
const typeorm_1 = require("typeorm");
var UserTier;
(function (UserTier) {
    UserTier["FREE"] = "FREE";
    UserTier["BASIC"] = "BASIC";
    UserTier["GOLD"] = "GOLD";
    UserTier["PLATINUM"] = "PLATINUM";
})(UserTier || (exports.UserTier = UserTier = {}));
var UserRole;
(function (UserRole) {
    UserRole["ADMIN"] = "ADMIN";
    UserRole["USER"] = "USER";
})(UserRole || (exports.UserRole = UserRole = {}));
var IdType;
(function (IdType) {
    IdType["NATIONAL_ID"] = "NATIONAL_ID";
    IdType["ALIEN_ID"] = "ALIEN_ID";
    IdType["PASSPORT"] = "PASSPORT";
})(IdType || (exports.IdType = IdType = {}));
let User = class User {
    id;
    email;
    passwordHash;
    role;
    firstName;
    lastName;
    tier;
    stripeCustomerId;
    kraPin;
    nssfNumber;
    nhifNumber;
    idType;
    idNumber;
    nationalityId;
    address;
    city;
    countryId;
    isResident;
    countryOfOrigin;
    isOnboardingCompleted;
    createdAt;
    updatedAt;
};
exports.User = User;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], User.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({ unique: true }),
    __metadata("design:type", String)
], User.prototype, "email", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], User.prototype, "passwordHash", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: UserRole,
        default: UserRole.USER,
    }),
    __metadata("design:type", String)
], User.prototype, "role", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "firstName", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "lastName", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: UserTier,
        default: UserTier.FREE,
    }),
    __metadata("design:type", String)
], User.prototype, "tier", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "stripeCustomerId", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "kraPin", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "nssfNumber", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "nhifNumber", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: IdType,
        nullable: true,
        name: 'idtype',
    }),
    __metadata("design:type", String)
], User.prototype, "idType", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "idNumber", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true, name: 'nationalityid' }),
    __metadata("design:type", String)
], User.prototype, "nationalityId", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "address", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "city", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], User.prototype, "countryId", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: true, name: 'isresident' }),
    __metadata("design:type", Boolean)
], User.prototype, "isResident", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true, name: 'countryoforigin' }),
    __metadata("design:type", String)
], User.prototype, "countryOfOrigin", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: false, name: 'isOnboardingCompleted' }),
    __metadata("design:type", Boolean)
], User.prototype, "isOnboardingCompleted", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], User.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], User.prototype, "updatedAt", void 0);
exports.User = User = __decorate([
    (0, typeorm_1.Entity)('users')
], User);
//# sourceMappingURL=user.entity.js.map