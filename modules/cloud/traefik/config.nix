{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.cloud.traefik;

  # Copied from traefik.nix
  jsonValue = with types;
    let
      valueType = nullOr
        (oneOf [
          bool
          int
          float
          str
          (lazyAttrsOf valueType)
          (listOf valueType)
        ]) // {
        description = "JSON value";
        emptyValue.value = { };
      };
    in
    valueType;

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
      localHost = mkOption {
        type = types.nullOr types.str;
        description = "The local host of the service. Must be an IP if protocol is TCP. Default to localhost/127.0.0.1";
        default = null;
      };
      port = mkOption {
        type = types.port;
        description = "The port that the service is listening on";
      };
      entrypoints = mkOption {
        type = listOf (enum [ "http" "https" "smtp-submission" "smtp-submission-ssl" "imap" ]);
        default = [ "https" ];
        description = "The entrypoints that will serve the host";
      };
      middlewares = mkOption {
        type = listOf jsonValue;
        default = [ ];
        description = "The middlewares to be used with the host.";
      };
      protocol = mkOption {
        type = enum [ "http" "tcp" ];
        default = "http";
        description = "The protocol of the router and service";
      };
      tlsPassthrough = mkOption {
        type = types.bool;
        default = true;
        description = "Sets the TCP passthrough value. Defaults to `true` if the connection is tcp";
      };
    };
  };

  # Returns the filter given a host configuration
  filterOfHost = host:
    let
      hostFilter = if host.protocol == "http" then "Host" else "HostSNI";
    in
    if host.filter != null then host.filter
    else if host.path == null then "${hostFilter}(`${host.host}`)"
    else "${hostFilter}(`${host.host}`) && Path(`${host.path}`)";

  # Turns a host configuration into dynamic traefik configuration
  hostToConfig = name: host: {
    "${host.protocol}" = {
      routers."${name}-router" = {
        rule = filterOfHost host;
        entryPoints = host.entrypoints;
        tls = { certResolver = "le"; } // (if host.protocol == "tcp" then { passthrough = if (host ? tlsPassthrough) then host.tlsPassthrough else true; } else { });
        service = "${name}-service";

      } // (
        if host.protocol == "http" then
          { middlewares = lists.imap0 (id: m: "${name}-middleware-${toString id}") host.middlewares; }
        else if host.middlewares == [ ] then
          { }
        else abort "Cannot have middlewares on tcp routers"
      );
      services."${name}-service".loadBalancer.servers = [
        (
          let
            localhost =
              if isNull host.localHost then
                (
                  if host.protocol == "http" then "localhost"
                  else "127.0.0.1"
                ) else host.localHost;
          in
          if host.protocol == "http" then
            { url = "http://${localhost}:${toString host.port}"; }
          else { address = "${localhost}:${toString host.port}"; }
        )
      ];
    } // (if (host.middlewares != [ ]) then {
      middlewares = builtins.listToAttrs (lists.imap0
        (id: v: {
          name = "${name}-middleware-${toString id}";
          value = v;
        })
        host.middlewares);
    } else { });
  };
in
{

  options.cloud.traefik.hosts = mkOption {
    type = types.attrsOf hostType;
    default = { };
    description = "The HTTP hosts to run on the server";
  };

  config.cloud.traefik.config = builtins.foldl' attrsets.recursiveUpdate { } (attrsets.mapAttrsToList hostToConfig cfg.hosts);
}
