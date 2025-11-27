// Constants
const FALLBACK_TIMEOUT_MS = 1500;
const HIDDEN_THRESHOLD_MS = 800;
const BANNER_Z_INDEX = "9999999";
const BANNER_SELECTOR = ".smart-banner";

// Platform configuration
const platformConfig = {
  ios: {
    name: "iOS",
    storeUrl: "https://apps.apple.com/app/twake-chat/id6473384641",
    pattern: /iPhone|iPad|iPod/i,
  },
  android: {
    name: "android",
    storeUrl: "https://play.google.com/store/apps/details?id=app.twake.android.chat",
    pattern: /Android/i,
  },
};

const openAppDeepLink = "twake.chat://openapp";

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

function openTwakeChatApp() {
  const platform = getPlatform();
  const storeUrl = getStoreUrl(platform);

  if (!storeUrl) {
    closeSmartBanner();
    return;
  }

  let fallbackTimer = null;
  let hiddenAt = null;

  const onVisibility = () => {
    if (document.hidden) {
      hiddenAt = Date.now();
      clearFallback();
    }
  };

  const onBlur = () => {
    hiddenAt = Date.now();
    clearFallback();
  };

  const onPageHide = () => clearFallback();

  const clearFallback = () => {
    if (fallbackTimer) {
      clearTimeout(fallbackTimer);
      fallbackTimer = null;
    }
    window.removeEventListener("blur", onBlur);
    document.removeEventListener("visibilitychange", onVisibility);
    window.removeEventListener("pagehide", onPageHide);
  };

  document.addEventListener("visibilitychange", onVisibility);
  window.addEventListener("blur", onBlur);
  window.addEventListener("pagehide", onPageHide);

  window.location.href = openAppDeepLink;

  fallbackTimer = setTimeout(() => {
    const recentlyHidden = hiddenAt && (Date.now() - hiddenAt <= HIDDEN_THRESHOLD_MS);
    if (!document.hidden && !recentlyHidden) {
      window.open(storeUrl, '_top');
    }
  }, FALLBACK_TIMEOUT_MS);

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
