name: Build APK

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    name: Build Android APK
    runs-on: ubuntu-latest

    steps:
      # 1. Checkout code
      - name: Checkout repository
        uses: actions/checkout@v4

      # 2. Setup Java
      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      # 3. Setup Flutter
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'

      # 4. Download fonts
      - name: Download Pacifico font
        run: |
          mkdir -p assets/fonts
          curl -L "https://github.com/google/fonts/raw/main/ofl/pacifico/Pacifico-Regular.ttf" \
            -o assets/fonts/Pacifico-Regular.ttf

      - name: Download Inter fonts
        run: |
          curl -L "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip" \
            -o inter.zip
          unzip -o inter.zip -d inter_tmp
          cp inter_tmp/Inter\ Desktop/Inter-Regular.otf assets/fonts/Inter-Regular.ttf || \
          find inter_tmp -name "Inter-Regular*" | head -1 | xargs -I{} cp {} assets/fonts/Inter-Regular.ttf || true
          find inter_tmp -name "Inter-Medium*" | head -1 | xargs -I{} cp {} assets/fonts/Inter-Medium.ttf || true
          find inter_tmp -name "Inter-SemiBold*" | head -1 | xargs -I{} cp {} assets/fonts/Inter-SemiBold.ttf || true
          find inter_tmp -name "Inter-Bold*" | head -1 | xargs -I{} cp {} assets/fonts/Inter-Bold.ttf || true
          rm -rf inter_tmp inter.zip

      # 5. Create app icon if not present
      - name: Create app icon placeholder
        run: |
          mkdir -p assets/icons
          if [ ! -f assets/icons/app_icon.png ]; then
            # Create a simple yellow icon using Python
            python3 - <<'EOF'
          import struct, zlib, math

          def create_png(size=512):
              def png_chunk(name, data):
                  chunk = name + data
                  return struct.pack('>I', len(data)) + chunk + struct.pack('>I', zlib.crc32(chunk) & 0xffffffff)
              
              # Header
              sig = b'\x89PNG\r\n\x1a\n'
              ihdr_data = struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)
              ihdr = png_chunk(b'IHDR', ihdr_data)
              
              # Image data - warm yellow background with "MK" text area
              raw = []
              for y in range(size):
                  row = [0]  # filter byte
                  for x in range(size):
                      cx, cy = x - size//2, y - size//2
                      dist = math.sqrt(cx*cx + cy*cy)
                      # Rounded square shape
                      in_shape = abs(cx) < size*0.42 and abs(cy) < size*0.42
                      corner_r = size * 0.15
                      in_corner = (abs(cx) > size*0.42 - corner_r or abs(cy) > size*0.42 - corner_r)
                      
                      if in_shape:
                          # Yellow gradient
                          grad = 1.0 - (abs(cx) + abs(cy)) / (size * 0.8)
                          r = min(255, int(255 - grad * 20))
                          g = min(255, int(215 - grad * 10))
                          b = 0
                      else:
                          r, g, b = 255, 249, 230  # background
                      row.extend([r, g, b])
                  raw.append(bytes(row))
              
              compressed = zlib.compress(b''.join(raw))
              idat = png_chunk(b'IDAT', compressed)
              iend = png_chunk(b'IEND', b'')
              return sig + ihdr + idat + iend

          with open('assets/icons/app_icon.png', 'wb') as f:
              f.write(create_png(512))
          with open('assets/icons/app_icon_fg.png', 'wb') as f:
              f.write(create_png(512))
          print("Icons created")
          EOF
          fi

      # 6. Install dependencies
      - name: Install Flutter dependencies
        run: flutter pub get

      # 7. Generate launcher icons
      - name: Generate launcher icons
        run: flutter pub run flutter_launcher_icons
        continue-on-error: true

      # 8. Build APK
      - name: Build release APK
        run: flutter build apk --release --no-tree-shake-icons

      # 9. Rename APK
      - name: Rename APK
        run: |
          mv build/app/outputs/flutter-apk/app-release.apk \
             build/app/outputs/flutter-apk/MyKeep-v1.0.0.apk

      # 10. Upload APK as artifact
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: MyKeep-APK
          path: build/app/outputs/flutter-apk/MyKeep-v1.0.0.apk
          retention-days: 30

      # 11. Create GitHub Release (on push to main)
      - name: Create Release
        if: github.ref == 'refs/heads/main'
        uses: softprops/action-gh-release@v1
        with:
          tag_name: v1.0.0
          name: My Keep v1.0.0
          body: |
            ## My Keep - Personal Notes App
            
            ### Features
            - Clean minimal UI with warm yellow theme
            - Dark / Light mode toggle
            - PIN lock for individual notes
            - Pin notes to top
            - Color-coded note cards
            - Search notes
            - Categories / Labels
            - Trash with restore option
            - 100% offline — no internet needed
            
            ### Install
            Download `MyKeep-v1.0.0.apk` below and install on your Android device.
            > Enable "Install from unknown sources" in Settings if needed.
          files: build/app/outputs/flutter-apk/MyKeep-v1.0.0.apk
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        continue-on-error: true
