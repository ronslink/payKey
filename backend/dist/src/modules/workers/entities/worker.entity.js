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
exports.Worker = exports.PaymentMethod = exports.PaymentFrequency = exports.EmploymentType = void 0;
const typeorm_1 = require("typeorm");
const user_entity_1 = require("../../users/entities/user.entity");
const property_entity_1 = require("../../properties/entities/property.entity");
const decimalTransformer = {
    to: (value) => value,
    from: (value) => {
        return value === null || value === undefined ? null : parseFloat(value);
    },
};
var EmploymentType;
(function (EmploymentType) {
    EmploymentType["FIXED"] = "FIXED";
    EmploymentType["HOURLY"] = "HOURLY";
})(EmploymentType || (exports.EmploymentType = EmploymentType = {}));
var PaymentFrequency;
(function (PaymentFrequency) {
    PaymentFrequency["MONTHLY"] = "MONTHLY";
    PaymentFrequency["WEEKLY"] = "WEEKLY";
})(PaymentFrequency || (exports.PaymentFrequency = PaymentFrequency = {}));
var PaymentMethod;
(function (PaymentMethod) {
    PaymentMethod["MPESA"] = "MPESA";
    PaymentMethod["BANK"] = "BANK";
    PaymentMethod["CASH"] = "CASH";
})(PaymentMethod || (exports.PaymentMethod = PaymentMethod = {}));
let Worker = class Worker {
    id;
    employmentType;
    hourlyRate;
    user;
    userId;
    name;
    phoneNumber;
    idNumber;
    kraPin;
    salaryGross;
    startDate;
    isActive;
    leaveBalance;
    email;
    nssfNumber;
    nhifNumber;
    jobTitle;
    housingAllowance;
    transportAllowance;
    paymentFrequency;
    paymentMethod;
    mpesaNumber;
    bankName;
    bankAccount;
    notes;
    terminationId;
    terminatedAt;
    property;
    propertyId;
    createdAt;
    updatedAt;
};
exports.Worker = Worker;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Worker.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: EmploymentType,
        default: EmploymentType.FIXED,
    }),
    __metadata("design:type", String)
], Worker.prototype, "employmentType", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 10, scale: 2, nullable: true, transformer: decimalTransformer }),
    __metadata("design:type", Number)
], Worker.prototype, "hourlyRate", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => user_entity_1.User, (user) => user.id),
    __metadata("design:type", user_entity_1.User)
], Worker.prototype, "user", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], Worker.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], Worker.prototype, "name", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], Worker.prototype, "phoneNumber", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "idNumber", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "kraPin", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 12, scale: 2, transformer: decimalTransformer }),
    __metadata("design:type", Number)
], Worker.prototype, "salaryGross", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'date' }),
    __metadata("design:type", Date)
], Worker.prototype, "startDate", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: true }),
    __metadata("design:type", Boolean)
], Worker.prototype, "isActive", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'int', default: 0 }),
    __metadata("design:type", Number)
], Worker.prototype, "leaveBalance", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "email", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "nssfNumber", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "nhifNumber", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "jobTitle", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 12, scale: 2, default: 0, transformer: decimalTransformer }),
    __metadata("design:type", Number)
], Worker.prototype, "housingAllowance", void 0);
__decorate([
    (0, typeorm_1.Column)('decimal', { precision: 12, scale: 2, default: 0, transformer: decimalTransformer }),
    __metadata("design:type", Number)
], Worker.prototype, "transportAllowance", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: PaymentFrequency,
        default: PaymentFrequency.MONTHLY,
    }),
    __metadata("design:type", String)
], Worker.prototype, "paymentFrequency", void 0);
__decorate([
    (0, typeorm_1.Column)({
        type: 'enum',
        enum: PaymentMethod,
        default: PaymentMethod.MPESA,
    }),
    __metadata("design:type", String)
], Worker.prototype, "paymentMethod", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "mpesaNumber", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "bankName", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "bankAccount", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "notes", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "terminationId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'timestamp', nullable: true }),
    __metadata("design:type", Date)
], Worker.prototype, "terminatedAt", void 0);
__decorate([
    (0, typeorm_1.ManyToOne)(() => property_entity_1.Property, { nullable: true }),
    (0, typeorm_1.JoinColumn)({ name: 'propertyId' }),
    __metadata("design:type", property_entity_1.Property)
], Worker.prototype, "property", void 0);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], Worker.prototype, "propertyId", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], Worker.prototype, "createdAt", void 0);
__decorate([
    (0, typeorm_1.UpdateDateColumn)(),
    __metadata("design:type", Date)
], Worker.prototype, "updatedAt", void 0);
exports.Worker = Worker = __decorate([
    (0, typeorm_1.Entity)('workers')
], Worker);
//# sourceMappingURL=worker.entity.js.map