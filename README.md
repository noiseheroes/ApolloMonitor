# Apollo Monitor

A native macOS menu bar app for controlling your Universal Audio Apollo Solo monitor volume.

![Apollo Monitor](https://img.shields.io/badge/macOS-13.0+-blue) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Menu Bar Control** - Quick access to monitor controls from your menu bar
- **Volume Control** - Precise dB control with visual slider (-∞ to 0 dB)
- **Mute** - One-click mute toggle
- **Dim** - -17dB dim function for quick level reduction
- **Mono** - Mono summing for checking mixes
- **Real-time Sync** - Stays in sync with UA Console app
- **macOS Widget** - Desktop widget for at-a-glance monitoring (coming soon)

## Screenshots

*Coming soon*

## Requirements

- macOS 13.0 (Ventura) or later
- Universal Audio Apollo Solo (Thunderbolt)
- UA Console app running

## Installation

### From Releases

1. Download the latest `.dmg` from [Releases](https://github.com/noiseheroes/ApolloMonitor/releases)
2. Drag `Apollo Monitor.app` to your Applications folder
3. Launch the app - it will appear in your menu bar

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/noiseheroes/ApolloMonitor.git
   ```

2. Open `ApolloMonitor.xcodeproj` in Xcode

3. Build and run (⌘R)

## How It Works

Apollo Monitor communicates with the UA Console application via a local TCP socket on port 4710. This is the same protocol used by UA's own applications to control the Apollo hardware.

The app sends and receives JSON-formatted commands to control:
- Monitor level (`CRMonitorLevel`)
- Mute state (`Mute`)
- Dim state (`DimOn`)
- Mono state (`MixToMono`)

## Credits

### Protocol Discovery

The TCP protocol for communicating with Universal Audio devices was discovered and documented by the **[cuefinger](https://github.com/tschiemer/cuefinger)** project by [@tschiemer](https://github.com/tschiemer). This project would not be possible without their reverse engineering work.

### Development

- Developed by [Noise Heroes](https://github.com/noiseheroes)
- Built with assistance from Claude (Anthropic)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Disclaimer

This is an unofficial third-party application. Universal Audio, Apollo, and UA Console are trademarks of Universal Audio, Inc. This project is not affiliated with or endorsed by Universal Audio.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Support

If you encounter any issues, please [open an issue](https://github.com/noiseheroes/ApolloMonitor/issues) on GitHub.
