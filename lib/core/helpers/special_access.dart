/// Legacy UIDs that had hardcoded extended management access before Firestore flag.
const Set<String> legacySpecialManagementUids = {
  '7DUwUuQ0rIUUb94NCK2vdnrZCLo1',
};

bool hasLegacySpecialManagementAccess(String uid) =>
    legacySpecialManagementUids.contains(uid);
