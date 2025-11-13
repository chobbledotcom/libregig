{
  description = "Libregig - band management app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ruby_3_4
            rubyPackages_3_4.ruby-vips
            rubyPackages_3_4.psych
            sqlite
            nodejs
            imagemagick
            jq
            # Build dependencies for native gems
            libyaml
            pkg-config
            libffi
          ];

          # Use bundler to manage Rails version instead of Nix
          shellHook = ''
            export GEM_HOME=$PWD/.gems
            export PATH=$GEM_HOME/bin:$PATH

            # Add bin directory to PATH for easy access to scripts
            export PATH=$PWD/bin:$PATH

            # Configure bundler to skip documentation
            bundle config set --local path '.gems'
            bundle config set --local no-document true

            echo "Installing dependencies from Gemfile..."
            gem install bundler --no-document
            bundle install
            echo "Ruby $(ruby --version) with Rails $(rails --version)"
            echo ""
            echo "Scripts available:"
            echo "  rspec-find     - Find first failing test with details"
            echo "  rspec-quick    - Run tests quickly with in-memory DB"
            echo "  rspec-quicker  - Run tests in parallel with fail-fast"
            echo "  rspec-replace  - Test replacements for broken tests"
            echo "  test           - Run all tests in parallel"
            echo "  find           - Run ripgrep for a string, useful dirs only"
          '';
        };
      }
    );
}