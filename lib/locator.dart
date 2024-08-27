import 'package:get_it/get_it.dart';
import 'download_state.dart'; // Import your state model

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerSingleton<DownloadState>(DownloadState());
}
