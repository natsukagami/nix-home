{
  lib,
  fetchFromGitHub,
  stdenv,
  nodejs,
  pnpm,
  buildGoModule,
  mage,
  writeShellScriptBin,
  nixosTests,
  autoPatchelfHook,
  musl,
}:

let
  version = "0.24.5-git";
  src = fetchFromGitHub {
    owner = "go-vikunja";
    repo = "vikunja";
    rev = "e57f04ec23e9ff8aa9877d2ea7d571c2a44790b0";
    hash = "sha256-W6o1h6XBPvT1lH1zO5N7HcodksKill5eqSuaFl2kfuY=";
  };

  frontend = stdenv.mkDerivation (finalAttrs: {
    pname = "vikunja-frontend";
    inherit version src;

    sourceRoot = "${finalAttrs.src.name}/frontend";

    pnpmDeps = pnpm.fetchDeps {
      inherit (finalAttrs)
        pname
        version
        src
        sourceRoot
        ;
      hash = "sha256-sOCaJDBgEMID+lN5plQpSqaGBIUs5h2tAwDzhtOH53o=";
    };

    nativeBuildInputs = [
      nodejs
      pnpm.configHook
      autoPatchelfHook
    ];

    buildInputs = [
      musl # For sass-embedded
    ];

    doCheck = true;
    dontAutoPatchelf = true;

    # See https://github.com/sass/embedded-host-node/issues/334
    preBuild = ''
      autoPatchelf node_modules/.pnpm/sass-embedded*
    '';

    postBuild = ''
      pnpm run build
    '';

    checkPhase = ''
      pnpm run test:unit --run
    '';

    installPhase = ''
      cp -r dist/ $out
    '';
  });

  # Injects a `t.Skip()` into a given test since there's apparently no other way to skip tests here.
  skipTest =
    lineOffset: testCase: file:
    let
      jumpAndAppend = lib.concatStringsSep ";" (lib.replicate (lineOffset - 1) "n" ++ [ "a" ]);
    in
    ''
      sed -i -e '/${testCase}/{
      ${jumpAndAppend} t.Skip();
      }' ${file}
    '';
in
buildGoModule {
  inherit src version;
  pname = "vikunja";

  nativeBuildInputs =
    let
      fakeGit = writeShellScriptBin "git" ''
        if [[ $@ = "describe --tags --always --abbrev=10" ]]; then
            echo "${version}"
        else
            >&2 echo "Unknown command: $@"
            exit 1
        fi
      '';
    in
    [
      fakeGit
      mage
    ];

  vendorHash = "sha256-UWjlivF9ySXCAr84A1trCJ/n9pB98ZhEyG11qz3PL7g=";

  inherit frontend;

  prePatch = ''
    cp -r ${frontend} frontend/dist
  '';

  postConfigure = ''
    # These tests need internet, so we skip them.
    ${skipTest 1 "TestConvertTrelloToVikunja" "pkg/modules/migration/trello/trello_test.go"}
    ${skipTest 1 "TestConvertTodoistToVikunja" "pkg/modules/migration/todoist/todoist_test.go"}
  '';

  buildPhase = ''
    runHook preBuild

    # Fixes "mkdir /homeless-shelter: permission denied" - "Error: error compiling magefiles" during build
    export HOME=$(mktemp -d)
    mage build:build

    runHook postBuild
  '';

  checkPhase = ''
    mage test:unit
    mage test:integration
  '';

  installPhase = ''
    runHook preInstall
    install -Dt $out/bin vikunja
    runHook postInstall
  '';

  passthru.tests.vikunja = nixosTests.vikunja;

  meta = {
    changelog = "https://kolaente.dev/vikunja/api/src/tag/v${version}/CHANGELOG.md";
    description = "Todo-app to organize your life";
    homepage = "https://vikunja.io/";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [ leona ];
    mainProgram = "vikunja";
    platforms = lib.platforms.linux;
  };
}
