{
  lib,
  config,
  options,
  ...
}:
lib.nixvim.plugins.mkNeovimPlugin {
  name = "ltex-extra";
  package = "ltex_extra-nvim";
  description = "LTeX_extra is a companion plugin for LTeX language server.";

  maintainers = [ lib.maintainers.loicreynier ];

  callSetup = false;

  settingsOptions = {
    path = lib.nixvim.defaultNullOpts.mkStr "" ''
      Path (relative to project root) to load external files from.

      Commonly used values are:
      - `.ltex`
      - `.vscode` for compatibility with projects using the associated VS Code extension.
    '';

    init_check = lib.nixvim.defaultNullOpts.mkBool true ''
      Whether to load dictionaries on startup.
    '';

    load_langs = lib.nixvim.defaultNullOpts.mkListOf lib.types.str [ "en-US" ] ''
      Languages for witch dicionnaries will be loaded.
      See `plugins.lsp.servers.ltex.languages` for possible values.
    '';

    log_level = lib.nixvim.defaultNullOpts.mkEnumFirstDefault [
      "none"
      "trace"
      "debug"
      "info"
      "warn"
      "error"
      "fatal"
    ] "Log level.";
  };

  extraConfig = cfg: {
    warnings = lib.nixvim.mkWarnings "plugins.ltex-extra" [
      (
        let
          expectedDefs = map toString [
            ./.
            ../../lsp/language-servers
          ];
          isExternal = d: !lib.elem d.file expectedDefs;
          anyExternal =
            acc: name: v:
            let
              e = lib.findFirst isExternal null v.definitionsWithLocations;
            in
            if acc != null then
              acc
            else if e == null then
              null
            else
              {
                inherit name;
                inherit (e) file;
              };
          external = lib.foldlAttrs anyExternal null options.plugins.lsp.servers.ltex;
        in
        {
          # TODO: Added 2025-03-30; remove after 25.05
          # Warn if servers.ltex seems to be configured outside of ltex-extra
          when = !config.lsp.servers.ltex.enable && external != null;
          message = ''
            in ${external.file}
            You seem to have configured `plugins.lsp.servers.ltex.${external.name}` for `ltex-extra`.
            It now uses `plugins.lsp.servers.ltex_plus` by default,
            either move the configuration or explicitly enable `ltex` with `plugins.lsp.servers.ltex.enable = true`
          '';
        }
      )
    ];

    extraConfigLuaPre = /* lua */ ''
      function ltex_extra_attach()
        require("ltex_extra").setup(${lib.nixvim.toLuaObject cfg.settings})
      end
    '';
    lsp = {
      servers.ltex.config.on_attach.__raw = "ltex_extra_attach";
      servers.ltex_plus = {
        # Enable ltex_plus if ltex is not already enabled
        enable = lib.mkIf (!config.lsp.servers.ltex.enable) (lib.mkDefault true);
        config.on_attach.__raw = "ltex_extra_attach";
      };
    };
  };

  settingsExample = {
    path = ".ltex";
    initCheck = true;
    loadLangs = [
      "en-US"
      "fr-FR"
    ];
    logLevel = "non";
  };
}
