// ==UserScript==
// @name         French Tutor via Hotkey
// @namespace    http://example.com/
// @version      1.16
// @description  Process selected text using ChatGPT API via a keyboard shortcut with simplified popup
// @author       Vadim Zaliva
// @match        *://*/*
// @grant        GM_xmlhttpRequest
// @grant        GM_getValue
// @grant        GM_setValue
// ==/UserScript==

(function () {
    'use strict';

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

    const OPENAI_API_URL = "https://api.openai.com/v1/chat/completions";

    async function sendToChatGPT(inputText) {
        const apiKey = await getOpenAIKey();
        const prompt = `You are my French teacher. I speak English. I will be giving you
snippets in French. Translate them to English and explain them.
Additionally, highlight some vocabulary (beyond basic one) and grammar
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
                    model: "gpt-4",
                    messages: [
                        { role: "system", content: "You are a helpful assistant." },
                        { role: "user", content: prompt }
                    ]
                }),
                onload: function (response) {
                    if (response.status === 200) {
                        const data = JSON.parse(response.responseText);
                        // Strip Markdown quotes like ```HTML or ```
                        const cleanedContent = data.choices[0].message.content.replace(/```[a-zA-Z]*\n|```/g, "");
                        resolve(cleanedContent);
                    } else {
                        reject("Error with ChatGPT API: " + response.statusText);
                    }
                },
                onerror: function (err) {
                    reject("Request failed: " + err);
                }
            });
        });
    }

    function showPopup(processedText) {
        const popup = window.open("", "ProcessedTextPopup", "width=600,height=400,scrollbars=yes");
        if (!popup) {
            alert("Popup blocked. Please allow popups for this site.");
            return;
        }

        popup.document.write(`
            <html>
            <head>
                <title>Processed Text</title>
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
                        max-height: calc(100% - 20px);
                        overflow-y: auto;
                        padding: 10px;
                        background-color: #ffffff !important;
                        color: #000000 !important;
                        border: 1px solid #ddd;
                    }
                </style>
            </head>
            <body>
                <div class="content">${processedText}</div>
            </body>
            </html>
        `);
    }

    document.addEventListener("keydown", async (event) => {
        if (event.ctrlKey && event.key === "Enter") {
            const selection = window.getSelection().toString();
            if (selection) {
                try {
                    const result = await sendToChatGPT(selection);
                    showPopup(result);
                } catch (err) {
                    alert("Error: " + err);
                }
            } else {
                alert("No text selected. Please select text and try again.");
            }
        }
    });
})();
