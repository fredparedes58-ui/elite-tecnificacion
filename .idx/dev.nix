# To learn more about how to use Nix to configure your environment
# see: https://firebase.google.com/docs/studio/customize-workspace
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "unstable"; # or "stable-24.05"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.flutter
    pkgs.jdk21
    pkgs.unzip
    pkgs.google-chrome
  ];
  # Sets environment variables in the workspace
  env = {
    CHROME_EXECUTABLE = "/nix/store/vqhs79yfvjqxl8178mhvyz2cqjrqk217-google-chrome-131.0.6778.139/share/google/chrome/google-chrome";
    FLUTTER_SDK = "/nix/store/vjwj46wpaxfqq6gwmnynl4hl6fmzqjsa-flutter-wrapped-3.38.3-sdk-links";
  };
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];
    workspace = {
      # Runs when a workspace is first created with this `dev.nix` file
      onCreate = { };
      # To run something each time the workspace is (re)started, use the `onStart` hook
    };
    # Enable previews and customize configuration
    previews = {
      enable = true;
      previews = {
        web = {
          command = ["flutter" "run" "--machine" "-d" "web-server" "--web-hostname" "0.0.0.0" "--web-port" "$PORT"];
          manager = "flutter";
        };
        android = {
          command = ["flutter" "run" "--machine" "-d" "android" "-d" "localhost:5555"];
          manager = "flutter";
        };
      };
    };
  };
}
# Refresh environment
