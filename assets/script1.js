// ==UserScript==
// @name         Google Drive PDF to PDF (Optimized)
// @namespace    http://tampermonkey.net/
// @version      1.13
// @description  Generate a PDF from images in a Google Drive PDF viewer by sending GET requests directly to fetch images, without scrolling.
// @author       Your Name
// @match        https://drive.google.com/file/d/*
// @grant        none
// ==/UserScript==

// @match        https://drive.google.com/file/d/*/view

try {
    (function () {
        'use strict';
        
        try {
            // Create a Trusted Types policy
            var policy = trustedTypes.createPolicy('default', {
                createHTML: (html) => html,
                createScriptURL: (url) => url
            });
        } catch (error) {
            // alert("Error message:" + error.message);
            alert("Stack trace:" + error.stack);
        }

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

        // Function to extract the required string from the HTML
        // function extractImageString() {
        //     const htmlContent = document.documentElement.innerHTML;
        //     const startIndex = htmlContent.indexOf('https://drive.google.com/viewer2/prod-03/meta?ck\\u003ddrive\\u0026ds\\u003d');
        //     if (startIndex === -1) return null;

        //     const endIndex = htmlContent.indexOf('"', startIndex);
        //     if (endIndex === -1) return null;

        //     const extractedString = htmlContent.substring(startIndex + 'https://drive.google.com/viewer2/prod-03/meta?ck\\u003ddrive\\u0026ds\\u003d'.length, endIndex);
        //     return extractedString;
        // }

        function extractImageString() {
            const htmlContent = document.documentElement.innerHTML;
            // Regular expression to match the dynamic URL pattern
            const mysteryStringRegex = /https:\/\/drive\.google\.com\/viewer[^"]*meta\?ck\\u003ddrive\\u0026ds\\u003d[^"]*/;
            
            // Find the first match in the HTML content
            const match = htmlContent.match(mysteryStringRegex);
            
            if (match) {
                let full_url =  match[0];  // Return the matched URL
                console.log(full_url);
                console.log(full_url.split('ck\\u003ddrive\\u0026ds\\u003d'));
                let extractedString = full_url.split('ck\\u003ddrive\\u0026ds\\u003d')[1];
                return extractedString;
            }
            
            return null;  // Return null if no match is found
        }

        // Function to generate the image URL for each page
        function generateImageURL(imageString, pageNumber) {
            return `https://drive.google.com/viewer2/prod-03/img?ck=drive&ds=${imageString}&authuser=0&page=${pageNumber}&skiphighlight=true&w=800&webp=true`;
        }

        // Function to generate PDF
        async function generatePDF() {
            let jspdf = document.createElement("script");
            jspdf.src = policy.createScriptURL('https://cdnjs.cloudflare.com/ajax/libs/jspdf/1.5.3/jspdf.debug.js');

            jspdf.onload = async function () {
                // Get the PDF file name from property="og:title"
                let pdfFileName = document.querySelector('meta[property="og:title"]').getAttribute('content').trim();
                if (!pdfFileName) {
                    pdfFileName = prompt("Please enter the PDF file name:", "download");
                }

                // if .pdf isn't last of the file name, add .pdf
                if (!pdfFileName.endsWith('.pdf')) {
                    pdfFileName += '.pdf';
                }

                let pdf = new jsPDF();
                const totalImages = getTotalImages(); // Get the total number of images
                const imageString = extractImageString(); // Extract the required string
                if (!imageString) {
                    console.log("Failed to extract image string.");
                    return;
                }

                button.style.backgroundColor = '#dc3545'; // Change button background to red
                button.style.color = '#fff'; // Change button text color to white
                button.innerHTML = policy.createHTML(`Generating - 0 / ${totalImages}`); // Initial status message

                for (let i = 1; i <= totalImages; i++) {
                    const imageURL = generateImageURL(imageString, i-1);
                    try {
                        const response = await fetch(imageURL);
                        if (response.ok && response.headers.get("content-type").startsWith("image/")) {
                            const blob = await response.blob();
                            const img = document.createElement('img');
                            img.src = URL.createObjectURL(blob);

                            // Ensure the image is fully loaded before drawing it to the canvas
                            await img.decode();

                            const can = document.createElement('canvas');
                            const con = can.getContext("2d");
                            can.width = img.width;
                            can.height = img.height;
                            con.drawImage(img, 0, 0);

                            const imgData = can.toDataURL("image/jpeg", 1.0);
                            if (imgData.startsWith("data:image/jpeg")) {
                                pdf.addImage(imgData, 'JPEG', 0, 0);
                                pdf.addPage();
                            } else {
                                console.log(`Skipping image on page ${i} due to invalid base64 string.`);
                            }
                        } else {
                            console.log(`Failed to load image for page ${i}`);
                        }
                    } catch (error) {
                        console.log(`Error fetching image for page ${i}:`, error);
                    }

                    button.innerHTML = policy.createHTML(`Generating - ${i} / ${totalImages}`); // Update progress

                    if (i % 6 === 0) {
                        await sleep(1000); // Pause for 2 seconds after every 6 requests
                    } else {
                        await sleep(1); // Pause for 0.2 seconds after each request
                    }
                }

                // pdf.save(pdfFileName); // Save the PDF
                // let pdfBlob = pdf.output('bloburl');
                // let pdfLink = document.createElement('a');
                // pdfLink.href = pdfBlob;
                // pdfLink.download = pdfFileName;
                // pdfLink.click();

                let pdfBlob = pdf.output('blob')
                console.log(pdfBlob);

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

                // instead of using fetch, use XMLHttpRequest
                // let xhr = new XMLHttpRequest();
                // xhr.open("POST", "http://localhost:8080/upload", true);
                // xhr.setRequestHeader("Content-Type", "application/json");
                // xhr.setRequestHeader("filename", pdfFileName);
                // xhr.send(pdfBlob);

                // xhr.onreadystatechange = function () {
                //     if (xhr.readyState == 4 && xhr.status == 200) {
                //         alert('PDF uploaded successfully!');
                //     } else {
                //         alert('Failed to upload PDF.' + xhr.status);
                //     }
                // }

                // }).catch(error => {
                //     console.log('Error:', error);
                //     console.log('Error stack:', error.stack);
                //     // let error_stack = error.stack;
                //     // // split the error_stack into multiple chunks, each of 50 characters and show as alert
                //     // let error_stack_chunks = [];
                //     // for (let i = 0; i < error_stack.length; i += 50) {
                //     //     alert(error_stack.slice(i, i + 50));
                //     // }

                // });


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
} catch (error) {
    alert("Error message:" + error.message);
    alert("Stack trace:" + error.stack);
}
