// ==UserScript==
// @name         French Tutor via Hotkey
// @namespace    http://example.com/
// @version      1.18
// @description  Process selected text using ChatGPT API via a keyboard shortcut with immediate popup feedback
// @author       Vadim Zaliva
// @match        *://*/*
// @grant        GM_xmlhttpRequest
// @grant        GM_getValue
// @grant        GM_setValue
// ==/UserScript==

(function () {
    'use strict';

    const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions";
    const OPENAI_MODEL = "gpt-5.5";

    async function getOpenAIKey() {
        let apiKey = await GM_getValue("openai_api_key", null);

        if (!apiKey) {
            apiKey = prompt("Enter your OpenAI API key:");

            if (apiKey) {
                await GM_setValue("openai_api_key", apiKey);
                alert("API key saved successfully!");
            } else {
                throw new Error("API key is required.");
            }
        }

        return apiKey;
    }

    async function sendToChatGPT(inputText) {
        const apiKey = await getOpenAIKey();

        const prompt = `You are my French teacher. I speak English. I will be giving you
snippets in French. Translate them to English and explain them.
Additionally, highlight some vocabulary beyond basic words and grammar
constructs. Respond in formatted HTML for display in a browser.

"${inputText}"`;

        return new Promise((resolve, reject) => {
            GM_xmlhttpRequest({
                method: "POST",
                url: OPENAI_API_URL,
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${apiKey}`
                },
                data: JSON.stringify({
                    model: OPENAI_MODEL,
                    messages: [
                        {
                            role: "system",
                            content: "You are a helpful French tutor. Return formatted HTML only."
                        },
                        {
                            role: "user",
                            content: prompt
                        }
                    ]
                }),
                onload: function (response) {
                    let data = null;

                    try {
                        data = JSON.parse(response.responseText);
                    } catch (_) {
                        // Non-JSON response; handled below.
                    }

                    if (response.status >= 200 && response.status < 300) {
                        const content = data?.choices?.[0]?.message?.content;

                        if (!content) {
                            reject("OpenAI response had no message content.");
                            return;
                        }

                        // Strip Markdown fences like ```html ... ```
                        const cleanedContent = content.replace(/```[a-zA-Z]*\n|```/g, "");
                        resolve(cleanedContent);
                    } else {
                        const apiMessage =
                            data?.error?.message ||
                            response.responseText ||
                            response.statusText ||
                            "Unknown API error";

                        reject(`OpenAI API error ${response.status}: ${apiMessage}`);
                    }
                },
                onerror: function (err) {
                    reject("Request failed: " + JSON.stringify(err));
                }
            });
        });
    }

    function escapeHtml(text) {
        return String(text)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function openPopupWithMessage(message) {
        const popup = window.open("", "ProcessedTextPopup", "width=700,height=500,scrollbars=yes");

        if (!popup) {
            alert("Popup blocked. Please allow popups for this site.");
            return null;
        }

        popup.document.open();
        popup.document.write(`
            <html>
            <head>
                <title>French Tutor</title>
                <style>
                    body {
                        font-family: Arial, sans-serif;
                        line-height: 1.6;
                        margin: 0;
                        padding: 10px;
                        overflow-y: auto;
                        background-color: #ffffff !important;
                        color: #000000 !important;
                    }

                    .content {
                        min-height: calc(100vh - 42px);
                        overflow-y: auto;
                        padding: 12px;
                        background-color: #ffffff !important;
                        color: #000000 !important;
                        border: 1px solid #ddd;
                        border-radius: 6px;
                    }

                    .status {
                        font-style: italic;
                        color: #555;
                    }

                    .error {
                        color: #900;
                        white-space: pre-wrap;
                    }
                </style>
            </head>
            <body>
                <div class="content">
                    <div class="status">${escapeHtml(message)}</div>
                </div>
            </body>
            </html>
        `);
        popup.document.close();

        return popup;
    }

    function updatePopupWithHtml(popup, html) {
        if (!popup || popup.closed) {
            popup = openPopupWithMessage("");
        }

        if (!popup) {
            return;
        }

        const content = popup.document.querySelector(".content");

        if (content) {
            content.innerHTML = html;
        }
    }

    function updatePopupWithError(popup, err) {
        const message = err instanceof Error ? err.message : String(err);

        updatePopupWithHtml(
            popup,
            `<div class="error"><strong>Error:</strong> ${escapeHtml(message)}</div>`
        );
    }

    document.addEventListener("keydown", async (event) => {
        if (event.ctrlKey && event.key === "Enter") {
            const selection = window.getSelection().toString().trim();

            if (!selection) {
                alert("No text selected. Please select text and try again.");
                return;
            }

            const popup = openPopupWithMessage("Working… contacting OpenAI.");

            if (!popup) {
                return;
            }

            try {
                const result = await sendToChatGPT(selection);
                updatePopupWithHtml(popup, result);
            } catch (err) {
                updatePopupWithError(popup, err);
            }
        }
    });
})();