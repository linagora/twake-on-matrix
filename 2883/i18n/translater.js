const i18n = {};
const languageDefault = "en";
const defaultEngText = {
  title: "Download the new Twake Chat app",
  description: "Faster and more convenient",
  download: "Download",
};

/**
 * @description Check if the language is valid
 * @param {String} language
 * @returns {boolean}
 */
function isValidUserLanguage(language) {
  if (language == null || language == undefined) {
    return false;
  }
  return true;
}

/**
 * @description Get the user language
 * @returns {String}
 */
function getUserLanguage() {
  let userLanguage = languageDefault;

  try {
    const language = navigator.language;
    if (isValidUserLanguage(language)) {
      userLanguage = language.split("-")[0];
    }
  } catch (error) {
    console.error(`[Twake Chat] Error getting user language:`, error);
  }

  console.info(`[Twake Chat] Current Language: `, userLanguage);
  return userLanguage;
}

/**
 * @description Load the language resources
 * @returns {Promise<void>}
 */
async function loadLanguageResources() {
  const language = getUserLanguage();
  try {
    const response = await fetch(`./i18n/${language}.json`);
    const data = await response.json();
    i18n[language] = data;
    console.info(
      `[Twake Chat] Successfully loaded ${language} resources:`,
      i18n[language]
    );
  } catch (error) {
    console.error(`[Twake Chat] Error loading ${language} resources:`, error);
    i18n["en"] = defaultEngText;
    console.info(`[Twake Chat] Using default English resources:`, i18n["en"]);
  }
}

/**
 * @description Set the text content of smart banner
 * @typedef SetTextContentParams
 * @property {String} id
 * @property {String} text
 * @param {SetTextContentParams} param
 * @returns {void}
 */
function setTextContent({ id, text }) {
  const element = document.getElementById(id);
  if (element !== null) {
    element.textContent = text;
  }
}

document.addEventListener("DOMContentLoaded", async function () {
  await loadLanguageResources();
  const language = getUserLanguage();

  let languageResources = defaultEngText;

  if (i18n[language] !== null && i18n[language] !== undefined) {
    languageResources = i18n[language];
  }

  setTextContent({
    id: "banner-title-id",
    text: languageResources.title,
  });
  setTextContent({
    id: "banner-description-id",
    text: languageResources.description,
  });
  setTextContent({
    id: "download-button-id",
    text: languageResources.download,
  });
});
