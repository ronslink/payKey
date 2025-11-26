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
exports.UpdateComplianceProfileDto = void 0;
const class_validator_1 = require("class-validator");
const user_entity_1 = require("../entities/user.entity");
class UpdateComplianceProfileDto {
    kraPin;
    nssfNumber;
    nhifNumber;
    idType;
    idNumber;
    nationalityId;
    address;
    city;
    countryId;
}
exports.UpdateComplianceProfileDto = UpdateComplianceProfileDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^[A-Z]\d{9}[A-Z]$/, {
        message: 'KRA PIN must be in the format A123456789Z',
    }),
    __metadata("design:type", String)
], UpdateComplianceProfileDto.prototype, "kraPin", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdateComplianceProfileDto.prototype, "nssfNumber", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdateComplianceProfileDto.prototype, "nhifNumber", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(user_entity_1.IdType),
    __metadata("design:type", String)
], UpdateComplianceProfileDto.prototype, "idType", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.ValidateIf)((o) => o.idType === user_entity_1.IdType.NATIONAL_ID),
    (0, class_validator_1.Matches)(/^\d{7,8}$/, {
        message: 'National ID must be 7 or 8 digits',
    }),
    (0, class_validator_1.ValidateIf)((o) => o.idType === user_entity_1.IdType.ALIEN_ID || o.idType === user_entity_1.IdType.PASSPORT),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdateComplianceProfileDto.prototype, "idNumber", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.ValidateIf)((o) => o.idType === user_entity_1.IdType.ALIEN_ID || o.idType === user_entity_1.IdType.PASSPORT),
    (0, class_validator_1.IsNotEmpty)({
        message: 'Nationality is required for Expats (Passport/Alien ID)',
    }),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], UpdateComplianceProfileDto.prototype, "nationalityId", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdateComplianceProfileDto.prototype, "address", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdateComplianceProfileDto.prototype, "city", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdateComplianceProfileDto.prototype, "countryId", void 0);
//# sourceMappingURL=update-compliance-profile.dto.js.map