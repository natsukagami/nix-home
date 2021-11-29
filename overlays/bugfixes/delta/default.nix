final: prev: {
  delta =
    if (prev.delta.version == "0.10.0") then
    # There is a bug where prev.delta on v0.10.0 does NOT have adequate dependencies on Darwin.
      (prev.delta.overrideAttrs
        (oldAttrs: {
          version = "0.10.0-patched";
          buildInputs = final.lib.optionals final.stdenv.isDarwin (with final; [
            darwin.apple_sdk.frameworks.DiskArbitration
            darwin.apple_sdk.frameworks.Foundation
            darwin.apple_sdk.frameworks.Security
            libiconv
          ]);
        })) else prev.delta;
}
