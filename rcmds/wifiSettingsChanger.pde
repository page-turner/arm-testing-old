void loadWifiSettings() {
  try {
    String[] settings=loadStrings("data/wifiSettings.txt");
    wifiIP=settings[0];
    wifiPort=int(settings[1]);
  }
  catch(Exception e) {
  }
}
