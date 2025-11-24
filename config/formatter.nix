{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem =
    { ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";

        programs = {
          actionlint.enable = true;
          nixfmt.enable = true;
        };
      };
    };
}
