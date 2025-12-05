// Constants
const BANNER_Z_INDEX = "9999999";
const BANNER_SELECTOR = ".smart-banner";

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

function openTwakeChatApp() {
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

function initialTchatApp() {
  const platform = getPlatform();

  // Skip displaying the banner on desktop browsers
  if (platform === "other" || typeof window === "undefined") {
    return;
  }

  showSmartBanner();

  // Ensure the banner stays on top after Flutter re-renders
  const observer = new MutationObserver(() => {
    const banner = document.querySelector(BANNER_SELECTOR);
    if (banner) {
      banner.style.zIndex = BANNER_Z_INDEX;
    }
  });

  observer.observe(document.body, { childList: true, subtree: true });

  // Cleanup observer when page unloads
  window.addEventListener("unload", () => observer.disconnect(), { once: true });
}

function showSmartBanner() {
  const banner = document.querySelector(BANNER_SELECTOR);
  if (!banner) return;

  banner.style.display = "block";
  banner.style.zIndex = BANNER_Z_INDEX;
  banner.style.top = "16px";
  document.body.style.overflow = "hidden";
}

function closeSmartBanner() {
  const banner = document.querySelector(BANNER_SELECTOR);
  if (!banner) return;

  banner.style.display = "none";
  banner.style.top = "0";
  document.body.style.overflow = "auto";
}
