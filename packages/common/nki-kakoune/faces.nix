{ callPackage, ... }:
let
  utils = callPackage ./utils.nix { };
  faces = {
    Default = "%opt{text},%opt{base}";
    BufferPadding = "%opt{base},%opt{base}";
    MenuForeground = "%opt{blue},white+bF";
    MenuBackground = "%opt{sky},white+F";
    Information = "%opt{sky},white";
    # Markdown help color scheme
    InfoDefault = "Information";
    InfoBlock = "@block";
    InfoBlockQuote = "+i@block";
    InfoBullet = "@bullet";
    InfoHeader = "@header";
    InfoLink = "@link";
    InfoLinkMono = "+b@mono";
    InfoMono = "@mono";
    InfoRule = "+b@Information";
    InfoDiagnosticError = "@DiagnosticError";
    InfoDiagnosticHint = "@DiagnosticHint";
    InfoDiagnosticInformation = "@Information";
    InfoDiagnosticWarning = "@DiagnosticWarning";
    # Extra faces
    macro = "+u@function";
    method = "@function";
    format_specifier = "+i@string";
    mutable_variable = "+i@variable";
    class = "+b@variable";
  };
in
utils.mkFacesScript "default-faces" faces
