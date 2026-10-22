{
  config,
  lib,
  pkgs,
  pkgs-stable,
  pkgs-master,
  pkgs-blender,
  ...
}:
let
  bambu-studio = pkgs.symlinkJoin {
    name = "bambu-studio-${pkgs-master.bambu-studio.version}";
    paths = [ pkgs-master.bambu-studio ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Work around wxWidgets HiDPI text clipping under fractional scaling.
      # https://github.com/bambulab/BambuStudio/issues/4959
      wrapProgram $out/bin/bambu-studio --set GDK_DPI_SCALE 0.8
    '';
  };
  cfg = config.modules.desktop.creative;
in
{
  # On by default so existing hosts keep the creative suite; headless-ish or dev
  # hosts (and ones that cannot fetch/build bambu-studio) turn it off.
  options.modules.desktop.creative.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Creative apps: krita, musescore, slicers, blender, OBS.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs-stable; [
      # creative
      krita # digital painting
      musescore # music notation
      pkgs-master.orca-slicer # 3d printer slicer app
      bambu-studio # bambu 3d printer slicer app
      pkgs-blender.blender # 3d modeling
    ];

    programs = {
      # live streaming
      obs-studio = {
        enable = pkgs.stdenv.hostPlatform.isx86_64;
        plugins = with pkgs.obs-studio-plugins; [
          # screen capture
          wlrobs
          # obs-ndi
          # obs-nvfbc
          # obs-teleport
          # obs-hyperion
          # droidcam-obs
          # obs-vkcapture
          obs-gstreamer
          input-overlay
          obs-multi-rtmp
          obs-source-clone
          # obs-shaderfilter
          # obs-source-record
          # obs-livesplit-one
          # looking-glass-obs
          # obs-vintage-filter
          # obs-command-source
          # obs-move-transition
          # obs-backgroundremoval
          # advanced-scene-switcher
          obs-pipewire-audio-capture
          obs-vaapi
          # obs-3d-effect
        ];
      };
    };
  };
}
