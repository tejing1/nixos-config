let
  generic = {
    border = "pixel";
    floating = "auto_off";
    marks = [];
    type = "con";
  };
  win = percent: name: swallows: generic // {
    current_border_width = 2;
    inherit name percent swallows;
  };
  splith = percent: nodes: generic // {
    layout = "splith";
    inherit percent nodes;
  };
  splitv = percent: nodes: generic // {
    layout = "splitv";
    inherit percent nodes;
  };
  tabbed = percent: nodes: generic // {
    layout = "tabbed";
    inherit percent nodes;
  };
  stacked = percent: nodes: generic // {
    layout = "stacked";
    inherit percent nodes;
  };
  term = null;
  temp = ["splith" ["splitv" ["tabbed" term] (1104.0 / 2132.0) term] (1924.0 / 3840.0) term];
  mkLayout = let
    mkLayout' = template: {
      json = generic // {
        layout = builtins.head template;
        nodes = [];
      };
      exec = [];
    };
  in
    template: let layout = mkLayout' template; in "append_layout ${builtins.toFile "layout.json" (builtins.toJSON layout.json)}";
in
builtins.toJSON
  (splith 1.0 [
    (splitv (1924.0 / 3840.0) [
      (tabbed (1104.0 / 2132.0) [
        (win 1 "zsh" [
          {class = "^URxvt$";instance="^zsh$";}
        ])
      ])
      (win (1028.0 / 2132.0) "zsh" [
        {class = "^URxvt$";instance="^zsh$";}
      ])
    ])
    (win (1916.0 / 3840.0) "zsh" [
      {class = "^URxvt$";instance="^zsh$";}
    ])
  ])
