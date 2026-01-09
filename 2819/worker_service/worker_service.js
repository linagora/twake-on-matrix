// Constants
const BANNER_Z_INDEX = "9999999";
const BANNER_SELECTOR = ".smart-banner";
const TRANSITION_DURATION_MS = 300;

// Platform configuration
const platformConfig = {
  ios: {
    name: "iOS",
    storeUrl: "https://apps.apple.com/cm/app/twake-chat/id6473384641",
    pattern: /iPhone|iPad|iPod/i,
  },
  android: {
    name: "android",
    storeUrl: "https://play.google.com/store/apps/details?id=app.twake.android.chat",
    pattern: /Android/i,
  },
};

const universalLinkBase = "https://links.twake.app/chat";

function getPlatform() {
  const ua = navigator.userAgent || navigator.vendor || window.opera;
  if (platformConfig.ios.pattern.test(ua)) return platformConfig.ios.name;
  if (platformConfig.android.pattern.test(ua)) return platformConfig.android.name;
  return "other";
}

function getStoreUrl(platform) {
  if (platform === platformConfig.ios.name) return platformConfig.ios.storeUrl;
  if (platform === platformConfig.android.name) return platformConfig.android.storeUrl;
  return null;
}

function getUniversalLink(platform) {
  const storeUrl = getStoreUrl(platform);
  if (!storeUrl) return null;
  return `${universalLinkBase}?fallback=${encodeURIComponent(storeUrl)}`;
}

/**
 * Attempts to open the Twake Chat app via deep link, falling back to the app store.
 * Uses visibility detection to determine if the app opened successfully.
 */
function downloadTwakeChatApp() {
  const platform = getPlatform();
  const universalLink = getUniversalLink(platform);

  if (!universalLink) {
    closeSmartBanner();
    return;
  }

  console.log('[Twake Banner] Opening universal link:', universalLink);

  // Try to open universal link in new tab
  // Universal links will automatically:
  // - Open the app if installed
  // - Redirect to fallback URL if app not installed
  const newWindow = window.open(universalLink, '_blank');

  // Check if popup was blocked (common in cross-origin iframes)
  if (!newWindow || newWindow.closed || typeof newWindow.closed === 'undefined') {
    console.warn('[Twake Banner] ⚠️ Popup blocked - likely in restrictive iframe');
    console.log('[Twake Banner] Universal link:', universalLink);
    console.log('[Twake Banner] Copy the link above to test manually');
    // Popup was blocked - in a production environment, you might want to:
    // - Show a message to the user
    // - Try alternative approaches (e.g., navigate parent window if allowed)
    // - Or silently fail (current behavior)
  } else {
    console.log('[Twake Banner] ✅ Universal link opened successfully');
  }

  closeSmartBanner();
}

// MutationObserver instance (module-level to manage lifecycle)
let bannerObserver = null;

/**
 * Initializes the Twake Chat app banner on mobile platforms.
 * The banner will display on every page load for mobile users.
 */
function initTwakeChatApp() {
  const platform = getPlatform();

  // Skip displaying the banner on desktop browsers
  if (platform === "other" || typeof window === "undefined") {
    return;
  }

  showSmartBanner();
}

// Maintain backward compatibility
const initialTchatApp = initTwakeChatApp;

/**
 * Displays the smart banner with a smooth transition.
 * Sets up a MutationObserver to ensure the banner stays on top after Flutter re-renders.
 */
function showSmartBanner() {
  const banner = document.querySelector(BANNER_SELECTOR);
  if (!banner) return;

  banner.style.display = "block";
  banner.style.zIndex = BANNER_Z_INDEX;

  // Force reflow before adding class for smooth transition
  banner.offsetHeight;
  banner.classList.add("visible");

  // Ensure the banner stays on top after Flutter re-renders
  if (!bannerObserver) {
    bannerObserver = new MutationObserver(() => {
      const currentBanner = document.querySelector(BANNER_SELECTOR);
      if (currentBanner && currentBanner.style.display !== "none") {
        currentBanner.style.zIndex = BANNER_Z_INDEX;
      }
    });

    // Only observe the banner's parent, not entire body
    const parent = banner.parentElement;
    if (parent) {
      bannerObserver.observe(parent, { childList: true });
    }

    // Cleanup observer when pagehide
    window.addEventListener("pagehide", () => {
      if (bannerObserver) {
        bannerObserver.disconnect();
        bannerObserver = null;
      }
    }, { once: true });
  }
}

/**
 * Closes the smart banner with a smooth transition.
 * The banner will reappear on the next page reload.
 */
function closeSmartBanner() {
  const banner = document.querySelector(BANNER_SELECTOR);
  if (!banner) return;

  banner.classList.remove("visible");

  // Hide after transition completes
  setTimeout(() => {
    if (!banner.classList.contains("visible")) {
      banner.style.display = "none";
    }
  }, TRANSITION_DURATION_MS);

  // Disconnect observer when banner is closed
  if (bannerObserver) {
    bannerObserver.disconnect();
    bannerObserver = null;
  }
}
