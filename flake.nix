{
  description = "";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/24.11";

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      electronBuilds = {
        "34.5.1" = {
          "linux-x64" = pkgs.fetchurl {
            url =
              "https://github.com/electron/electron/releases/download/v34.5.1/electron-v34.5.1-linux-x64.zip";
            sha256 = "sha256-Oub3X6CPXBvbe7zsTcnPfX9T/89qQpLkpIKyzlFVBec=";
          };
        };
      };
      electronZipDir = let electronBuild = electronBuilds."34.5.1";
      in pkgs.linkFarm "electron-zip-dir" [{
        name = "${electronBuild.linux-x64.name}";
        path = electronBuild.linux-x64;
      }];
    in {
      devShell.x86_64-linux = pkgs.mkShell {
        buildInputs = with pkgs; [
          python312
          nodejs_22
          corepack
          pkg-config
          krb5
          glib
          nss
          nspr
          dbus
          libdbusmenu
          # Add gtk3 which is needed by Electron
          gtk3
          # Add missing libraries found in ldd output
          expat
          udev
          # Other dependencies that Electron might need
          at-spi2-atk
          at-spi2-core
          cups
          libdrm
          libxkbcommon
          mesa
          xorg.libxkbfile
          xorg.libxcb
          xorg.libX11
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXrandr
          # Additional potentially needed libraries
          alsa-lib
          cairo
          pango
          libepoxy
          gdk-pixbuf
          yarn
        ];
        shellHook = ''
          # More explicit library path handling
          export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${
            pkgs.lib.makeLibraryPath [
              pkgs.glib
              pkgs.nss
              pkgs.nspr
              pkgs.dbus
              pkgs.libdbusmenu
              pkgs.gtk3
              pkgs.expat
              pkgs.udev
              pkgs.at-spi2-atk
              pkgs.at-spi2-core
              pkgs.cups
              pkgs.libdrm
              pkgs.libxkbcommon
              pkgs.mesa
              pkgs.xorg.libxcb
              pkgs.xorg.libX11
              pkgs.xorg.libXcomposite
              pkgs.xorg.libXdamage
              pkgs.xorg.libXext
              pkgs.xorg.libXfixes
              pkgs.xorg.libXrandr
              pkgs.alsa-lib
              pkgs.cairo
              pkgs.pango
              pkgs.libepoxy
              pkgs.gdk-pixbuf
            ]
          }"

          # Debug info
          echo "LD_LIBRARY_PATH is set to: $LD_LIBRARY_PATH"

          # Check for critical libraries
          echo "Checking for critical libraries..."
          find ${pkgs.dbus}/lib -name "libdbus*.so*" || echo "No libdbus in ${pkgs.dbus}/lib"
          find ${pkgs.gtk3}/lib -name "libgtk-3.so*" || echo "No libgtk-3 in ${pkgs.gtk3}/lib"

          # Extra debug for missing libraries
          echo "Running ldd on code-oss binary (if it exists)..."
          if [ -f .build/electron/code-oss ]; then
            ldd .build/electron/code-oss | grep "not found" || echo "All libraries found"
          else
            echo ".build/electron/code-oss not found yet"
          fi
        '';
        electron_zip_dir = electronZipDir;
        ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
      };
    };
}
