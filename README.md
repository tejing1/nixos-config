This is my (tejing's) personal NixOS configuration flake.

It isn't really intended for actual use by others, but examining the code may be interesting. Even so, it should build even without the keys to `git-crypt unlock` it, since I use `self.lib.readSecret`/`self.lib.importSecret` to access the encrypted files, and provide a non-secret default value for the case where they aren't unlocked.

## Layout
- My nixos config is split into many profiles which can be found under `nixosConfigurations/tejingdesk/`.
- My home-manager config is split into many profiles which can be found under `homeConfigurations/tejing/`.

File layout generally follows the flake output structure through the use of various forms of `self.lib.importAll`, which imports every `.nix` file and every directory with a `default.nix`, to form an attrset.

I've tried to expose components that may be useful on their own as flake outputs, accessing them through `self` in my main configuration.

## Notable structures
- Files in `genericModules/` are exposed in outputs as both `nixosModules` and `homeModules`
- I use `my.*` options, which are also re-supplied through the `my` module argument, in both home-manager and nixos. This hierarchy contains components from `self`, and configuration options for any locally defined modules.
  - `my.lib` contains the output of `self.libFunc`, applied to whatever nixpkgs instance is appropriate, or `self.lib` if there is no appropriate nixpkgs instance available.
  - `my.pkgs` contains the output of `self.packagesFunc`, applied to whatever nixpkgs instance is appropriate.
  - `my.overlays` is `self.overlays`
- I expose my packages through the `self.packagesFunc` output, which I then use to create `self.packages.*`. `self.packagesFunc` accepts a nixpkgs instantiation (a `pkgs` value) as an input, and uses it to generate the output packages. This way, I can expose these packages as external outputs, but also incorporate them into my nixos config and have overlays and unfree options and such apply. Not to mention my config evaluates faster if I don't have to instantiate nixpkgs multiple times.
- I incorporate system-specific, but non-package, values into my personal `lib`, rather than throwing them in with my packages, as nixpkgs does. This, however, means there are multiple versions of my `lib`. Non-system-specific `lib` components are defined in `lib/` and make it into `self.lib`. System-specific `lib` components are defined in `libFunc/` and can only be accessed when `lib` has been instantiated with a specific nixpkgs instance, such as in `self.libFor.${system}`.
- I expose my flake inputs as `self.inputs`, which can be useful for getting at things with `nix eval`.

## Notable components
- `self.packages.*.hred` packages [hred](https://github.com/danburzo/hred) through node2nix. It's the best tool I know to grab meaningful datastructures from html. Pipe the output into [jq](https://stedolan.github.io/jq/) and you have a very versatile web scraping tool. I don't think there's anything better short of a headless browser.
- `self.overlays.editline-urxvt-home-end-fix` patches [editline](https://github.com/troglobit/editline) to recognize the `home` and `end` keys correctly in [`urxvt`](http://software.schmorp.de/pkg/rxvt-unicode.html), making `nix repl` much easier to work with in that terminal emulator. The patch has been accepted upstream, but has not yet made it into a release.
- `self.overlays.steam-fix-screensaver` gets around a longtime bug in the steam client which causes it to prevent screesaver activation as long as the steam client is running at all, even just in the system tray. It does this by `LD_PRELOAD`ing a special library that stubs the sdl call being used to accomplish it. Note that this overlay won't work for everyone out of the box, because it needs to know which `$PLATFORM` values to build for. These can be specified easily by altering an attrset in the overlay code. See the comment there for more information.
- `self.packages.*.starsector` packages [starsector](https://fractalsoftworks.com/) through `buildFHSUserEnv`. I tried making it work through patchelf as well as by using a nixpkgs-built JVM, but both failed. It's ugly, but it works. It also redirects all relevant saved state to `${STARSECTOR_CONFIG_DIR:-$HOME/.config/starsector}`.
- `self.homeModules.sfeed` is a module to generate a fairly complex `~/.sfeed/sfeedrc` from structured data, and automate running of `sfeed_update`. It allows overrides of `sfeed_update`'s functions to be specified together with the feed, and applied by case-match on the feed name at runtime. It also uses [resholve](https://github.com/abathur/resholve) to sanity check and avoid PATH dependence in the produced `sfeedrc`.
