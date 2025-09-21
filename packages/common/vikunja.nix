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
}:

let
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
buildGoModule (attrs: {
  version = "1.0.0-rc2";

  src = fetchFromGitHub {
    owner = "go-vikunja";
    repo = "vikunja";
    rev = "v${attrs.version}";
    hash = "sha256-bKkw/GwNeJHOeMSz4GUoJv+aU1CYwUnJn1rpAlcD1Js=";
  };

  vendorHash = "sha256-zm2fgNGkanm5PalaFCrdvJVH1VVMdWchH28IB1ZwM+w=";

  frontend = stdenv.mkDerivation (finalAttrs: {
    pname = "vikunja-frontend";
    inherit (attrs) version src;

    patches = [
      # ./nodejs-22.12-tailwindcss-update.patch
    ];
    sourceRoot = "${finalAttrs.src.name}/frontend";

    pnpmDeps = pnpm.fetchDeps {
      inherit (finalAttrs)
        pname
        version
        patches
        src
        sourceRoot
        ;
      fetcherVersion = 1;
      hash = "sha256-IqjdYdQPckD7n7gWy7tw9tfKClCsBBGZtkWCDXZXM4Y=";
      # hash = lib.fakeHash;
    };

    nativeBuildInputs = [
      nodejs
      pnpm.configHook
    ];

    doCheck = true;

    preBuild = ''
      # using sass-embedded fails at executing node_modules/sass-embedded-linux-x64/dart-sass/src/dart
      rm -r node_modules/sass-embedded*
      rm -r node_modules/.pnpm/sass-embedded*
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

  pname = "vikunja";

  nativeBuildInputs =
    let
      fakeGit = writeShellScriptBin "git" ''
        if [[ $@ = "describe --tags --always --abbrev=10" ]]; then
            echo "${attrs.version}"
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

  prePatch = ''
    cp -r ${attrs.frontend} frontend/dist
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
    export VIKUNJA_CORS_ENABLE=false
    mage test:all
  '';

  installPhase = ''
    runHook preInstall
    install -Dt $out/bin vikunja
    runHook postInstall
  '';

  passthru.tests.vikunja = nixosTests.vikunja;

  meta = {
    changelog = "https://kolaente.dev/vikunja/api/src/tag/v${attrs.version}/CHANGELOG.md";
    description = "Todo-app to organize your life";
    homepage = "https://vikunja.io/";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [ leona ];
    mainProgram = "vikunja";
    platforms = lib.platforms.linux;
  };
})
