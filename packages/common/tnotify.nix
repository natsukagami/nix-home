{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  libnotify,
}:

buildGoModule (finalAttrs: {
  pname = "tnotify";
  version = "0.1.6";

  src = fetchFromGitHub {
    owner = "soloterm";
    repo = "tnotify";
    rev = "v${finalAttrs.version}";
    hash = "sha256-6KvszN9mmLrReUqheROk1tiX6ou4m3T4HwfxA4kM/i0=";
  };

  vendorHash = "sha256-7K17JaXFsjf163g5PXCb5ng2gYdotnZ2IDKk8KFjNj0=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  # Expects the system's `osascript` in PATH, which the build sandbox lacks
  checkFlags = [ "-skip=^TestMacOSSender_IsAvailable$" ];

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ makeWrapper ];

  # The native fallback on Linux shells out to `notify-send`
  # (macOS uses the system's `osascript`).
  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    wrapProgram $out/bin/tnotify \
      --suffix PATH : ${lib.makeBinPath [ libnotify ]}
  '';

  meta = {
    description = "Send desktop notifications from the terminal via OSC escape sequences or native tools";
    homepage = "https://github.com/soloterm/tnotify";
    changelog = "https://github.com/soloterm/tnotify/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "tnotify";
    platforms = lib.platforms.unix;
  };
})
