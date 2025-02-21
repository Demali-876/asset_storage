<script>
import "../index.scss";
import { onMount } from "svelte";
import { AssetManager } from "@dfinity/assets";
import { HttpAgent, Actor } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { idlFactory, canisterId } from 'declarations/asset_storage_frontend';

const ASSET_CANISTER_ID = "bd3sg-teaaa-aaaaa-qaaba-cai";
const isLocal = process.env.DFX_NETWORK !== "ic";

let selectedFile = null;
let uploadProgress = 0;
let uploadMessage = "";
let assetManager = null;
let userPrincipal = null;
let isAuthenticated = false;
let isAuthorized = false;
let authClient = null;
let agent = null;

async function initAuth() {
    try {
        authClient = await AuthClient.create({
            idleOptions: {
                idleTimeout: 1000 * 60 * 30,
                disableDefaultIdleCallback: true,
            },
        });
        
        const identity = await authClient.getIdentity();
        agent = new HttpAgent({
            identity,
            host: isLocal ? "http://127.0.0.1:4943" : "https://ic0.app",
        });

        if (isLocal) {
            await agent.fetchRootKey();
        }

        if (await authClient.isAuthenticated()) {
            await handleAuthenticated(identity);
        }
    } catch (error) {
        console.error("Failed to initialize auth:", error);
        uploadMessage = "❌ Failed to initialize authentication.";
    }
}

async function handleAuthenticated(identity) {
    try {
        userPrincipal = identity.getPrincipal();
        isAuthenticated = true;

        assetManager = new AssetManager({
            canisterId: ASSET_CANISTER_ID,
            agent,
            
            maxChunkSize: 1900000,
        });

        console.log("User Principal:", userPrincipal.toText());
        await authorizeUser();
    } catch (error) {
        console.error("Error handling authentication:", error);
        uploadMessage = "❌ Failed to setup after authentication.";
    }
}

async function login() {
    try {
        const identityProvider = isLocal
            ? "http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:4943"
            : "https://identity.ic0.app";

        await authClient.login({
            identityProvider,
            maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
            onSuccess: async () => {
                const identity = await authClient.getIdentity();
                await handleAuthenticated(identity);
            },
            onError: (err) => {
                console.error("Authentication failed:", err);
                uploadMessage = "❌ Authentication failed.";
            },
        });
    } catch (error) {
        console.error("Login failed:", error);
        uploadMessage = "❌ Login failed.";
    }
}

async function authorizeUser() {
    try {
        if (!userPrincipal) {
            throw new Error("No user principal found.");
        }

        console.log("Starting authorization process for:", userPrincipal.toText());

        const assetActor = Actor.createActor(idlFactory, {
            agent,
            canisterId: canisterId
        });

        try {
            await assetActor.grant_permission({
                to_principal: userPrincipal,
                permission: { Commit: null }
            });
            console.log("✅ Granted Commit permission to user");
        } catch (error) {
            console.warn("Grant Commit permission warning:", error);
        }

        isAuthorized = true;
        uploadMessage = "✅ Authorization successful!";
        console.log("✅ Authorization process completed");
    } catch (error) {
        console.error("❌ Authorization failed:", error);
        uploadMessage = `❌ Authorization failed: ${error.message}`;
        isAuthorized = false;
    }
}

function handleFileChange(event) {
    selectedFile = event.target.files[0];
    uploadMessage = "";
}

async function uploadFile() {
    if (!selectedFile) {
        uploadMessage = "❌ Please select a file.";
        return;
    }

    if (!isAuthenticated) {
        uploadMessage = "❌ You must log in first.";
        return;
    }

    if (!isAuthorized) {
        uploadMessage = "❌ Authorization required.";
        return;
    }

    uploadProgress = 0;
    uploadMessage = "Uploading...";

    try {
        const key = await assetManager.store(selectedFile, {
            onProgress: ({ current, total }) => {
                uploadProgress = (current / total) * 100;
            },
        });

        uploadMessage = `✅ Upload successful! File ID: ${key}`;
        selectedFile = null;
        
        const fileInput = document.querySelector('input[type="file"]');
        if (fileInput) fileInput.value = '';
    } catch (error) {
        console.error("Upload failed:", error);
        uploadMessage = `❌ Upload failed: ${error.message}`;
    }
}

onMount(initAuth);
</script>

<main class="upload-container">
  <div class="upload-box">
    <h1>Asset Upload</h1>
    
    {#if !isAuthenticated}
      <button class="login-btn" on:click={login}>
        Login to Internet Identity
      </button>
    {:else}

      <div class="upload-controls">
        <label class="file-input">
          <input 
            type="file" 
            on:change={handleFileChange}
            disabled={!isAuthorized} 
          />
          Choose a File
        </label>

        {#if selectedFile}
          <p class="selected-file">
            Selected: {selectedFile.name} ({Math.round(selectedFile.size / 1024)} KB)
          </p>
        {/if}

        <button 
          class="upload-btn" 
          on:click={uploadFile}
          disabled={!selectedFile || !isAuthorized}
        >
          Upload File
        </button>
      </div>

      {#if !isAuthorized}
        <button class="authorize-btn" on:click={authorizeUser}>
          Authorize Access
        </button>
      {/if}
    {/if}

    {#if uploadProgress > 0 && uploadProgress < 100}
      <div class="progress-bar">
        <div class="progress" style="width: {uploadProgress}%"></div>
        <span class="progress-text">{Math.round(uploadProgress)}%</span>
      </div>
    {/if}

    {#if uploadMessage}
      <p class="upload-message" class:error={uploadMessage.includes('❌')}>
        {uploadMessage}
      </p>
    {/if}
  </div>
  <footer>
    <div class="footer-logos">
      <img src="qll.png" alt="QLL Logo" class="footer-logo qll" />
      <img src="iclogo.png" alt="IC Logo" class="footer-logo ic" />
    </div>
  </footer>
</main>