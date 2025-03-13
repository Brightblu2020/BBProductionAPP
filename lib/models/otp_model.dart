class OtpModel {
  OtpModel({
    this.contact,
    this.location,
    this.servicePartner,
    this.partnerName,
    required this.endTimestamp,
    this.siteAddress,
    required this.otp,
    required this.startTimestamp,
    this.lastUsed,
  });

  factory OtpModel.fromJson({required Map<String, dynamic> data}) {
    return OtpModel(
      startTimestamp: data['startTimestamp'],
      endTimestamp: data['endTimestamp'],
      otp: data['otp'],
      servicePartner: data['servicePartner'],
      partnerName: data['partnerName'],
      location: data['location'],
      siteAddress: data['siteAddress'],
      contact: data['contact'],
    );
  }

  OtpModel copyWith({int? endTimestamp}) {
    return OtpModel(
      endTimestamp: endTimestamp ?? this.endTimestamp,
      otp: otp,
      startTimestamp: startTimestamp,
      servicePartner: servicePartner,
      partnerName: partnerName,
      location: location,
      siteAddress: siteAddress,
      contact: contact,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "endTimestamp": endTimestamp,
      "otp": otp,
      "startTimestamp": startTimestamp,
      "servicePartner": servicePartner,
      "partnerName": partnerName,
      "location": location,
      "siteAddress": siteAddress,
      "contact": contact,
    };
  }

  final String? servicePartner;
  final String? location;
  final String? contact;
  final String otp;
  final int startTimestamp;
  final int endTimestamp;
  final String? partnerName;
  final String? siteAddress;
  final String? lastUsed;
}
