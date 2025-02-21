//This assets library in motoko is not actively mantained and as such it is not recommended to use this library.

import Assets "mo:assets";
import Principal "mo:base/Principal";
import Array "mo:base/Array";

actor class AssetStorage() = this {
  
  stable var authorizedUsers: [Principal] = [];

  let assetsInstance = Assets.Assets({
    serializedEntries = ([], []); 
  });

  public shared ({ caller }) func authorizeUser(user: Principal) : async Bool {
    if (caller == user) {
      authorizedUsers := Array.append(authorizedUsers, [user]);
      return true;
    };
    return false;
  };

  public shared ({ caller }) func isAuthorized() : async Bool {
    return Array.find<Principal>(authorizedUsers, func(u: Principal) { u == caller }) != null;
  };

  public shared ({ caller }) func uploadAsset(file: Blob) : async Bool {
    if (Array.find<Principal>(authorizedUsers, func(u: Principal) { u == caller }) == null) {
      return false;
    };

    assetsInstance.store({ 
      caller; 
      arg = { 
        key = "user_upload"; 
        content_type = "application/octet-stream"; 
        content_encoding = "identity"; 
        content = file; 
        sha256 = null; 
      }
    });
    
    return true;
  };
}
