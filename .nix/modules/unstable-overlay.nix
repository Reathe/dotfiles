{ nixpkgs-unstable, ... }:
{
  nixpkgs.overlays = [
    (
      final: _prev:
      {
        inherit (nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system})
          lazygit
          gemini-cli
          opencode
          codex
          ;
      }
    )
  ];
}
