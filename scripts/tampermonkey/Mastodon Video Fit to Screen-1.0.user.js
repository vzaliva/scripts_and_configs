// ==UserScript==
// @name         Mastodon Video Fit to Screen
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Resize videos on Mastodon if they don't fit the screen vertically
// @author       You
// @match        https://twiukraine.com/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    function adjustVideoSize() {
        // Find all video containers
        let videoContainers = document.querySelectorAll('.video-player');

        // Loop through each video container
        videoContainers.forEach(function(container) {
            let video = container.querySelector('video');

            setTimeout(function() {
                // Get the original aspect ratio of the video
                let aspectRatio = video.videoWidth / video.videoHeight;

                // Get the viewport height
                let viewportHeight = window.innerHeight;

                if (container.offsetHeight > 0.9*viewportHeight) {
                    let desiredHeight = viewportHeight * 0.8;
                    let newWidth = desiredHeight * aspectRatio;

                    //console.log("Resizing video. Original aspect ratio:", aspectRatio, "Desired height:", desiredHeight, "New width:", newWidth);

                    container.style.maxHeight = desiredHeight + 'px';
                    container.style.width = newWidth + 'px';
                    container.style.overflow = 'hidden';

                    video.style.height = '100%';
                    video.style.width = '100%';
                }
            }, 500);
        });
    }

    window.addEventListener('load', adjustVideoSize);
    let observer = new MutationObserver(adjustVideoSize);
    observer.observe(document.body, { childList: true, subtree: true });
})();
