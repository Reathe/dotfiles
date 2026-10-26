# Version, description and homepage of installed packages, from the nixpkgs revisions flake.lock pins, plus with `refs`
# (the channels flake.nix follows, e.g. { stable = "nixpkgs/nixos-26.05"; … }) `update`: the channel's newer version, or null.
# nix eval --json --impure --file installed.nix --apply 'f: f { src = "<source dir>"; items = ''[{"attr": …, "list": "stable" or "unstable"}]''; }'
{
  src,
  items,
  refs ? null,
}:
let
  # git+file copies only tracked files; getFlake takes a bare path as path:, which copies .jj and every worktree
  # (a test copy without .git still needs path:)
  f = builtins.getFlake (
    if builtins.pathExists "${src}/.git" then "git+file://${src}" else "path:${src}"
  );
  inherit (f.inputs.nixpkgs) lib;
  pkgsFrom =
    flake:
    import flake {
      system = builtins.currentSystem;
      config.allowUnfree = true;
    };
  locked = {
    stable = pkgsFrom f.inputs.nixpkgs;
    unstable = pkgsFrom f.inputs.nixpkgs-unstable;
  };
  latest = lib.mapAttrs (_: ref: pkgsFrom (builtins.getFlake ref)) refs;
  find = set: attr: lib.attrByPath (lib.splitString "." attr) null set;
  info =
    x:
    let
      p = find locked.${x.list} x.attr;
      h = p.meta.homepage or "";
      version = p.version or null;
      newest = (find latest.${x.list} x.attr).version or null;
    in
    x
    // {
      inherit version;
      description = p.meta.description or "";
      homepage = if builtins.isList h then builtins.head h else h;
    }
    // lib.optionalAttrs (refs != null) {
      update =
        if version != null && newest != null && builtins.compareVersions newest version > 0 then
          newest
        else
          null;
    };
in
map info (builtins.fromJSON items)
