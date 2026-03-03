sudo apt install libgtk-4-dev libadwaita-1-dev git
brew install zig
git clone https://github.com/ghostty-org/ghostty.git
cd ghostty
zig build -p $HOME/.local -Doptimize=ReleaseFast
