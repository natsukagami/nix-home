{
  callPackage,
  utils ? callPackage ./utils.nix { },
  extraFaces ? [ ],
  ...
}:
let
  faces = [
    {
      name = "Default";
      face = "%opt{text},%opt{base}";
    }
    {
      name = "BufferPadding";
      face = "%opt{base},%opt{base}";
    }
    {
      name = "MenuForeground";
      face = "%opt{blue},%opt{mantle}+b";
    }
    {
      name = "MenuBackground";
      face = "%opt{sky},%opt{mantle}";
    }
    {
      name = "MenuInfo";
      face = "%opt{teal},%opt{mantle}";
    }
    {
      name = "Information";
      face = "%opt{blue},%opt{mantle}";
    }
    {
      name = "DiagnosticError";
      face = "%opt{maroon},default";
    }
    # Markdown help color scheme
    {
      name = "InfoDefault";
      face = "Information";
    }
    {
      name = "InfoBlock";
      face = "@block";
    }
    {
      name = "InfoBlockQuote";
      face = "+i@block";
    }
    {
      name = "InfoBullet";
      face = "@bullet";
    }
    {
      name = "InfoHeader";
      face = "@header";
    }
    {
      name = "InfoLink";
      face = "@link";
    }
    {
      name = "InfoLinkMono";
      face = "+b@mono";
    }
    {
      name = "InfoMono";
      face = "@mono";
    }
    {
      name = "InfoRule";
      face = "+b@Information";
    }
    {
      name = "InfoDiagnosticError";
      face = "@DiagnosticError";
    }
    {
      name = "InfoDiagnosticHint";
      face = "@DiagnosticHint";
    }
    {
      name = "InfoDiagnosticInformation";
      face = "@Information";
    }
    {
      name = "InfoDiagnosticWarning";
      face = "@DiagnosticWarning";
    }
    # Extra faces
    {
      name = "macro";
      face = "+u@function";
    }
    {
      name = "method";
      face = "@function";
    }
    {
      name = "format_specifier";
      face = "+i@string";
    }
    {
      name = "mutable_variable";
      face = "+i@variable";
    }
    {
      name = "class";
      face = "+b@module";
    }
    {
      name = "interface";
      face = "+ib@module";
    }
  ];
in
utils.mkFacesScript "default" (faces ++ extraFaces)
