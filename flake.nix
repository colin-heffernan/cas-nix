{
  description = "Celeste Auto Splitter for Linux";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # CAS
    cas = {
      url = "sourcehut:~bfiedler/cas";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    cas,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "steam"
            "steam-original"
            "steam-runtime"
          ];
      };
    };
    inherit (nixpkgs) lib;
  in rec {
    apps.${system} = {
      cas = {
        type = "app";
        program = "${packages.${system}.cas}/bin/cas";
      };
    };
    packages.${system} = {
      cas = pkgs.buildGoModule {
        pname = "cas";
        version = "git";
        src = cas;
        vendorHash = "sha256-7fwy6MakHaDs2cOVfg9ujzNEYArGHXLGgBI8zYu2Fjc=";
        preBuild = ''
          sed -i "s#if os.IsNotExist(err) {#if os.IsNotExist(err) {\nfmt.Fprintln(os.Stderr, \"bule.json missing, creating...\")\nsaveTimes(buleTimes, \"bule.json\")\n/*#g" main.go
          sed -i "s#color.NoColor = false#*/\n}\n}\ncolor.NoColor = true#g" main.go
          sed -i "s#\"pb.json\"#os.Getenv\(\"XDG_DATA_HOME\"\) + \"/CAS/pb.json\"#g" main.go
          sed -i "s#\"bule.json\"#os.Getenv\(\"XDG_DATA_HOME\"\) + \"/CAS/bule.json\"#g" main.go
        '';
      };
    };
    overlays.default = final: prev: {
      inherit (self.packages.${final.system}) cas;
    };
  };
}
