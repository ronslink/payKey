
class ProfileModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? businessName;
  final String? kraPin;
  final String? nssfNumber;
  final String? shifNumber;
  final String? bankName;
  final String? bankAccount;
  final String? mpesaPaybill;
  final String? mpesaTill;
  // Required compliance fields
  final String? idType;
  final String? idNumber;
  final String? address;
  final String? city;
  final String? countryId;
  final String? nationalityId;
  final String? residentStatus;
  final String? phoneNumber;

  ProfileModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.businessName,
    this.kraPin,
    this.nssfNumber,
    this.shifNumber,
    this.bankName,
    this.bankAccount,
    this.mpesaPaybill,
    this.mpesaTill,
    this.idType,
    this.idNumber,
    this.address,
    this.city,
    this.countryId,
    this.nationalityId,
    this.residentStatus,
    this.phoneNumber,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      businessName: json['businessName'],
      kraPin: json['kraPin'],
      nssfNumber: json['nssfNumber'],
      // Support both new and old keys if transition period, but backend should send shifNumber now
      shifNumber: json['shifNumber'] ?? json['nhifNumber'],
      bankName: json['bankName'],
      bankAccount: json['bankAccount'],
      mpesaPaybill: json['mpesaPaybill'],
      mpesaTill: json['mpesaTill'],
      idType: json['idType'] ?? json['idtype'], // Handle case sensitive
      idNumber: json['idNumber'],
      address: json['address'],
      city: json['city'],
      countryId: json['countryId'],
      nationalityId: json['nationalityId'],
      residentStatus: json['residentStatus'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'businessName': businessName,
      'kraPin': kraPin,
      'nssfNumber': nssfNumber,
      'shifNumber': shifNumber,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'mpesaPaybill': mpesaPaybill,
      'mpesaTill': mpesaTill,
    };
  }
}
