// ==UserScript==
// @name         Google Drive PDF to PDF
// @namespace    http://tampermonkey.net/
// @version      1.12
// @description  Generate a PDF from images in a Google Drive PDF viewer by scrolling to each image, capturing them, and generating a PDF until the specified number of images is reached.
// @author       Your Name
// @match        https://drive.google.com/file/d/*/view
// @grant        none
// ==/UserScript==

(function () {
    'use strict';

    // Create a Trusted Types policy
    const policy = trustedTypes.createPolicy('default', {
        createHTML: (html) => html,
        createScriptURL: (url) => url
    });

    // Create a button and style it
    let button = document.createElement('button');
    button.style.position = 'fixed';
    button.style.right = '20px';
    button.style.top = '50%';
    button.style.transform = 'translateY(-50%)';
    button.style.zIndex = '1000';
    button.style.padding = '10px 20px';
    button.style.backgroundColor = '#007bff';
    button.style.color = '#fff';
    button.style.border = 'none';
    button.style.borderRadius = '5px';
    button.style.cursor = 'pointer';

    // Set the button's innerHTML using TrustedHTML
    button.innerHTML = policy.createHTML('Generate PDF');
    document.body.appendChild(button);

    // Function to delay execution
    const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

    // Function to wait for the image src to load
    async function waitForImageSrc(img) {
        let attempts = 0;
        while ((!img.src || img.src === '') && attempts < 5) {
            console.log(`Waiting for image src... Attempt ${attempts + 1}`);
            await sleep(1000); // Wait for 1 second
            attempts++;
        }
        return img.src;
    }

    // Function to find the total number of images (pages)
    function getTotalImages() {
        const spanElements = document.getElementsByTagName('span');
        for (let span of spanElements) {
            if (span.textContent.trim() === '/') {
                const nextDiv = span.nextElementSibling;
                if (nextDiv && nextDiv.tagName.toLowerCase() === 'div') {
                    const totalImages = parseInt(nextDiv.textContent.trim());
                    return isNaN(totalImages) ? 0 : totalImages;
                }
            }
        }
        return 0;
    }

    // Function to get the position of the last image on the page
    function getLastImagePosition() {
        let images = document.getElementsByTagName("img");
        let lastPosition = 0;
        for (let img of images) {
            let rect = img.getBoundingClientRect();
            let bottomPosition = rect.bottom + window.pageYOffset;
            if (bottomPosition > lastPosition) {
                lastPosition = bottomPosition;
            }
        }
        return lastPosition;
    }

    // Function to get the height of the scrollable element
    function getScrollableElement() {
        let allElements = document.querySelectorAll("*");
        let chosenElement;
        let heightOfScrollableElement = 0;
        for (let elem of allElements) {
            if (elem.scrollHeight >= elem.clientHeight) {
                if (heightOfScrollableElement < elem.scrollHeight) {
                    heightOfScrollableElement = elem.scrollHeight;
                    chosenElement = elem;
                }
            }
        }
        return chosenElement;
    }

    // Function to continuously scroll to and capture images
    async function scrollAndCaptureImages(pdf, totalImages) {
        let previousImageCount = 0;
        let imageCounter = 0;
        let lastImagePosition = 0;

        const scrollElement = getScrollableElement();
        if (!scrollElement) {
            console.log("No scrollable element found.");
            return;
        }

        const scrollDistance = Math.round(scrollElement.clientHeight*2);

        while (imageCounter < totalImages) {
            let elements = document.getElementsByTagName("img");
            let currentImageCount = elements.length;

            console.log("currentImageCount, totalImages, previousImageCount", currentImageCount, totalImages, previousImageCount)
            // print number of images in the pdf
            console.log(`Number of images in the pdf: ${pdf.internal.getNumberOfPages()}`);

            if (currentImageCount > previousImageCount) {
                console.log(`Found ${currentImageCount - previousImageCount} new images`);
                for (let i = previousImageCount; i < currentImageCount; i++) {
                    let img = elements[i];

                    // Scroll to the image before processing
                    img.scrollIntoView(
                        {
                            behavior: "smooth",
                            block: "center",
                            inline: "center"
                        }
                    );
                    await sleep(1200);

                    // Print the image src before checking validity
                    let imgSrc = await waitForImageSrc(img);
                    console.log("Image src:", imgSrc);

                    if (!/^blob:/.test(imgSrc)) {
                        console.log("Invalid src, skipping");
                        continue; // Skip this image and move to the next
                    }

                    console.log("Adding img ", img);
                    let can = document.createElement('canvas');
                    let con = can.getContext("2d");
                    can.width = img.width;
                    can.height = img.height;
                    con.drawImage(img, 0, 0);

                    let imgData = can.toDataURL("image/jpeg", 1.0);
                    pdf.addImage(imgData, 'JPEG', 0, 0);
                    pdf.addPage();

                    imageCounter++;
                    button.innerHTML = policy.createHTML(`Generating - ${imageCounter} / ${totalImages}`); // Update button text with progress

                    if (imageCounter % 5 === 0) {
                        await sleep(500); // Sleep for 0.5 seconds after every 5 images
                    }

                    if (imageCounter >= totalImages) {
                        console.log("Reached the total number of images, finishing PDF");
                        return; // Exit the function once all images are processed
                    }
                }
                previousImageCount = currentImageCount;

                // Update last image position
                lastImagePosition = getLastImagePosition();
            } else {
                console.log("No more new images found, scrolling down");

                // Scroll the element to load more images
                let scrollToLocation = scrollElement.scrollTop + scrollDistance;
                if (scrollToLocation >= scrollElement.scrollHeight) {
                    scrollToLocation = scrollElement.scrollHeight - scrollElement.clientHeight;
                }

                // scrollElement.scrollTo(0, scrollToLocation);
                // scroll smoothly
                scrollElement.scrollTo({
                    top: scrollToLocation,
                    behavior: 'smooth'
                });

                console.log(`Scrolled to position: ${scrollToLocation}`);

                await sleep(500); // Small delay to load new images

                // click on the last image to load more images
                let lastImage = document.querySelector('img:last-child');
                lastImage.click();

                // Check if we've reached the end of the document
                if ((scrollElement.scrollTop + scrollElement.clientHeight) >= scrollElement.scrollHeight) {
                    console.log("Reached the end of the document, but haven't found all images.");
                    // You might want to add additional logic here, such as retrying or breaking the loop
                }
            }
        }
    }
    // Function to generate PDF
    async function generatePDF() {
        let jspdf = document.createElement("script");
        jspdf.src = policy.createScriptURL('https://cdnjs.cloudflare.com/ajax/libs/jspdf/1.5.3/jspdf.debug.js');

        jspdf.onload = async function () {

            // get pdf file name from property="og:title"
            let pdfFileName = document.querySelector('meta[property="og:title"]').getAttribute('content').trim();
            if(pdfFileName === null || pdfFileName === ''){
                // ask user for pdf file name
                pdfFileName = prompt("Please enter the PDF file name:", "download");
            }

            let pdf = new jsPDF();
            const totalImages = getTotalImages(); // Get the total number of images
            console.log(`Total images: ${totalImages}`);

            button.style.backgroundColor = '#dc3545'; // Change button background to red
            button.style.color = '#fff'; // Change button text color to white
            button.innerHTML = policy.createHTML(`Generating - 0 / ${totalImages}`); // Initial status message

            await scrollAndCaptureImages(pdf, totalImages); // Continuously scroll to and capture images
            // pdf.save(pdfFileName); // Save the PDF
            let pdfBlob = pdf.output('blob')
            // console.log(pdfBlob);

            // let formData = new FormData();
            // formData.append('file', pdfBlob, pdfFileName);

            fetch('http://localhost:8080/upload', {
                method: 'POST',
                headers: {
                    // 'Content-Type': 'multipart/form-data',
                    "Content-Type": "application/json",
                    'filename': pdfFileName
                },
                body: pdfBlob
            }).then(response => {
                if (response.ok) {
                    alert('PDF downloaded successfully!');
                } else {
                    alert('Failed to download PDF.');
                }
            });

            button.innerHTML = policy.createHTML('Generate PDF'); // Reset button text
            button.style.backgroundColor = '#007bff'; // Reset button background color
            button.style.color = '#fff'; // Reset button text color
            button.disabled = false; // Re-enable the button
        };

        document.head.appendChild(jspdf);
    }

    // Add an event listener to the button
    button.addEventListener('click', async function () {
        button.innerHTML = policy.createHTML('Generating - 0 / 0'); // Update button text
        button.disabled = true; // Disable the button to prevent multiple clicks
        await generatePDF(); // Generate the PDF
    });
})();
