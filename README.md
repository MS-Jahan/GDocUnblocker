![alt text](https://raw.githubusercontent.com/MS-Jahan/GDocUnblocker/main/assets/icons/app_icon.png "Title")

# GDocUnblocker
[Video Promo](https://www.youtube.com/watch?v=lD80-iX3zTs)

**GDocUnblocker** is a Flutter application designed to bypass download restrictions in Google Drive Doc/PDF previews. This app runs some Javascript code to capture the Doc/PDF pages as images and then converts them to PDF. As `webview_flutter` doesn't support downloads, the app achieves its goal by creating a local server on the device that handles POST requests from the WebView, allowing files to be saved directly to the device's storage.

## Features

- **WebView Integration**: Opens Google Drive PDF preview links in a WebView, offering different methods to unblock the download.
- **Local Server**: Runs a local server on the device to intercept and handle file downloads.
- **File Management**: Provides a file management system where users can view and open downloaded files.
- **Permissions Handling**: Automatically requests the necessary permissions to manage and access storage.

## How It Works

The core functionality of GDocUnblocker revolves around bypassing the typical download restrictions in WebView by setting up a local server on the Android device. When a file download is triggered within the WebView, instead of being blocked, the file is sent to the local server running on the device. Here's how it works step-by-step:

1. **WebView Integration**:
   - The app opens the Google Drive PDF preview in a WebView.
   - Depending on the user's selection, different scripts are injected to the webview to handle the download.

2. **Local Server**:
   - The app runs a local server on `localhost:8080` using the `shelf` package.
   - When a download is triggered, the WebView sends a POST request to this local server with the file data.

3. **File Handling**:
   - The local server receives the file data and saves it directly to the device's download directory.
   - The app updates its state to notify the user of a successful download.

4. **Viewing Downloads**:
   - The app includes a `Downloads` page where users can view and open all downloaded files.

## Getting Started

### Prerequisites

- **Flutter SDK**: Ensure that you have Flutter installed on your development machine. You can download it [here](https://flutter.dev/docs/get-started/install).
- **Android SDK**: Ensure that you have the Android SDK installed for Android development.

### Installation

1. **Clone the Repository**:
 ```bash
   git clone https://github.com/yourusername/GDocUnblocker.git
   cd GDocUnblocker
 ```

2. **Install Dependencies**:
 ```bash
   flutter pub get
 ```

3. **Run the App**:
 ```bash
   flutter run
 ```

### Usage

1. **Enter a Google Drive PDF preview URL**:
   - Copy any Google Drive PDF preview link and paste it into the input field.
   
2. **Select Unblock Method**:
   - Choose between the "Faster (Recommended)" and "Slower, Low Res" methods based on your preference.

3. **Download Files**:
   - Click the "Go" button, and the app will open the link in a WebView.
   - Click the "Generate PDF" button. After the PDF is generated, the app will handle the file download through the local server.
   - After the download is complete, you can view the files in the "Downloads" section.

### Permissions

The app requires the following permissions:

- **Storage Access**: To download and manage files.
- **Manage External Storage**: To handle files in broader storage directories.

### Troubleshooting

- **Server Not Working**: If the local server is not functioning, ensure that you have allowed the necessary storage permissions.
- **Download Issues**: If the download fails, try using the "Slower, Low Res" method, which might work better in some cases.

You may also see popups in the webview incase any error happens. Please create an issue if you encounter any.

## Contributing

We welcome contributions! Please fork this repository, create a feature branch, and submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

