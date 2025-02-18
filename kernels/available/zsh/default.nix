{
  self,
  pkgs,
  name ? "zsh",
  displayName ? "zsh",
  runtimePackages ? with pkgs; [zsh coreutils],
  extraRuntimePackages ? [],
  # https://github.com/nix-community/poetry2nix#mkPoetryPackages
  projectDir ? self + "/kernels/available/zsh",
  pyproject ? projectDir + "/pyproject.toml",
  poetrylock ? projectDir + "/poetry.lock",
  overrides ? pkgs.poetry2nix.overrides.withDefaults (import ./overrides.nix),
  python ? pkgs.python3,
  editablePackageSources ? {},
  extraPackages ? ps: [],
  preferWheels ? false,
}: let
  env = pkgs.poetry2nix.mkPoetryEnv {
    inherit
      projectDir
      pyproject
      poetrylock
      overrides
      python
      editablePackageSources
      extraPackages
      preferWheels
      ;
  };

  allRuntimePackages = runtimePackages ++ extraRuntimePackages;

  wrappedEnv =
    pkgs.runCommand "wrapper-${env.name}"
    {nativeBuildInputs = [pkgs.makeWrapper];}
    ''
      mkdir -p $out/bin
      for i in ${env}/bin/*; do
        filename=$(basename $i)
        ln -s ${env}/bin/$filename $out/bin/$filename
        wrapProgram $out/bin/$filename \
          --set PATH "${pkgs.lib.makeSearchPath "bin" allRuntimePackages}"
      done
    '';
in {
  inherit name displayName;
  language = "zsh";
  argv = [
    "${wrappedEnv}/bin/python"
    "-m"
    "zsh_jupyter_kernel"
    "-f"
    "{connection_file}"
  ];
  codemirrorMode = "shell";
  logo64 = ./logo64.png;
  logo32 = ./logo32.png;
}
