# `asset_storage`

## Overview

The `asset_storage` project is a frontend canister-based solution for managing assets on the Internet Computer (IC) using the `dfinity/assets` library. It enables asset storage, authentication, and permission management within a frontend canister.

## Workflow

### 1. Deploy the Frontend Canister  
Deploy the frontend canister using:

```bash
dfx deploy asset_storage_frontend
```

### 2. Grant Permissions  
Grant `ManagePermissions` to the frontend canister using:

```bash
dfx canister call <frontend_canister_id> grant_permission '(record { to_principal = principal "<frontend_canister_id>"; permission = variant { ManagePermissions } })'
```

Note : Replace `<frontend_canister_id>` with the actual canister ID of the frontend canister.

### 3. Create the Frontend Actor  
Use the `idlFactory` and `canisterId` from `declarations/asset_storage_frontend` to create the frontend actor.

### 4. Authenticate and Grant Commit Permission  
After user authentication, grant `Commit` permission to allow file uploads:

```javascript
await frontend.grant_permission({
    to_principal: userPrincipal,
    permission: { Commit: null }
});
```

### 5. Chunk and Store Assets  
Use the `AssetManager` from `dfinity/assets` to efficiently chunk and store files within the frontend canister.
