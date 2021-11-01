{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.cloud.traefik;

  hostType = with types; submodule {
    options = {
      host = mkOption {
        type = str;
        description = "The host for the router filter";
      };
      path = mkOption {
        type = nullOr str;
        default = null;
        description = "The path for the router filter (exact path is matched)";
      };
      filter = mkOption {
        type = nullOr str;
        default = null;
        description = "The filter syntax for the router. Overrides `host` and `path` if provided";
      };
      port = mkOption {
        type = types.port;
        description = "The port that the service is listening on";
      };
      entrypoints = mkOption {
        type = listOf (enum ["http" "https" "smtp-submission" "imap"]);
        default = [ "https" ];
        description = "The entrypoints that will serve the host";
      };
    };
  };

  # Returns the filter given a host configuration
  filterOfHost = host :
    if host.filter != null then host.filter
    else if host.path == null then "Host(`${host.host}`)"
    else "Host(`${host.host}`) && Path(`${host.path}`)";

  # Turns a host configuration into dynamic traefik configuration
  hostToConfig = name : host : {
    http.routers."${name}-router" = {
      rule = filterOfHost host;
      entryPoints = host.entrypoints;
      tls.certResolver = "le";
      service = "${name}-service";
    };
    http.services."${name}-service".loadBalancer.servers = [
      { url = "http://localhost:${toString host.port}"; }
    ];
  };
in
{

  options.cloud.traefik.hosts = mkOption {
    type = types.attrsOf hostType;
    default = {};
    description = "The HTTP hosts to run on the server";
  };

  config.cloud.traefik.config = builtins.foldl' attrsets.recursiveUpdate {} (attrsets.mapAttrsToList hostToConfig cfg.hosts);
}
