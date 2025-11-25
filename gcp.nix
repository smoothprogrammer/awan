{ terranix }:
{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options.perSystem = mkPerSystemOption (
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      cfg = config.awan.gcp;

      terraform = {
        variable = {
          variable = {
            org_id = {
              type = "string";
            };
            project_id = {
              type = "string";
            };
            billing_account = {
              type = "string";
            };
            region = {
              type = "string";
            };
            zone = {
              type = "string";
            };
          };
        };

        init = {
          # https://registry.terraform.io/providers/hashicorp/google/7.12.0/docs
          terraform.required_providers.google = {
            source = "hashicorp/google";
            version = "7.12.0";
          };

          # https://registry.terraform.io/providers/hashicorp/google/7.12.0/docs/guides/provider_reference
          provider.google = {
            project = cfg.project_id;
            region = cfg.region;
            zone = cfg.zone;
          };

          # https://registry.terraform.io/providers/hashicorp/google/7.12.0/docs/resources/google_project
          resource.google_project.main = {
            name = cfg.project_id;
            project_id = cfg.project_id;
            org_id = cfg.org_id;
            billing_account = cfg.billing_account;
            auto_create_network = false;
          };
        };
      };

      initConfig = terranix.lib.terranixConfiguration {
        inherit system;
        modules = [
          terraform.variable
          terraform.init
        ];
      };

      gcp = pkgs.writeShellApplication {
        name = "gcp";
        text = ''
          echo "TODO: add CLI documentation"
        '';
      };

      auth = pkgs.writeShellApplication {
        name = "auth";
        runtimeInputs = with pkgs; [ google-cloud-sdk ];
        text = ''
          gcloud auth application-default login
        '';
      };

      init = pkgs.writeShellApplication {
        name = "init";
        runtimeInputs = with pkgs; [ opentofu ];
        text = ''
          ln -sf ${initConfig} ./config.tf.json
          tofu init
        '';
      };
    in
    {
      options.awan.gcp = {
        enable = mkOption {
          type = types.bool;
          default = false;
        };

        org_id = mkOption {
          type = types.str;
          default = "\${var.org_id}";
        };

        project_id = mkOption {
          type = types.str;
          default = "\${var.project_id}";
        };

        billing_account = mkOption {
          type = types.str;
          default = "\${var.billing_account}";
        };

        region = mkOption {
          type = types.str;
          default = "\${var.region}";
        };

        zone = mkOption {
          type = types.str;
          default = "\${var.zone}";
        };
      };

      config = mkIf cfg.enable {
        packages.gcp = gcp.overrideAttrs {
          name = "gcp";
          passthru = {
            inherit auth init;
          };
        };
      };
    }
  );
}
