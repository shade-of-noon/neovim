{
  description = "Neovim flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
  in {

    packages."${system}".neovim-dev = let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages."${system}".pkgs;
      pythonEnv = nixpkgs.legacyPackages."${system}".pkgs.python3;
      devMode = true;
      in (pkgs.neovim-unwrapped.override {
          # doCheck = true;
          stdenv = pkgs.llvmPackages_latest.stdenv;
      }).overrideAttrs(oa:{
        cmakeBuildType="debug";
        cmakeFlags = oa.cmakeFlags ++ [
          "-DMIN_LOG_LEVEL=0"
          "-DENABLE_LTO=OFF"
          "-DUSE_BUNDLED=OFF"
          # https://github.com/google/sanitizers/wiki/AddressSanitizerFlags
          # https://clang.llvm.org/docs/AddressSanitizer.html#symbolizing-the-reports
          "-DCLANG_ASAN_UBSAN=ON"
	];


        version = "master";
        src = ./.;
        nativeBuildInputs = oa.nativeBuildInputs
          ++ lib.optionals devMode (with pkgs; [
            pythonEnv
            include-what-you-use  # for scripts/check-includes.py
            jq                    # jq for scripts/vim-patch.sh -r
            doxygen
          ]);

        buildInputs = oa.buildInputs ++ ([
          pkgs.tree-sitter
        ]);

        shellHook = oa.shellHook + ''
          export NVIM_PYTHON_LOG_LEVEL=DEBUG
          export NVIM_LOG_FILE=/tmp/nvim.log

          export ASAN_OPTIONS="log_path=./test.log:abort_on_error=1"
          export UBSAN_OPTIONS=print_stacktrace=1
        '';
      });

    defaultPackage."${system}" = self.packages.x86_64-linux.neovim-dev;

    apps."${system}".nvim = {
      type = "app";
      program = self.packages."${system}".neovim-dev + "/bin/nvim";
    };

    defaultApp."${system}" = self.apps."${system}".nvim;
  };
}
